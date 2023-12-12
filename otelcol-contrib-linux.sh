#!/bin/bash

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Display a message in green color
print_success_message() {
    echo -e "\e[32m$1\e[0m"  # \e[32m sets the color to green, \e[0m resets the color
}

# Display a message in red color
print_error_message() {
    echo -e "\e[31m$1\e[0m"  # \e[31m sets the color to red, \e[0m resets the color
}

# Check if the OpenTelemetry Collector Contrib version is already installed
check_if_installed() {
    local installed_version
    installed_version=$(/usr/bin/otelcol-contrib --version 2>/dev/null)
    
    if [ -n "${installed_version}" ]; then
        # If it exists, tell the user and exit
        echo ""
        print_error_message "The OTel Collector Contrib version ${installed_version} is already installed."
        echo ""
        exit 0
    fi
}

# Get the sys arch
get_architecture() {
    case $(uname -m) in
        "x86_64" | "amd64")
            echo "amd64"
        ;;
        "aarch64" | "arm64")
            echo "arm64"
        ;;
        *)
            print_error_message "Unsupported architecture: $(uname -m)"
            exit 1
        ;;
    esac
}

# Check and install jq to retrieve the latest version of otelcol-contrib
install_jq() {
    log "Checking and installing jq..."
    if ! command -v jq &> /dev/null; then
        print_success_message "jq is not installed. Installing jq..."
        # Install jq based on the package manager
        if [ -f "/etc/debian_version" ]; then
            sudo apt-get update
            sudo apt-get install -y jq
            elif [ -f "/etc/redhat-release" ]; then
            sudo yum install -y jq
        else
            print_error_message "Unsupported Linux distribution. Please install jq manually."
            exit 1
        fi
    fi
}

# Gets the latest release version from GitHub API and strip leading v because it is not needed in the package name
get_latest_version() {
    local latest_version
    latest_version=$(curl -sS https://api.github.com/repos/open-telemetry/opentelemetry-collector-releases/releases/latest | jq -r .tag_name)
    echo "${latest_version#v}"  # Remove the leading "v"
}

# Constructs a complete download link for the latest otelcol-contrib
get_download_link() {
    local version=$1
    local arch=$2
    local distro=$3
    
    local package_format
    if [ "${distro}" == "debian" ]; then
        package_format="deb"
        elif [ "${distro}" == "rpm" ]; then
        package_format="rpm"
    else
        print_error_message "Unsupported distribution: ${distro}"
        exit 1
    fi
    
    echo "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${version}/otelcol-contrib_${version}_linux_${arch}.${package_format}"
}

# Download the package
download_package() {
    local download_link=$1
    local package_name=$2
    sudo curl -sSL -O "${download_link}" || { print_error_message "Failed to download ${package_name}"; exit 1; }
}

# Function to install on Debian-based systems
install_debian() {
    local version=$1
    local package_name=$2
    sudo dpkg -i "${package_name}" || sudo apt-get -f install
}

# Function to install on RPM-based systems
install_rpm() {
    local version=$1
    local package_name=$2
    sudo yum install -y "${package_name}"
}

# Cleanup the downloaded package
cleanup() {
    print_success_message "Cleaning up..."
    echo ""
    sudo rm -f "${PACKAGE_NAME}"
}

# Start

# Check if an installation of the otelcol-contrib already exists. If so, then exit
check_if_installed

# Check and install jq
install_jq

# Check the sys arch
ARCH=$(get_architecture)

# Get the latest release version of otelcol-contrib
VERSION=$(get_latest_version)

# Check if the release version is retrieved successfully
if [ -z "${VERSION}" ]; then
    print_error_message "Failed to retrieve the latest version from GitHub API."
    exit 1
fi

# Get the Linux distro
if [ -f "/etc/debian_version" ]; then
    DISTRO="debian"
    elif [ -f "/etc/redhat-release" ]; then
    DISTRO="rpm"
else
    print_error_message "Unsupported Linux distribution."
    exit 1
fi

# Construct the full download link based on the latest version, architecture, and distribution
DOWNLOAD_LINK=$(get_download_link "${VERSION}" "${ARCH}" "${DISTRO}")

# Download the otelcol-contrib package
PACKAGE_NAME=$(basename "${DOWNLOAD_LINK}")
download_package "${DOWNLOAD_LINK}" "${PACKAGE_NAME}"

# Install on Debian-based systems
if [ "${DISTRO}" == "debian" ]; then
    install_debian "${VERSION}" "${PACKAGE_NAME}"
    
    # Install on RPM-based systems
    elif [ "${DISTRO}" == "rpm" ]; then
    install_rpm "${VERSION}" "${PACKAGE_NAME}"
    
    # Unsupported distribution
else
    print_error_message "Unsupported Linux distribution."
    exit 1
fi

# Verify installation
if [ $? -eq 0 ]; then
    echo ""
    print_success_message "Circonus has installed the OpenTelemetry Collector Contrib version ${VERSION} successfully. Happy logging!"
    echo ""
    print_success_message "Caveat: Modify the configuration file "/etc/otelcol-contrib/config.yaml" to send data to Circonus."
    echo ""
    cleanup
else
    print_error_message "Installation failed. Please check the error messages above."
fi
