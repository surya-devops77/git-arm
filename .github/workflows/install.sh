#!/bin/bash

# Update package lists
sudo apt update

# Define environment variables
USERNAME="demouser"
PASSWORD="demouser123"
GIT_USERNAME="surya-devops77"
GIT_PASSWORD="Siva.9715"
GIT_FRONTEND_REPO="https://github.com/surya-devops77/demo.git"
GIT_BACKEND_REPO="https://github.com/surya-devops77/arm.git"
SSH_CONFIG_DIR="/etc/ssh/sshd_config.d"

# Create the user and set the password
echo -e "$PASSWORD\n$PASSWORD" | sudo adduser --gecos "" $USERNAME

# Add the user to the sudo group
sudo usermod -aG sudo $USERNAME

# Grant sudo privileges without password
echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers.d/$USERNAME

# Set correct permissions for the sudoers file
sudo chmod 440 /etc/sudoers.d/$USERNAME

# Modify any .conf file in sshd_config.d to enable password authentication

for CONF_FILE in "$SSH_CONFIG_DIR"/*.conf; do
    if [ -f "$CONF_FILE" ]; then
        sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' "$CONF_FILE"
    fi
done

# Restart SSH service to apply changes
sudo systemctl restart ssh

echo "User $USERNAME has been created, granted sudo privileges without password, and SSH password authentication is enabled in sshd_config and all .conf files in sshd_config.d."

# Step 1: Add Swap Memory
# Check if swap is already configured
free -h

# Allocate a 4G swap file
sudo fallocate -l 4G /swapfile

# Verify the allocated space
ls -lh /swapfile

# Set correct permissions
sudo chmod 600 /swapfile

# Mark the file as swap
sudo mkswap /swapfile

# Enable the swap file
sudo swapon /swapfile

# Verify swap is enabled
free -h

# Step 2: Install Node.js
sudo apt-get install -y zip unzip wget
curl -sL https://deb.nodesource.com/setup_22.x | sudo bash -
sudo apt install -y nodejs
sudo npm install -g pm2
sudo apt-get install -y build-essential
sudo npm install -g yarn

echo "Node.js and tools installed:"
yarn --version
node --version
npm --version

# Step 3: Install Nginx Web Server
sudo apt-get install -y nginx

# Start and check the Nginx service
#sudo service nginx start

# Step 4: Install Certbot for SSL
sudo apt-get install -y certbot python3-certbot-nginx

# Step 5: Setup Application Paths
sudo mkdir -p /opt/nodejs/frontend /opt/nodejs/backend

# Step 6: Configure Git for demouser
echo '#!/bin/bash' > $HOME/git_creds.sh
echo "sleep 1" >> $HOME/git_creds.sh
echo "echo username=$GIT_USERNAME" >> $HOME/git_creds.sh
echo "echo password=$GIT_PASSWORD" >> $HOME/git_creds.sh
git config --global credential.helper "/bin/bash $HOME/git_creds.sh"

# Step 7: Clone Git Repositories
cd /opt/nodejs
git clone $GIT_FRONTEND_REPO
git clone $GIT_BACKEND_REPO

# Rename Cloned Directories
#mv demodeployments frontend
#mv deployments backend


# Switch Both Repos to Dev Branch
cd /opt/nodejs/Tone-Frontend
git checkout main
cd /opt/nodejs/Tone-Backend
git checkout main

# Step 8: Configure Nginx
cat <<EOL | sudo tee /etc/nginx/sites-available/frontend.conf
server {
    listen 80;
    server_name dev-dashboard.tonetrackr.com;
    if (\$http_x_forwarded_proto != 'https') {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name dev-dashboard.tonetrackr.com;
    ssl_certificate /etc/letsencrypt/live/dev-dashboard.tonetrackr.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/dev-dashboard.tonetrackr.com/privkey.pem;

    root /opt/nodejs/Tone-Frontend/build;
    index index.html index.htm index.nginx-debian.html;

    location / {
        try_files \$uri \$uri/ /index.html\$query_string;
    }
}
EOL

cat <<EOL | sudo tee /etc/nginx/sites-available/backend.conf
server {
    listen 80;
    server_name dev-dashboard.tonetrackr.com;
    if (\$http_x_forwarded_proto != 'https') {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name dev-dashboard.tonetrackr.com;
    ssl_certificate /etc/letsencrypt/live/dev-dashboard.tonetrackr.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/dev-dashboard.tonetrackr.com/privkey.pem;

    root /opt/nodejs/Tone-Frontend/build;
    index index.html index.htm index.nginx-debian.html;

    location / {
        try_files \$uri \$uri/ /index.html\$query_string;
    }
}
EOL

# Enable Nginx Configurations
sudo ln -s /etc/nginx/sites-available/frontend.conf /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/backend.conf /etc/nginx/sites-enabled/

# Restart Nginx
#sudo systemctl restart nginx

echo "Setup completed successfully."
