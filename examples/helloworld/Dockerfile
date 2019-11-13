FROM ubuntu:18.04

# Run a command when CREATING the image
RUN apt-get update -y
RUN apt-get install -y sudo
RUN apt-get install -y figlet toilet

RUN echo "Hello Cosynus!" > hellomsg.txt

# Execute the command when the container runs
CMD figlet -kp < hellomsg.txt

