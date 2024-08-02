FROM node:20-bullseye
LABEL maintainer=sre@signiant.com

# Install and configure tenv
RUN wget https://github.com/tofuutils/tenv/releases/download/v2.7.9/tenv_v2.7.9_amd64.deb \
  && dpkg -i tenv_v2.7.9_amd64.deb \
  && TENV_AUTO_INSTALL=true
  && export TFENV_TERRAFORM_DEFAULT_VERSION=1.3.1

# Install a base set of packages from the default repo
RUN apt update \
  && apt install -y python3 python3-pip figlet jq sudo ssh
  
#Update python setuptool
RUN pip install --upgrade setuptools

# Install docker-compose
RUN pip install docker-compose helm

# Install k8s tooling
RUN apt-get install --yes --no-install-recommends
RUN curl -LO https://dl.k8s.io/release/v1.29.2/bin/linux/amd64/kubectl && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
RUN wget https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
    chmod 700 get-helm-3 &&\
    ./get-helm-3

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