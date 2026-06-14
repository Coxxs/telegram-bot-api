#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Starting Telegram Bot API installation..."

# 0. Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run this script as root (use sudo)."
  exit 1
fi

# Prompt for API ID and API Hash
read -p "Enter your Telegram API ID: " API_ID
read -p "Enter your Telegram API HASH: " API_HASH

if [ -z "$API_ID" ] || [ -z "$API_HASH" ]; then
    echo "Error: API ID and API HASH are required!"
    exit 1
fi

# 1. Download the binary and make it executable
echo "Downloading telegram-bot-api..."
curl -fsSL https://github.com/Coxxs/telegram-bot-api/releases/latest/download/telegram-bot-api -o /usr/local/bin/telegram-bot-api
chmod +x /usr/local/bin/telegram-bot-api
echo "Download complete."

# 2. Create "telegram" system user and working directory
echo "Creating 'telegram' user and working directories..."
# Create user without a home directory and disable shell login for security
if ! id "telegram" &>/dev/null; then
    useradd -r -s /bin/false telegram
else
    echo "User 'telegram' already exists, skipping."
fi

# Create a directory for the bot API to store local files
WORK_DIR="/var/lib/telegram-bot-api"
mkdir -p "$WORK_DIR"
chown telegram:telegram "$WORK_DIR"

# 3. Create the systemd service file
echo "Creating systemd service file..."
cat <<EOF > /etc/systemd/system/telegram-bot-api.service
[Unit]
Description=Telegram Bot API Local Server
Documentation=https://core.telegram.org/bots/api
After=network.target

[Service]
User=telegram
Group=telegram
WorkingDirectory=$WORK_DIR
ExecStart=/usr/local/bin/telegram-bot-api --api-id=$API_ID --api-hash=$API_HASH --local --dir=$WORK_DIR
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# 4. Auto boot (enable and start the service)
echo "Reloading systemd daemon and enabling service..."
systemctl daemon-reload
systemctl enable telegram-bot-api
systemctl start telegram-bot-api

echo "==================================================="
echo "Installation complete!"
echo "The Telegram Bot API is now running locally."
echo "Check the service status using: sudo systemctl status telegram-bot-api"
echo "View live logs using: sudo journalctl -u telegram-bot-api -f"
echo "==================================================="