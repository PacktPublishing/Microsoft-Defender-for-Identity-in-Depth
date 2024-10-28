#!/bin/bash

# Install syslog with best practices
sudo apt-get update
sudo apt-get install -y rsyslog

# Configure log rotation
sudo cp /etc/logrotate.d/rsyslog /etc/logrotate.d/rsyslog.bak
sudo tee /etc/logrotate.d/rsyslog > /dev/null <<EOF
/var/log/syslog
{
    rotate 7
    daily
    missingok
    notifempty
    delaycompress
    compress
    postrotate
        /usr/lib/rsyslog/rsyslog-rotate
    endscript
}
EOF

# Install Azure Monitor Agent
wget https://aka.ms/azcmagent -O ~/install_linux_azcmagent.sh
sudo bash ~/install_linux_azcmagent.sh

# Other Azure related things and best practices for an Ubuntu server in Azure
# ...

sudo wget -O Forwarder_AMA_installer.py https://raw.githubusercontent.com/Azure/Azure-Sentinel/master/DataConnectors/Syslog/Forwarder_AMA_installer.py&&sudo python3 Forwarder_AMA_installer.py

# Restart syslog service
sudo systemctl restart rsyslog

echo "Script execution completed."