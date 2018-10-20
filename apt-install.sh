#!/usr/bin/env bash
set -eu

# Big Ol' Install & Config script for .deb systems (but probably just *Ubuntu)
# ============================================================================


if [ "$EUID" -ne 0 ]; then
    printf "This installer must be run as root, obviously. Aborting.\n" >&2
    exit 1
fi


# Sys Installer BEGIN >>>
# -------------------

apt-get update

# Prevent interactive config prompt for tzdata
DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata

apt-get dist-upgrade -y
apt-get install -y \
    sudo \
    nano \
    git \
    gcc \
    make \
    perl \
    apt-transport-https \
    lsb-release \
    gnupg2 \
    gdebi-core \
    wget \
    curl \
    libssl-dev \
    libxml2-dev \
    libcurl4-openssl-dev \
    libcairo2-dev \
    libsqlite0-dev \
    libmariadb-dev \
    libpq-dev \
    libssh2-1-dev \
    unixodbc-dev

# Sys Installer END <<<
# -----------------


# Sys Config BEGIN >>>
# ----------------

printf "[user]\n    name = Ryan Price\n    email = ryapric@gmail.com\n" > ~/.gitconfig

# Sys Config END <<<
# --------------


# Docker Installer BEGIN >>>
# ----------------------

if ! command -v 'docker'; then
    curl -sSL https://get.docker.com | sh
fi

usermod -aG docker "$SUDO_USER"

# Docker Installer END <<<
# --------------------


# R Installer BEGIN >>>
# -----------------

if ! grep --quiet 'cran' /etc/apt/sources.list; then
    cran_deb="deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran35/"
    echo "$cran_deb" | tee -a /etc/apt/sources.list
fi

for key in 'E298A3A825C0D65DFD57CBB651716619E084DAB9'; do
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys "$key" ||
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys "$key" ||
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys "$key" ||
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys "$key" ||
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys "$key"
done

apt-get update
apt-get install -y \
    r-base \
    r-base-dev \
    r-recommended

Rscript -e "
    install.packages( \
        c( \
            'tidyverse', \
            'data.table', \
            'devtools', \
            'RcppRoll', \
            'odbc', \
            'RSQLite', \
            'RPostgres', \
            'RMySQL', \
            'RMariaDB' \
        ), \
        dependencies = TRUE, \
        repos = 'https://cloud.r-project.org/' \
    )
"

rstudio_debfile="~/rstudio-bin.deb"
curl -o "$rstudio_debfile" 'https://download1.rstudio.org/rstudio-xenial-1.1.456-amd64.deb'
gdebi --n "$rstudio_debfile"
rm "$rstudio_debfile"

# R Installer END <<<
# ---------------


# Python Installer BEGIN >>>
# ----------------------

apt-get install -y \
    python3 \
    python3-pip \
    ipython3 \
    spyder3

pip3 install \
    pandas \
    requests \
    flask

# Python Installer END <<<
# --------------------


apt-get autoremove -y

exit 0
