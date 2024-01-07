# Set the base image
ARG BASE_IMAGE_TAG=${BASE_IMAGE_TAG}
FROM rockylinux:${BASE_IMAGE_TAG}

# Set ARG
ARG TZ=Asia/Tokyo
ARG USER_NAME=${USER_NAME}

# Set TimeZone
RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && echo ${TZ} > /etc/timezone

# Repository Update
RUN dnf update -y

# Install Packages
RUN dnf install openssh-server -y &&\
    dnf install sudo -y &&\
    dnf install systemd -y &&\
    dnf install git -y &&\
    dnf install unzip -y

# Install awscliv2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" &&\
    unzip awscliv2.zip &&\
    ./aws/install &&\
    rm awscliv2.zip

# Add User
RUN adduser ${USER_NAME} --badname

# Setup to use sudo without password
RUN echo "${USER_NAME} ALL=NOPASSWD: ALL" >> /etc/sudoers

# Replace sshd_config
RUN chown root:root /etc/ssh/sshd_config &&\
    chmod 600 /etc/ssh/sshd_config

# Setup WORKDIR
WORKDIR /home/${USER_NAME}

# Change User
USER ${USER_NAME}

# Setup alias
COPY ./.alias /home/${USER_NAME}/
RUN cat ~/.alias >> ~/.bashrc &&\
    rm .alias

# Create .ssh
RUN mkdir ~/.ssh &&\
    chmod 700 ~/.ssh

# Setup startup_execution.sh
COPY ./startup_execution.sh /home/${USER_NAME}/
RUN sudo chown ${USER_NAME}:${USER_NAME} ~/startup_execution.sh &&\
    chmod 700 ~/startup_execution.sh

RUN sudo ssh-keygen -A

ENTRYPOINT ~/startup_execution.sh
