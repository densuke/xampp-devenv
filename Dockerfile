FROM php:8.3-apache
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000



WORKDIR /usr/local

# ツールのインストール

# GitHub CLI
SHELL ["/bin/bash", "-e", "-o", "pipefail", "-c"]
# hadolint ignore=DL3008,DL3015
RUN <<EOT
    (type -p wget >/dev/null || (apt-get update && apt-get install wget -y))
	mkdir -p -m 755 /etc/apt/keyrings
    out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg 
    cat $out | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null 
	chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg 
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list
	apt-get update
	apt-get install gh -y
    apt-get clean
    rm -rf /var/lib/apt/lists
EOT

# hadolint ignore=DL3008
RUN <<EOT
    apt-get update
    apt-get install -y curl git sudo unzip --no-install-recommends 
    apt-get upgrade -y --auto-remove --purge
    apt-get clean
    rm -rf /var/lib/apt/lists
EOT

WORKDIR /usr/local/etc/php

RUN <<EOT
    export MAKEFLAGS="-j$(nproc)"
    docker-php-ext-install mysqli pdo_mysql opcache
    pecl install xdebug
    ln -s php.ini-development php.ini
EOT

COPY conf.d/*.ini conf.d/

# ユーザーの作成
RUN <<EOT
    groupadd --gid $USER_GID $USERNAME
    useradd -s /bin/bash -m --uid $USER_UID --gid $USER_GID -m $USERNAME
    mkdir /workspaces
    chown $USERNAME:$USERNAME /workspaces
    # sudo設定(パス無し実行)
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
EOT

EXPOSE 80
WORKDIR /workspaces
USER $USERNAME