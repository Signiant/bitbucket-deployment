FROM node:18-bullseye
LABEL maintainer=sre@signiant.com

# Install a base set of packages from the default repo
# && Install packages from the repoforge repo
# && make sure we're running latest of everything
# && Install the nodejs package from nodesource
# && Install yarn
# && Install pip
RUN apt update \
  && apt install -y python3 python3-pip figlet jq

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
# Install the AWS CLI - used by promo process
# Install shyaml - used by promo process to ECS
# Install boto and requests - used by the S3 MIME type setter
# Install MaestroOps, slackclient, and datadog
# Install dns - used by eb_check_live_env.py
RUN pip install awscli shyaml boto boto3 requests maestroops datadog slackclient pyyaml dnspython3 pyyaml

RUN ln -s /usr/bin/python3 /usr/bin/python

ADD figlet-fonts /figlet-fonts