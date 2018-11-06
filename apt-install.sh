#!/usr/bin/env bash
set -eu

# Big Ol' Install & Config script for .deb systems (but probably just *Ubuntu)
# ============================================================================


# Bold echo
echob () {
    echo $(tput bold)$@
}


if [ "$EUID" -ne 0 ]; then
    echob "This installer must be run as root, obviously. Aborting." >&2
    exit 1
fi


# Top-level setting for what user supporting packages are being installed for
# This should help prevent the right user name from being masked from anywhere later
LIBS_USER="$SUDO_USER"


# Sys Installer BEGIN >>>
# -------------------

echob "Upgrading & installing system packages..."

apt-get -qq update

# Prevent future interactive config prompt for tzdata
DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata

apt-get -qq dist-upgrade
apt-get -qq install \
    sudo \
    man \
    nano \
    git \
    htop \
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
    unixodbc-dev \
    libreoffice \
    compton

# Sys Installer END <<<
# -----------------


# Sys Config BEGIN >>>
# ----------------

echob "Setting up dotfile/other configs..."
git clone https://github.com/ryapric/dotfiles.git dotfiles_tmp
cd dotfiles_tmp/
bash dotfiles.sh -d
cd .. && rm -rf dotfiles_tmp/

# Sys Config END <<<
# --------------


# Firefox Installer BEGIN >>>
# -----------------------

echob "Getting the latest version of Firefox..."

if [ ! -e /etc/apt/sources.list.d/*firefox* ]; then
    apt-add-repository ppa:mozillateam/firefox-next
    apt-get -qq update && apt-get -qy install firefox
fi

# Firefox Installer END <<<
# ---------------------


# Docker Installer BEGIN >>>
# ----------------------

echob "Installing Docker..."

if ! command -v 'docker'; then
    curl -L https://get.docker.com | sh
    usermod -aG docker "$LIBS_USER"
fi


# Docker Installer END <<<
# --------------------


# R Installer BEGIN >>>
# -----------------

echob "Installing R..."

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
    inst_pkgs <- as.data.frame(installed.packages())\$Package; \
    for (i in pkgs) { \
        if (i %in% inst_pkgs) { \
            print(paste(i, 'is already installed')); \
        } else { \
            install.packages(i, repos = 'https://cloud.r-project.org/', lib = Sys.getenv('R_LIBS_USER')) \
        } \
    }
"

if ! command -v 'rstudio'; then
    rstudio_debfile="${HOME}/rstudio-bin.deb"
    curl -L -o "$rstudio_debfile" 'https://download1.rstudio.org/rstudio-xenial-1.1.456-amd64.deb'
    gdebi --n "$rstudio_debfile"
    rm "$rstudio_debfile"
fi

# R Installer END <<<
# ---------------


# Python Installer BEGIN >>>
# ----------------------

echob "Installing Python..."

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


# Julia Installer BEGIN >>>
# ---------------------

echo "Installing Julia..."

julia_ver="1.0.1"

if ! command -v 'julia'; then
    curl -L \
        -o julia.tar.gz \
        https://julialang-s3.julialang.org/bin/linux/x64/1.0/julia-${julia_ver}-linux-x86_64.tar.gz
    tar -xf julia.tar.gz
    rm julia.tar.gz
    mkdir /usr/share/julia/
    mv julia-${julia_ver} /usr/share/julia/
    ln -s /usr/share/julia/julia-${julia_ver}/bin/julia /usr/bin/julia
fi

#if ! command -v 'atom'; then
#    curl -L -o atom.deb https://atom.io/download/deb
#    gdebi --n atom.deb
#    rm atom.deb
#fi

# Julia Installer END <<<
# -------------------


# DBeaver Installer BEGIN >>>
# -----------------------

echob "Installing DBeaver..."

if ! command -v 'dbeaver'; then
    dbeaver_debfile="${HOME}/dbeaver.deb"
    curl -L -o "$dbeaver_debfile" 'https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb'
    gdebi --n "$dbeaver_debfile"
    rm "$dbeaver_debfile"
fi

# DBeaver Installer END <<<
# ---------------------


# Microsoft Installer BEGIN >>>
# -------------------------

echob "Installing MS products (VS Code, Powershell, etc.)"

# Import keys for all MS products, add repo(s), and install
curl -L https://packages.microsoft.com/keys/microsoft.asc | apt-key add -

if [ ! -e /etc/apt/sources.list.d/vscode.list ]; then
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list
fi

if [ ! -e /etc/apt/sources.list.d/microsoft* ]; then
    curl -L https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list | tee /etc/apt/sources.list.d/microsoft.list
fi

apt-get -qq update
apt-get install -qy \
    code \
    powershell

# Microsoft Installer END <<<
# -----------------------


echob "Cleaning up..."

apt-get -qy autoremove

echob "Done!"

exit 0
