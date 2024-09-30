#!/bin/bash

# ایجاد پوشه موقت برای دانلود فایل‌ها
TEMP_DIR=$(mktemp -d)

# دانلود فایل های مورد نیاز
echo "Downloading backup-marzban.sh..."
curl -o "$TEMP_DIR/backup-marzban.sh" https://raw.githubusercontent.com/arvinmroadi/ArM_Backuper_Marzban/main/backup_marzban_v1.3.sh

# انتقال فایل backup-marzban.sh به مسیر /root/
echo "Moving backup-marzban.sh to /root/..."
mv "$TEMP_DIR/backup-marzban.sh" /root/backup-marzban.sh

# ایجاد دسترسی اجرا برای فایل backup-marzban.sh
echo "Setting execute permissions for backup-marzban.sh..."
chmod +x /root/backup-marzban.sh

# ایجاد alias برای اجرای ساده‌تر
echo "alias arm_backuper_marzban='/root/backup-marzban.sh'" >> ~/.bashrc
source ~/.bashrc

# حذف پوشه موقت
rm -rf "$TEMP_DIR"

echo "Installation complete. You can now use the command 'arm_backuper_marzban' to run the script."
