#!/bin/bash

# Check if the script is run with sudo privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo privileges (e.g., sudo ./install_resourcespace.sh)"
    exit 1
fi

# Stage 1: Check if Docker is installed; if not, update system and install Docker
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Updating system and installing Docker..."
    apt update && apt autoremove -y && apt dist-upgrade -y && apt autoremove -y && apt clean
    apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io
    systemctl start docker
    systemctl enable docker
    usermod -aG docker "$SUDO_USER"
    echo "System will reboot now to apply updates and group changes."
    echo "Please run this script again after reboot to continue the installation."
    reboot
    exit 0
fi

# Stage 2: Configure the second disk for Docker data-root
echo "Scanning for available disks..."
echo "- - -" | tee /sys/class/scsi_host/host*/scan > /dev/null
echo "Available block devices:"
lsblk
echo "Please enter the device name for the second disk (e.g., /dev/sdb):"
read -r SECOND_DISK

# Validate input
if [ ! -b "$SECOND_DISK" ]; then
    echo "Error: $SECOND_DISK is not a valid block device. Please check and rerun the script."
    exit 1
fi

# Set up LVM and mount the disk
pvcreate "$SECOND_DISK"
vgcreate docker_vg "$SECOND_DISK"
lvcreate -n docker_data -l 100%FREE docker_vg
systemctl stop docker
mkdir -p /mnt/docker_data
echo "/dev/docker_vg/docker_data /mnt/docker_data xfs defaults 0 0" | tee -a /etc/fstab
mount -a
rsync -av /var/lib/docker/ /mnt/docker_data/
echo '{
    "data-root": "/mnt/docker_data"
}' | tee /etc/docker/daemon.json

# Rename the original Docker data directory for backup
echo "Renaming original Docker data directory to /var/lib/docker.old for backup..."
mv /var/lib/docker /var/lib/docker.old

systemctl start docker

# Stage 3: Install Git and clone the ResourceSpace Docker repository
apt update && apt install -y git
git clone https://github.com/resourcespace/docker.git ~/resourcespace

# Stage 4: Collect user inputs for environment variables
echo "Please enter the MySQL password for the resourcespace_rw user:"
read -r MYSQL_PASSWORD
echo "Please enter the MySQL root password:"
read -r MYSQL_ROOT_PASSWORD
echo "Please enter the base URL for ResourceSpace (e.g., http://dam.example.com):"
read -r BASE_URL
echo "Please enter the admin email:"
read -r ADMIN_EMAIL
echo "Please enter the admin password:"
read -r ADMIN_PASSWORD

# Create the db.env file with user inputs
cat > ~/resourcespace/db.env << EOL
MYSQL_PASSWORD=$MYSQL_PASSWORD
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
MYSQL_DATABASE=resourcespace
MYSQL_USER=resourcespace_rw
EOL

# Stage 5: Deploy ResourceSpace using Docker Compose
cd ~/resourcespace
docker compose up --build -d

# Stage 6: Provide setup instructions
echo "ResourceSpace is now running. Please access it at http://localhost to complete the web setup."
echo "IMPORTANT: During the setup, use 'http://localhost' as the base URL to avoid errors."
echo "Use the following details during the setup process:"
echo "- **MySQL server**: mariadb"
echo "- **MySQL username**: resourcespace_rw"
echo "- **MySQL password**: $MYSQL_PASSWORD"
echo "- **MySQL binary path**: <leave blank>"
echo "- **Base URL**: http://localhost"
echo "- **Admin e-mail**: $ADMIN_EMAIL"
echo "- **Admin password**: $ADMIN_PASSWORD"
echo "- **Email from address**: example@example.com (adjust if necessary)"

# Wait for the user to complete the setup
echo "Once you have completed the web setup, press Enter to continue..."
read -r

# Stage 7: Automatically update config.php with the correct base URL
echo "Updating config.php with the correct base URL..."
docker exec -i resourcespace /bin/bash -c "sed -i 's|http://localhost|${BASE_URL}|g' /var/www/html/include/config.php"

echo "Setup is complete! ResourceSpace should now be accessible at $BASE_URL."
echo "If you encounter issues, ensure all services are running with 'docker ps'."
