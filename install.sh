#!/bin/bash

# نمایش پیام نصب
echo -e "\e[32mStarting the installation process...\e[0m"

# دانلود و انتقال اسکریپت به /usr/local/bin
echo -e "\e[33mDownloading and installing the backup script...\e[0m"
curl -s https://raw.githubusercontent.com/arvinmoradi/ArM_Backuper_Marzban/main/backup_marzban_v1.3.sh -o /usr/local/bin/arm_backuper_marzban

# چک کردن موفقیت دانلود
if [ $? -eq 0 ]; then
    echo -e "\e[32mScript downloaded successfully.\e[0m"
else
    echo -e "\e[31mFailed to download the script! Exiting...\e[0m"
    exit 1
fi

# دادن دسترسی اجرایی به اسکریپت
chmod +x /usr/local/bin/arm_backuper_marzban

# نمایش پیام نصب موفقیت‌آمیز
echo -e "\e[32mInstallation complete. You can now use the command 'arm_backuper_marzban' to run the script.\e[0m"

# اجرای اسکریپت
echo -e "\e[33mRunning the script now...\e[0m"
/usr/local/bin/arm_backuper_marzban