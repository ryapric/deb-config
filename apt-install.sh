#!/usr/bin/env bash
set -eu

# Big Ol' Install & Config script for .deb systems (but probably just *Ubuntu)
# ============================================================================


# Set SUDO_USER if running as root user itself (useful for testing)
if [ "$UID" -eq 0 ]; then
    SUDO_USER=root
fi

if [ "$EUID" -ne 0 ]; then
    printf "This installer must be run as root, obviously. Aborting.\n" >&2
    exit 1
fi


# Top-level setting for what user supporting packages are being installed for
LIBS_USER="$SUDO_USER"


# Sys Installer BEGIN >>>
# -------------------

apt-get -qq update

# Prevent future interactive config prompt for tzdata
DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata

apt-get -qq dist-upgrade
apt-get -qq install \
    sudo \
    man \
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

# Add git branch highlighting to PS1 prompt (but note that this will ignore all the other PS1 changes the file tries)

# The following is currently NOT working as expected; some weird meta-ESC issue
# First, provide the `__git_ps1` command
#if [ ! -e ~/.bash_git ]; then
#    curl -L 'https://raw.github.com/git/git/master/contrib/completion/git-prompt.sh' > ~/.bash_git
#    echo -e "\nsource ~/.bash_git\n" >> ~/.bashrc
#    source ~/.bash_git
#fi
#
#if ! grep --quiet '__git_ps1' ~/.bashrc; then
#    echo -e "\nPS1=\"${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\W\[\033[00m\]\[\033[01;33m\]$(__git_ps1)\[\033[00m\]\$ \"\n" >> ~/.bashrc
#fi

if [ ! -e ~/.gitconfig ] || ! grep --quiet '[user]' ~/.gitconfig; then
    echo -e "[user]\n\tname = Ryan Price\n\temail = ryapric@gmail.com\n" > ~/.gitconfig
fi

# Sys Config END <<<
# --------------


# Docker Installer BEGIN >>>
# ----------------------

if ! command -v 'docker'; then
    curl -sSL https://get.docker.com | sh
fi

if [ "$UID" -ne 0 ]; then
    usermod -aG docker "$SUDO_USER"
fi

# Docker Installer END <<<
# --------------------


# R Installer BEGIN >>>
# -----------------

if ! grep --quiet 'cran' /etc/apt/sources.list; then
    cran_deb="deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran35/"
    echo "$cran_deb" | tee -a /etc/apt/sources.list
fi

# Retries, in case key signing fails
for key in 'E298A3A825C0D65DFD57CBB651716619E084DAB9'; do
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys "$key" ||
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys "$key" ||
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys "$key" ||
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys "$key" ||
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys "$key"
done

apt-get -qq update
apt-get -qq install \
    r-base \
    r-base-dev \
    r-recommended

sudo -H -u "$LIBS_USER" Rscript -e "
    dir.create(Sys.getenv('R_LIBS_USER'), recursive = TRUE); \
    pkgs <- c( \
        'tidyverse', \
        'data.table', \
        'devtools', \
        'testthat', \
        'knitr', \
        'roxygen2', \
        'rmarkdown', \
        'RcppRoll', \
        'odbc', \
        'RSQLite', \
        'RPostgres', \
        'RMySQL', \
        'RMariaDB' \
    ); \
    for (i in pkgs) { \
        inst_pkgs <- as.data.frame(installed.packages())\$Package; \
        if (!(i %in% inst_pkgs)) { \
            sprintf('%s is already installed', i); \
            install.packages(i, repos = 'https://cloud.r-project.org/', lib = Sys.getenv('R_LIBS_USER')) \
        } \
    }
"

if ! command -v 'rstudio'; then
    rstudio_debfile="${HOME}/rstudio-bin.deb"
    curl -sSL -o "$rstudio_debfile" 'https://download1.rstudio.org/rstudio-xenial-1.1.456-amd64.deb'
    gdebi --n "$rstudio_debfile"
    rm "$rstudio_debfile"
fi

# R Installer END <<<
# ---------------


# Python Installer BEGIN >>>
# ----------------------

apt-get install -qq \
    python3 \
    python3-pip \
    python3-venv \
    ipython3 \
    spyder3

sudo -H -u "$LIBS_USER" pip3 install --user \
    wheel \
    pandas \
    flask

# Python Installer END <<<
# --------------------


# DBeaver Installer BEGIN >>>
# -----------------------

if ! command -v 'dbeaver'; then
    dbeaver_debfile="${HOME}/dbeaver.deb"
    curl -sSL -o "$dbeaver_debfile" 'https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb'
    gdebi --n "$dbeaver_debfile"
    rm "$dbeaver_debfile"
fi

# DBeaver Installer END <<<
# ---------------------


apt-get -qy autoremove

exit 0
