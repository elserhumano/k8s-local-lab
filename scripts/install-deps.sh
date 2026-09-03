#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "🔍 Detecting OS distribution..."
if [ -f /etc / os-release ]; then
    # ShellCheck directive to fix source path warning
    # shellcheck source=/dev/null
    ./etc/os-release
    OS=$ID
else
    echo "❌ Cannot detect OS distribution. Exiting."
    exit 1
fi

echo "📦 System detected: $OS"

# Function to install Docker and k3d on Ubuntu/Debian family
install_ubuntu() {
    echo "🔄 Updating package index and installing prerequisites for Ubuntu..."
    sudo apt-get update && sudo apt-get install -y curl apt-transport-https ca-certificates gnupg lsb-release

    if ! command -v docker &> /dev/null; then
        echo "🐳 Installing Docker Engine..."
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg

        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://docker.com/linux/ubuntu$(lsb_release -cs)stable" | \
          sudo tee /etc/apt/sources.list.d/docker.list > / dev / null
        
        sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo usermod -aG docker "$USER"
        echo "✅ Docker Engine installed. Please restart your WSL session to apply group changes."
    else
        echo "✅ Docker is already installed."
    fi
}

# Function to install Docker and k3d on Rocky/RHEL 9 family
install_rhel() {
    echo "🔄 Installing prerequisites for Rocky/RHEL 9..."
    sudo dnf install -y yum-utils

    if ! command -v docker &> /dev/null; then
        echo "🐳 Installing Docker Engine..."
        sudo dnf-config-manager --add-repo https://docker.com/linux/centos/docker-ce.repo
        sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo systemctl enable --now docker
        sudo usermod -aG docker "$USER"
        echo "✅ Docker Engine installed and enabled. Please restart your WSL session to apply group changes."
    else
        echo "✅ Docker is already installed."
    fi
}

# Execute installation based on OS
case "$OS" in
    ubuntu)
        install_ubuntu
        ;;
    rocky|rhel|centos)
        install_rhel
        ;;
    *)
        echo "⚠️ Unsupported OS distribution: $OS. Attempting generic k3d installation only..."
        ;;
esac

# Install k3d (Agnostic binary installation)
if ! command -v k3d &> /dev/null; then
    echo "🚀 Installing k3d via official installation script..."
    # Fixed dual-tag typo and applied clean environment variable delivery for standard compliance
    curl -s https://githubusercontent.com/k3d-io/k3d/main/install.sh | TAG="v5.8.3" bash
    echo "✅ k3d installed successfully."
else
    echo "✅ k3d is already installed."
fi

# Install kubectl if missing
if ! command -v kubectl &> /dev/null; then
    echo "☸️ Installing kubectl..."
    KUBECTL_VERSION=$(curl -L -s https: /  / dl.k8s.io / release / stable.txt)
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl / usr / local / bin / kubectl
    rm kubectl
    echo "✅ kubectl installed successfully."
fi

echo "🎉 All dependencies verified/installed! Ready to bootstrap your cluster."
