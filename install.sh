#!/bin/bash

# Download the backup script from GitHub
wget https://raw.githubusercontent.com/arvinmroadi/ArM_Backuper_Marzban/main/backup_marzban.sh -O /usr/local/bin/backup_marzban.sh

# Check if the download was successful
if [ $? -ne 0 ]; then
    echo "Failed to download the backup script. Please check your internet connection or repository URL."
    exit 1
fi

# Make the script executable
chmod +x /usr/local/bin/backup_marzban.sh

# Create a shortcut script in /usr/local/bin/ for easier access
echo "#!/bin/bash" > /usr/local/bin/arm_backuper_marzban
echo "/usr/local/bin/backup_marzban.sh" >> /usr/local/bin/arm_backuper_marzban

# Make the shortcut script executable
chmod +x /usr/local/bin/arm_backuper_marzban

# Inform the user that the installation is complete
echo -e "\e[32mInstallation complete!\e[0m You can now run the script using: \e[34marm_backuper_marzban\e[0m"
