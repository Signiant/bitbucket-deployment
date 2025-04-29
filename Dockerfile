FROM node:20-bullseye
LABEL maintainer=sre@signiant.com

ARG BUILDPLATFORM
ARG TENV_VERSION="4.4.0"

# Install and configure tenv
RUN export ARCH=$(echo ${BUILDPLATFORM} | cut -d / -f 2) \
  && wget https://github.com/tofuutils/tenv/releases/download/v${TENV_VERSION}/tenv_v${TENV_VERSION}_${ARCH}.deb \
  && dpkg -i tenv_v${TENV_VERSION}_${ARCH}.deb
ENV TENV_AUTO_INSTALL=true
ENV TFENV_TERRAFORM_DEFAULT_VERSION=1.3.1

# Install a base set of packages from the default repo
RUN apt update \
  && apt upgrade -y \
  && apt install -y ruby ruby-dev python3 python3-pip figlet jq sudo ssh
  
#Update python setuptool
RUN pip install --upgrade setuptools

# Install docker-compose
RUN pip install docker-compose helm

# Install k8s tooling
RUN apt-get install --yes --no-install-recommends
RUN export ARCH=$(echo ${BUILDPLATFORM} | cut -d / -f 2) \
  && curl -LO https://dl.k8s.io/release/v1.29.2/bin/linux/${ARCH}/kubectl && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
RUN wget https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
    chmod 700 get-helm-3 &&\
    ./get-helm-3

# Install required gems for our promotion scripts
RUN /bin/bash -l -c "echo 'gem: --no-ri --no-rdoc' > ~/.gemrc"
COPY gem.packages.list /tmp/gem.packages.list
RUN chmod +r /tmp/gem.packages.list
RUN gem install `cat /tmp/gem.packages.list | tr "\n" " "`

# python module installs:
COPY requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt

# always use python3
RUN ln -s /usr/bin/python3 /usr/bin/python

#install n module
RUN npm install -g n

ADD figlet-fonts /figlet-fonts