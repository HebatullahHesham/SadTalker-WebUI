#!/bin/bash

# Ensure the script itself is executable
chmod +x "$0"

# Move to the directory where the script is located
cd "$(dirname "${BASH_SOURCE[0]}")"

# Check if the script path contains spaces
if [[ "$(pwd)" =~ " " ]]; then 
    echo "This script relies on Miniconda which cannot be silently installed under a path with spaces."
    exit
fi

OS_ARCH=$(uname -m)
case "${OS_ARCH}" in
    x86_64*)    OS_ARCH="x86_64";;
    arm64*)     OS_ARCH="aarch64";;
    aarch64*)   OS_ARCH="aarch64";;
    *)          echo "Unknown system architecture: $OS_ARCH! This script runs only on x86_64 or arm64" && exit
esac

# Configurations
INSTALL_DIR="$(pwd)/installer_files"
CONDA_ROOT_PREFIX="$(pwd)/installer_files/conda"
INSTALL_ENV_DIR="$(pwd)/installer_files/env"
MINICONDA_DOWNLOAD_URL="https://repo.anaconda.com/miniconda/Miniconda3-py310_23.3.1-0-Linux-${OS_ARCH}.sh"
conda_exists="F"

# Check if Conda is installed
if "$CONDA_ROOT_PREFIX/bin/conda" --version &>/dev/null; then 
    conda_exists="T"
fi

# (if necessary) install git and conda into a contained environment
# Download Miniconda
if [ "$conda_exists" == "F" ]; then
    echo "Downloading Miniconda from $MINICONDA_DOWNLOAD_URL to $INSTALL_DIR/miniconda_installer.sh"

    mkdir -p "$INSTALL_DIR"
    curl -Lk "$MINICONDA_DOWNLOAD_URL" > "$INSTALL_DIR/miniconda_installer.sh"

    chmod u+x "$INSTALL_DIR/miniconda_installer.sh"
    bash "$INSTALL_DIR/miniconda_installer.sh" -b -p $CONDA_ROOT_PREFIX

    # Test the conda binary
    echo "Miniconda version:"
    "$CONDA_ROOT_PREFIX/bin/conda" --version
fi

# Create the installer environment
if [ ! -e "$INSTALL_ENV_DIR" ]; then
    "$CONDA_ROOT_PREFIX/bin/conda" create -y -k --prefix "$INSTALL_ENV_DIR" python=3.10
fi

# Check if conda environment was created
if [ ! -e "$INSTALL_ENV_DIR/bin/python" ]; then
    echo "Conda environment is empty."
    exit
fi

# Set environment isolation
export PYTHONNOUSERSITE=1
unset PYTHONPATH
unset PYTHONHOME
export CUDA_PATH="$INSTALL_ENV_DIR"
export CUDA_HOME="$CUDA_PATH"

# Activate the installer environment
source "$CONDA_ROOT_PREFIX/etc/profile.d/conda.sh" # Needed to avoid conda 'shell not initialized' error
conda activate "$INSTALL_ENV_DIR"

# Set up the installer environment
python launcher.py
