# ResourceSpace Docker Installation Script

This interactive Bash script automates the installation of [ResourceSpace](https://www.resourcespace.com/) on Docker within an Ubuntu 24.04 virtual machine. It sets up a dedicated disk for Docker's data-root, provides user-friendly prompts for configuration, and includes a workaround for the base URL setup issue. This script is ideal for quickly deploying a fully functional ResourceSpace instance.

## Features
- Installs Docker and necessary dependencies.
- Configures a second disk as Docker's data-root for better storage management.
- Clones the ResourceSpace Docker repository and deploys it using Docker Compose.
- Provides interactive prompts for MySQL passwords, base URL, and admin credentials.
- Includes a workaround for the base URL configuration during the web setup.
- Renames the original Docker data directory for backup purposes.

## Prerequisites
- A fresh Ubuntu 24.04 virtual machine.
- A second disk attached to the VM for use as Docker's data-root.
- Internet access for downloading dependencies and the ResourceSpace repository.
- Basic familiarity with the terminal and Docker concepts.

## Usage

### Step 1: Save and Prepare the Script
1. Copy the script into a file named `install_resourcespace.sh`.
2. Make the script executable:
   ```bash
   chmod +x install_resourcespace.sh
