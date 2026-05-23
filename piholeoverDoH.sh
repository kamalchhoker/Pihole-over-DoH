#!/bin/bash
# Pull the Cloudflared binary from server

curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared jammy main' | sudo tee /etc/apt/sources.list.d/cloudflared.list
sudo apt-get update
sudo apt-get install cloudflared

# Create cloudflared user
sudo useradd -r -m -s /bin/false cloudflared

# Define the file path
FILE_PATH="/etc/systemd/system/cloudflared.service"

# Write the service file
sudo tee "$FILE_PATH" > /dev/null << 'EOF'
[Unit]
Description=cloudflared DNS over HTTPS proxy
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=cloudflared
ExecStart=/usr/bin/cloudflared proxy-dns --port 53 --upstream https://1.1.1.1/dns-query
Restart=on-failure
RestartSec=5s
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF

if [ -f "$FILE_PATH" ]; then
    echo "File created successfully at $FILE_PATH"
else
    echo "Failed to create file"
    exit 1
fi

sudo systemctl daemon-reexec
sudo systemctl enable cloudflared
sudo systemctl start cloudflared
echo "cloudflared started"   
