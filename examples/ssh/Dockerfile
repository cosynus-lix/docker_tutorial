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
RUN mkdir /home/cosynus/.ssh
RUN chown -R cosynus /home/cosynus 

# set the right access for ssh
RUN chmod 644 /home/cosynus/.ssh

# set up bash as default shell (minor)
# RUN sed -i "s:home/cosynus\:/bin/sh:home/cosynus\:/bin/bash:" /etc/passwd

# In the real world you should set up the access using a ssh key
# Having the password in clear in the container is a bad practice.
RUN echo "cosynus:password" | chpasswd

# Expose the port 22 of the container
USER root
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






