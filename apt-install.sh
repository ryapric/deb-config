#!/usr/bin/env sh
set -eu

# Big Ol' Install & Config script for .deb systems
# ================================================


if [ "$EUID" -ne 0 ]; then
    printf "This installer must be run as root, obviously. Aborting.\n" >&2
fi


# Sys Installer BEGIN >>>
# -------------------

apt-get update
apt-get dist-upgrade -y
apt-get install -y \
    curl \
    gnupg2 \
    lsb-release \
    




# Sys Installer END <<<
# -----------------


# Docker Installer BEGIN >>>
# ----------------------

curl -sSL https://get.docker.com | sh

# Docker Installer END <<<
# --------------------


# R Installer BEGIN >>>
# -----------------


# R Installer END <<<
# ---------------


# Python Installer BEGIN >>>
# ----------------------

# Python Installer END <<<
# --------------------


apt-get autoremove -y

exit 0
