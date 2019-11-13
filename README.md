# Docker Tutorial

## What is Docker and Why is it Useful?

Docker is a platform that allows to define, create, run, and coordinate containers (a virtual "operating system"?). Docker is different than a virtual machine because it virtualizes the OS-level primitives instead of the machine's hardware. So, it abstraction is "lightweight" than a standard virtual machine (i.e., operating system virtualization instead of hardware virtualization)

![Container vs. virtual machines](https://i2.wp.com/www.docker.com/blog/wp-content/uploads/Blog.-Are-containers-..VM-Image-1-1024x435.png?ssl=1)


Why do we use Docker?

- *Deploy* and *distribute* software in a fast and repeatable way.

  A use case is to deploy a web service "in the cloud". Each remote machine can have a different operating system, resources, and can be virtualized in different ways... If the remote machine installs Docker then we can just deploy our software with Docker in a uniform (and reliable) way.

- *Continuous Integration*:

  A common use case is when we want to run a set of tests on a system (a single software or a distributed system). We want to fix the environment (or environments) used to test our system (e.g., test it different versions of Java) and run the tests in a clean environment (for automatic continuous integration on GitHub, see [TravisCI](https://travis-ci.com)).

Some use cases we are more interested in:

- Create replication packages for our experiments: when we publish a paper we can set up docker instead than a virtual machine (advantages: more reusable, faster to create, easier to distribute)

- Try different development environments quickly, without polluting your system. For example run a program requiring a completely different version of clibc or run a program that works on linux on Mac or Windows.

- Have and share the development and execution environments for our tools: for example, we could use Docker to define the machine used to develop ROS.

- Another test case (similar to continuous integration) is to compile, run, and evaluate the student's programming exercises where every time the student upload a new program we want to compile it run some test cases. Clearly we want separation (e.g., not having a student's assignment polluting the results of another student's assignment), so every time we want to run a new, separate system that already has all the necessary dependencies installed.


Docker also allows to define a composition and orchestration of different containers, useful to specify the deployment of distributed systems (e.g., multiple services).


**Limitations**: the container uses the guest operating system. So, in principle to run Windows you need Windows. Docker on Mac and Windows "cheats" to run Linux containers, since it uses a Linux kernel underneath (virtualized somehow). In practice some combinations do not work, like running a Windows container on MacOs.



## 0. Test your installation

Test if your docker installation works:
```bash
$ docker run hello-world
```

Run `bash` in a Ubuntu system:
```bash
$ docker run -it ubuntu bash
```

- An `image` defines the system we run. Above, `ubuntu` is the name of an existing image.

- When we execute `docker run` we create a `container`: a container instantiates an image. We can instantiate how many containers we want.

- Where is the code defining the Ubuntu system,  the `ubuntu` image?


    Some magic: Docker is already configured to look for an image in a remote registry called [Docker Hub](https://hub.docker.com).

    In practice:

    - you download the images locally (more in the `docker images` command)

    - you can push your images on DockerHub (so everyone can download them)

    - you can create your own registry (e.g., a company registry) if you need to.




## 1. Hello World

We define an image printing `hello world`.

### A Dockerfile defines (declaratively) a docker image.

Create a file named `Dockerfile` in a separate directory:

```Docker
# Base the container on the ubuntu image
FROM ubuntu:18.04

# Execute the command when the container RUNS
CMD echo "Hello Cosynus!"
```

We create the image from the Dockerfile (`docker build` command):
```bash
$ docker build -t hellocosynus .
```

We can check if we have the `hellocosynus` image:
```bash
$ docker image ls
```

c. Run the container (`docker run` command):
```bash
$ docker run -it --name hellocontainer hellocosynus
```


### Greeting with style - customizing the image

```Docker
FROM ubuntu:18.04

# Run a command when CREATING the image
RUN apt-get update -y
RUN apt-get install -y sudo
RUN apt-get install -y figlet toilet

RUN echo "Hello Cosynus!" > hellomsg.txt


# Execute the command when the container runs
CMD figlet -kp < hellomsg.txt
```

### Containers graveyard

See what containers are running (none now):
```bash
$ docker container ls
```

See the list of the stopped containers:
```bash
$ docker container ls -a
```

Restart a container:
```bash
$ docker container start -i hellocontainer
```

Getting rid of all the stopped containers and **dangling images**:
```bash
docker container prune
```

Alternatives: start a container with the `--rm` flag (i.e., `docker run -it --rm hellocosynus`), remove the precise container (e.g., `docker container rm container_id`).



## 2. Setting up a linux box with ssh access

a. Dockerfile

```Docker
FROM hellocosynus

# Run additional commands (to change the hellocosynus image)
RUN apt-get update -y
RUN apt-get install -y openssh-server


################################################################################
# Set up a new user
################################################################################
RUN mkdir -p /var/run/sshd
RUN chmod 0755 /var/run/sshd
RUN useradd --groups sudo -m cosynus
RUN chown -R cosynus /home/cosynus 
# set the right access for ssh
RUN chmod 644 /home/sergio/.ssh
# set up bash as default shell (minor)
# RUN sed -i "s:home/cosynus\:/bin/sh:home/cosynus\:/bin/bash:" /etc/passwd

# In the real world you should set up the access using a ssh key
# Having the password in clear in the container is a bad practice.
RUN echo "cosynus:password" | chpasswd

# Expose the port 22 of the container
EXPOSE 22

# copy the entrypoint.sh (script that run the ssh service)
# entrypoint.sh becomes part of the image!
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
#
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# CMD is executed after ENTRYPOINT
# here it is a busyloop to keep the container running
CMD tail -f /dev/null
```


- We build on the previous image `hellocosynus`: you can compose different images!

- There is a lot of garbage to create a user and setting up the ssh server

- `EXPOSE 22` tells Docker to expose the network port to the outside world (otherwise the container cannot be accessed)

- `COPY` copies a file (took from the current directory where we execute `docker build`) in the **image**.

- `ENTRYPOINT` is the first command executed when running the container.

We execute the script [entrypoint.sh](./examples/ssh/entrypoint.sh) that starts the ssh service.

Only the last ENTRYPOINT instruction in the Dockerfile will have an effect.

[CMD vs ENTRYPOINT](https://stackoverflow.com/questions/21553353/what-is-the-difference-between-cmd-and-entrypoint-in-a-dockerfile)

More commands and documentation about writing a [Dockerfile](https://docs.docker.com/engine/reference/builder/)


We build the image:
```bash
$ docker build -t ssh .
```

Run the container:
```bash
$ docker run  -di -p 3200:22 --name sshcontainer ssh
```

We run the container in background (detached, `-d` option).

We map the port 22 of the container to the port 3200 of the host.

```bash
$ docker container ls
```
We should have a container running.


Now we can connect to the ssh server (with password `password`):
```bash
$ ssh -p 3200 cosynus@localhost
```


b. Containers conserve their state:

Connect to the server:

```bash
$ ssh -p 3200 cosynus@localhost
$ touch cosynushasbeenhere
$ ls
$ pwd
```

Let's restart the container:

```bash
$ docker container stop sshcontainer
$ docker container start sshcontainer
```

And check again the container's status:

```bash
$ ssh -p 3200 cosynus@localhost
$ ls
$ pwd
```

The file `cosynushasbeenhere` is there.

Careful: changes to the image (e.g., installing software) should be done at in the `Dockerfile` and not on the container.


c. How many containers as you want...

We can run another container on different port:
```bash
$ docker run  -di -p 3201:22 --name sshcontainer2 ssh
```

We can check if the file `cosynushasbeenhere` is there (of course not).


## 3. Can I share the guest file system?

```Dockerfile
FROM ssh

RUN mkdir /home/cosynus/persist
```

We create a new image:
```bash
$ docker build -t fs .
```

Run a container binding a directory to the container's filesystem:
```bash
$ docker run  -di -p 3200:22 --name fscontainer --mount type=bind,source=`cd ~/ && pwd`,target=/home/cosynus/persist fs
```
There are other options for the mount (e.g., read only filesystem).


