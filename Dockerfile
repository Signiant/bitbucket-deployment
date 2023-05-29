FROM node:18-bullseye
LABEL maintainer=sre@signiant.com

# Add Terraform repo
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor > /usr/share/keyrings/hashicorp-archive-keyring.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com bullseye main" > /etc/apt/sources.list.d/hashicorp.list

# Install a base set of packages from the default repo
RUN apt update \
  && apt install -y python3 python3-pip figlet jq sudo terraform

#Update python setuptool
RUN pip install --upgrade setuptools

# Install docker-compose
RUN pip install docker-compose

#install RVM 1.9.3
RUN /bin/bash -l -c "apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3B4FE6ACC0B21F32"
RUN /bin/bash -l -c "echo 'deb http://security.ubuntu.com/ubuntu bionic-security main' | tee -a /etc/apt/sources.list"
RUN /bin/bash -l -c "gpg --keyserver keyserver.ubuntu.com --recv-key 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB"
RUN /bin/bash -l -c "curl -L get.rvm.io | bash -s stable"
RUN /bin/bash -l -c "rvm get 1.29.7"
RUN /bin/bash -l -c "rvm install 1.9.3"
RUN /bin/bash -l -c "echo 'gem: --no-ri --no-rdoc' > ~/.gemrc"
RUN /bin/bash -l -c "gem install bundler -v 1.17.3"
RUN . /etc/profile.d/rvm.sh

#Install required gems for our promotion scripts
COPY gem.packages.list /tmp/gem.packages.list
RUN chmod +r /tmp/gem.packages.list \
    && /bin/bash -l -c "gem install `cat /tmp/gem.packages.list | tr \"\\n\" \" \"`"

# python module installs:
COPY requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt

# always use python3
RUN ln -s /usr/bin/python3 /usr/bin/python

#install n module
RUN npm install -g n

ADD figlet-fonts /figlet-fonts