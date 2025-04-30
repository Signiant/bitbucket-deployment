FROM node:20-bullseye
LABEL maintainer=sre@signiant.com

ARG BUILDPLATFORM
ARG TENV_VERSION="4.4.0"

# Install a base set of packages from the default repo
COPY apt.packages.list /tmp/apt.packages.list
RUN apt update \
  && apt upgrade -y \
  && apt install -y --no-install-recommends `cat /tmp/apt.packages.list | tr "\n" " "` \
  && rm /tmp/apt.packages.list

# Install required gems for our promotion scripts
COPY gem.packages.list /tmp/gem.packages.list
RUN /bin/bash -l -c "echo 'gem: --no-ri --no-rdoc' > ~/.gemrc" \
  && chmod +r /tmp/gem.packages.list \
  && gem install `cat /tmp/gem.packages.list | tr "\n" " "` \
  && rm /tmp/gem.packages.list

# Install Python modules and link python to python3
COPY requirements.txt /tmp/requirements.txt
RUN pip install docker-compose helm \
  && pip install --upgrade setuptools \
  && pip install -r /tmp/requirements.txt \
  && ln -s /usr/bin/python3 /usr/bin/python \
  && rm /tmp/requirements.txt

# Install n module
RUN npm install -g n

# Install and configure tenv
ENV TENV_AUTO_INSTALL=true
ENV TFENV_TERRAFORM_DEFAULT_VERSION=1.7.5
RUN export ARCH=$(echo ${BUILDPLATFORM} | cut -d / -f 2) \
  && wget https://github.com/tofuutils/tenv/releases/download/v${TENV_VERSION}/tenv_v${TENV_VERSION}_${ARCH}.deb \
  && dpkg -i tenv_v${TENV_VERSION}_${ARCH}.deb

# Install k8s tooling
RUN export ARCH=$(echo ${BUILDPLATFORM} | cut -d / -f 2) \
  && curl -LO https://dl.k8s.io/release/v1.29.2/bin/linux/${ARCH}/kubectl \
  && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
  && wget https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
  && chmod 700 get-helm-3 \
  && ./get-helm-3

# Add figlet-fonts directory
ADD figlet-fonts /figlet-fonts