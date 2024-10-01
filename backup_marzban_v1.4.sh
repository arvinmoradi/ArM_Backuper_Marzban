#!/bin/bash

# Clear the terminal screen
clear
sudo apt install toilet -y
sudo apt install -y toilet pv curl
sudo apt install figlet -y
# Function to display the welcome message
function display_welcome {
    clear
    echo "********************************************"
    toilet -f big --gay "ArM ❤️ ShH" | sed 's/^/* /; s/$/ */'
    echo -e "\e[32mArM Backuper Marzban\e[0m" # Project name in green
    echo "********************************************"
}

# Configuration file to store Telegram bot information
CONFIG_FILE="$HOME/telegram_bot_config.conf"
# File to store the compression method
METHOD_FILE="$HOME/compression_method.conf"
# File to store the script path
SCRIPT_PATH="$(realpath "$0")"

# Function to install required packages
function install_dependencies {
    echo "Installing required packages..."
    sudo apt update
    sudo apt install toilet -y
    sudo apt install -y toilet pv curl
    sudo apt install figlet -y
    echo "Dependencies installed."
}

# Function to check if the script is installed
function check_installation {
    if [ -f "$CONFIG_FILE" ] && [ -f "$METHOD_FILE" ]; then
        return 0
    else
        return 1
    fi
}

# Function to display the script status
function display_status {
    echo "********************************************"
    
    # Display bot information
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        echo -e "\e[32mBot Token: $BOT_TOKEN\e[0m"
        echo -e "\e[32mChat ID: $CHAT_ID\e[0m"
    else
        echo -e "\e[31mBot info not set!\e[0m"
    fi

    # Display cron job status
    cron_status=$(crontab -l | grep "$SCRIPT_PATH")
    if [ -n "$cron_status" ]; then
        interval=$(echo "$cron_status" | awk '{print $1}' | cut -d'/' -f2)
        echo -e "\e[32mCron Job is set to run every $interval minutes.\e[0m"
    else
        echo -e "\e[31mCron Job not set!\e[0m"
    fi

    # Display compression method
    if [ -f "$METHOD_FILE" ]; then
        source "$METHOD_FILE"
        if [ "$COMPRESSION_METHOD" == "1" ]; then
            echo -e "\e[32mCompression Method: gzip\e[0m"
        elif [ "$COMPRESSION_METHOD" == "2" ]; then
            echo -e "\e[32mCompression Method: xz\e[0m"
        else
            echo -e "\e[31mUnknown compression method!\e[0m"
        fi
    else
        echo -e "\e[31mCompression method not set!\e[0m"
    fi

    echo "********************************************"
}


# Function to display the main menu
function main_menu {
    while true; do
        display_welcome
        display_status
        if check_installation; then
            echo -e "\e[32mArM Backuper Marzban is installed.\e[0m"
            echo "1) Backup"
            echo "2) Restore"
            echo "3) Edit Bot Info"
            echo "4) Edit Compression Method"
            echo "5) Set Cron Job"
            echo "6) Remove Cron Job"
            echo "7) Uninstall"
            echo "8) Marzban Restart"
            echo "9) Exit"
            read -p "Choose an option: " option
            
            case $option in
                1) backup ;;
                2) restore ;;
                3) edit_bot_info ;;
                4) edit_compression_method ;;
                5) set_cron_job ;;
                6) remove_cron_job ;;
                7) uninstall ;;
                8) 
                    echo -e "\e[36mRestarting Marzban service...\e[0m"
                    sudo marzban restart
                    if [ $? -eq 0 ]; then
                        echo -e "\e[32mMarzban service restarted successfully.\e[0m"
                    else
                        echo -e "\e[31mFailed to restart Marzban service!\e[0m"
                    fi
                    read -p "Press any key to return to the main menu..." -n1 -s
                    ;;
                9) exit 0 ;;
                *) echo -e "\e[31mInvalid option! Please choose again.\e[0m" ;;
            esac
        else
            echo -e "\e[31mArM Backuper Marzban is not installed.\e[0m"
            echo "1) Install"
            echo "2) Exit"
            read -p "Choose an option: " option
            
            case $option in
                1) install_dependencies; install_script; echo -e "\e[32mArM Backuper Marzban installed. Returning to main menu.\e[0m" ;;
                2) exit 0 ;;
                *) echo -e "\e[31mInvalid option! Please choose again.\e[0m" ;;
            esac
        fi
    done
}


# Function to install the script and get Telegram info and compression method
function install_script {
    clear
    display_welcome
    
    # Display prompts for Telegram bot setup
    echo -e "\e[36mPlease enter your Telegram bot information:\e[0m"

    # Get the bot token from the user
    echo -e "\e[33mTelegram Bot Token:\e[0m \e[32m(You can get it from @BotFather)\e[0m"
    read -p "Enter your Telegram Bot Token: " BOT_TOKEN

    # Get the chat ID from the user
    echo -e "\e[33mChat ID:\e[0m \e[32m(Your Telegram chat ID)\e[0m"
    read -p "Enter your Chat ID: " CHAT_ID

    # Save the received information to a config file
    echo -e "\e[36mSaving Telegram configuration...\e[0m"
    {
        echo "BOT_TOKEN=\"$BOT_TOKEN\""
        echo "CHAT_ID=\"$CHAT_ID\""
    } > "$CONFIG_FILE"

    echo -e "\e[32mTelegram configuration saved successfully.\e[0m"

    # Choose compression method
    echo -e "\e[36mWhich compression method would you like to use?\e[0m"
    echo -e "\e[33m1) gzip\e[0m"
    echo -e "\e[33m2) xz\e[0m"
    read -p "Enter the number for your choice (1 or 2): " COMP_METHOD
    
    case $COMP_METHOD in
        1) 
            echo "COMPRESSION_METHOD=\"1\"" > "$METHOD_FILE"
            ;;
        2)
            echo "COMPRESSION_METHOD=\"2\"" > "$METHOD_FILE"
            ;;
        *)
            echo -e "\e[31mInvalid option! Exiting.\e[0m"
            exit 1
            ;;
    esac

    echo -e "\e[32mTelegram info and compression method saved.\e[0m"
}

# Function for backup
function backup {
    clear
    display_welcome

    # Load Telegram bot info
    source "$CONFIG_FILE"
    
    # Load compression method
    source "$METHOD_FILE"
    
    # Set compression method
    if [ "$COMPRESSION_METHOD" == "1" ]; then
        COMPRESS_CMD="gzip"
        ARCHIVE_EXT="tar.gz"
    else
        COMPRESS_CMD="xz"
        ARCHIVE_EXT="tar.xz"
    fi

    # Define total steps for progress (3 main steps: compress first directory + compress second directory + send files)
    total_steps=3

    # Initialize step counter
    current_step=0

    # Function to display progress bar
    function show_progress {
        progress=$((current_step * 100 / total_steps))
        bar=$(printf "%-${progress}s" "#" | tr ' ' '#')
        echo -ne "\e[34mProgress: [\e[32m$bar\e[34m] $progress%\r\e[0m"
    }

    # Function to display colorful messages
    function display_message {
        local message=$1
        local color=$2
        echo -e "\e[${color}m$message\e[0m"
    }

    # Start the backup process
    display_message "Starting backup process..." "36"
    show_progress

    # Backup paths
    DIR_PATH_1="/var/lib/marzban/"
    DIR_PATH_2="/opt/marzban/"

    # Check if both directories exist
    missing_paths=0

    if [ ! -d "$DIR_PATH_1" ]; then
        display_message "Error: Directory $DIR_PATH_1 does not exist." "31"
        missing_paths=$((missing_paths + 1))
    else
        display_message "Directory $DIR_PATH_1 exists." "32"
    fi

    if [ ! -d "$DIR_PATH_2" ]; then
        display_message "Error: Directory $DIR_PATH_2 does not exist." "31"
        missing_paths=$((missing_paths + 1))
    else
        display_message "Directory $DIR_PATH_2 exists." "32"
    fi

    # If any path is missing, stop the backup process
    if [ "$missing_paths" -gt 0 ]; then
        display_message "Backup process cannot proceed due to missing directories." "31"
        read -p "Press any key to return to the main menu..." -n1 -s
        return
    fi

    # Proceed with backup since both directories exist
    ARCHIVE_NAME_1="arm_backup_DB_$(date +%Y%m%d_%H%M%S).$ARCHIVE_EXT"
    ARCHIVE_NAME_2="arm_backup_opt_$(date +%Y%m%d_%H%M%S).$ARCHIVE_EXT"

    display_message "Compressing files from $DIR_PATH_1..." "33"
    if [ "$COMPRESS_CMD" == "gzip" ]; then
        tar -cf - -C "$DIR_PATH_1" . | pv -p -s $(du -sb "$DIR_PATH_1" | awk '{print $1}') | gzip > "$ARCHIVE_NAME_1"
    else
        tar -cf - -C "$DIR_PATH_1" . | pv -p -s $(du -sb "$DIR_PATH_1" | awk '{print $1}') | xz > "$ARCHIVE_NAME_1"
    fi

    if [ $? -eq 0 ]; then
        display_message "Compression completed successfully for the first directory." "32"
        current_step=$((current_step + 1))
        show_progress
    else
        display_message "Compression failed for the first directory!" "31"
        exit 1
    fi

    display_message "Compressing files from $DIR_PATH_2..." "33"
    if [ "$COMPRESS_CMD" == "gzip" ]; then
        tar -cf - -C "$DIR_PATH_2" . | pv -p -s $(du -sb "$DIR_PATH_2" | awk '{print $1}') | gzip > "$ARCHIVE_NAME_2"
    else
        tar -cf - -C "$DIR_PATH_2" . | pv -p -s $(du -sb "$DIR_PATH_2" | awk '{print $1}') | xz > "$ARCHIVE_NAME_2"
    fi

    if [ $? -eq 0 ]; then
        display_message "Compression completed successfully for the second directory." "32"
        current_step=$((current_step + 1))
        show_progress
    else
        display_message "Compression failed for the second directory!" "31"
        exit 1
    fi

    # Display 100% progress after both compressions
    show_progress
    echo -ne "\n"

    # Send the first compressed file to Telegram
    display_message "Sending the first compressed file to Telegram..." "36"
    curl -F chat_id="$CHAT_ID" -F document=@"$ARCHIVE_NAME_1" "https://api.telegram.org/bot$BOT_TOKEN/sendDocument" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        display_message "First file sent to Telegram successfully." "32"
        rm -f "$ARCHIVE_NAME_1"
        display_message "Deleted the first compressed file from the server." "36"
    else
        display_message "Failed to send the first file to Telegram!" "31"
        exit 1
    fi

    # Send the second compressed file to Telegram
    display_message "Sending the second compressed file to Telegram..." "36"
    curl -F chat_id="$CHAT_ID" -F document=@"$ARCHIVE_NAME_2" "https://api.telegram.org/bot$BOT_TOKEN/sendDocument" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        display_message "Second file sent to Telegram successfully." "32"
        rm -f "$ARCHIVE_NAME_2"
        display_message "Deleted the second compressed file from the server." "36"
    else
        display_message "Failed to send the second file to Telegram!" "31"
        exit 1
    fi

    # Display final 100% progress
    echo -ne "\e[34mProgress: [\e[32m####################\e[34m] 100%\n\e[0m"
    display_message "Backup and file transfer completed successfully." "32"

    # Wait for user input before returning to the main menu
    read -p "Press any key to return to the main menu..." -n1 -s
}

# Function for restore (Moving, extracting, and deleting the backup file with progress bars)
function restore {
    clear
    display_welcome
    echo -e "\e[36mLooking for the latest backup files in /root...\e[0m"

    # Finding the latest backup files in /root
    BACKUP_FILES=( $(ls -t /root/*.tar* 2>/dev/null | head -n 2) )

    # Check if we found exactly two files
    if [ ${#BACKUP_FILES[@]} -ne 2 ]; then
        echo -e "\e[31mExactly two backup files not found in /root.\e[0m"
        read -p "Press any key to return to the main menu..." -n1 -s
        return
    fi

    # Assigning the found backup files to variables
    BACKUP_FILE_DB="${BACKUP_FILES[0]}"
    BACKUP_FILE_OPT="${BACKUP_FILES[1]}"

    echo -e "\e[32mFound backup files:\e[0m"
    echo -e "  1. \e[34m$BACKUP_FILE_DB\e[0m"
    echo -e "  2. \e[34m$BACKUP_FILE_OPT\e[0m"

    # Remove existing files in /var/lib/marzban
    echo -e "\e[33mRemoving existing files from /var/lib/marzban...\e[0m"
    rm -rf /var/lib/marzban/*

    # Move and extract the first backup file (Database)
    echo -e "\e[33mMoving backup file $BACKUP_FILE_DB to /var/lib/marzban/...\e[0m"
    cp "$BACKUP_FILE_DB" /var/lib/marzban/
    if [ $? -eq 0 ]; then
        echo -e "\e[32mBackup file moved successfully.\e[0m"
    else
        echo -e "\e[31mFailed to move the backup file.\e[0m"
        read -p "Press any key to return to the main menu..." -n1 -s
        return
    fi

    echo -e "\e[33mExtracting the backup file to /var/lib/marzban/...\e[0m"
    cd /var/lib/marzban/ || exit
    case "$(basename "$BACKUP_FILE_DB")" in
        *.tar.gz)
            pv "$BACKUP_FILE_DB" | tar -xzf -
            ;;
        *.tar.xz)
            pv "$BACKUP_FILE_DB" | tar -xJf -
            ;;
        *.tar)
            pv "$BACKUP_FILE_DB" | tar -xf -
            ;;
        *)
            echo -e "\e[31mUnsupported backup file format.\e[0m"
            read -p "Press any key to return to the main menu..." -n1 -s
            return
            ;;
    esac

    echo -e "\e[32mExtraction completed successfully.\e[0m"
    # Remove the compressed file after successful extraction
    rm -f "$(basename "$BACKUP_FILE_DB")"
    echo -e "\e[32mBackup file deleted after extraction from /var/lib/marzban.\e[0m"

    # Remove existing files in /opt/marzban
    echo -e "\e[33mRemoving existing files from /opt/marzban...\e[0m"
    rm -rf /opt/marzban/*

    # Remove marzban directory if exists and recreate it
    if [ -d "/opt/marzban" ]; then
        echo -e "\e[33mRemoving existing marzban directory from /opt...\e[0m"
        rm -rf /opt/marzban
    fi
    echo -e "\e[33mCreating new marzban directory in /opt...\e[0m"
    mkdir /opt/marzban

    # Move and extract the second backup file (Opt)
    echo -e "\e[33mMoving backup file $BACKUP_FILE_OPT to /opt/marzban/...\e[0m"
    cp "$BACKUP_FILE_OPT" /opt/marzban/
    if [ $? -eq 0 ]; then
        echo -e "\e[32mBackup file moved successfully.\e[0m"
    else
        echo -e "\e[31mFailed to move the backup file.\e[0m"
        read -p "Press any key to return to the main menu..." -n1 -s
        return
    fi

    echo -e "\e[33mExtracting the backup file to /opt/marzban/...\e[0m"
    cd /opt/marzban/ || exit
    case "$(basename "$BACKUP_FILE_OPT")" in
        *.tar.gz)
            pv "$BACKUP_FILE_OPT" | tar -xzf -
            ;;
        *.tar.xz)
            pv "$BACKUP_FILE_OPT" | tar -xJf -
            ;;
        *.tar)
            pv "$BACKUP_FILE_OPT" | tar -xf -
            ;;
        *)
            echo -e "\e[31mUnsupported backup file format.\e[0m"
            read -p "Press any key to return to the main menu..." -n1 -s
            return
            ;;
    esac

    echo -e "\e[32mExtraction completed successfully.\e[0m"
    # Remove the compressed file after successful extraction
    rm -f "$(basename "$BACKUP_FILE_OPT")"
    echo -e "\e[32mBackup file deleted after extraction from /opt/marzban.\e[0m"

    # Remove original backup files from /root after successful extraction
    rm -f "$BACKUP_FILE_DB" "$BACKUP_FILE_OPT"
    echo -e "\e[32mOriginal backup files deleted from /root.\e[0m"

    # Completion message
    echo -e "\e[32mRestoration process completed successfully.\e[0m"
    read -p "Press any key to return to the main menu..." -n1 -s
}

# Function to edit bot info
function edit_bot_info {
    clear
    display_welcome
    echo "Current Bot Info:"
    source "$CONFIG_FILE"
    echo "Bot Token: $BOT_TOKEN"
    echo "Chat ID: $CHAT_ID"
    read -p "Enter new Telegram Bot Token: " NEW_BOT_TOKEN
    read -p "Enter new Chat ID: " NEW_CHAT_ID
    echo "BOT_TOKEN=\"$NEW_BOT_TOKEN\"" > "$CONFIG_FILE"
    echo "CHAT_ID=\"$NEW_CHAT_ID\"" >> "$CONFIG_FILE"
    echo "Bot info updated."
}

# Function to edit compression method
function edit_compression_method {
    clear
    display_welcome
    echo "Current Compression Method:"
    source "$METHOD_FILE"
    echo "Compression Method: $COMPRESSION_METHOD"
    echo "Which compression method would you like to use?"
    echo "1) gzip"
    echo "2) xz"
    read -p "Enter the number for your choice (1 or 2): " COMP_METHOD
    
    case $COMP_METHOD in
        1)
            echo "COMPRESSION_METHOD=\"1\"" > "$METHOD_FILE"
            echo "Compression method updated to gzip."
            ;;
        2)
            echo "COMPRESSION_METHOD=\"2\"" > "$METHOD_FILE"
            echo "Compression method updated to xz."
            ;;
        *)
            echo "Invalid option! Exiting."
            ;;
    esac
}

# Function to set a cron job for automatic backups
function set_cron_job {
    clear
    display_welcome
    echo "Set up Cron Job for automatic backups."
    read -p "Enter the backup interval in minutes: " interval

    if ! [[ "$interval" =~ ^[0-9]+$ ]]; then
        echo "Invalid input. Please enter a valid number."
        return
    fi

    (crontab -l | grep -v "$SCRIPT_PATH") | crontab -
    (crontab -l ; echo "*/$interval * * * * $SCRIPT_PATH --cron-backup") | crontab -

    echo "Cron job set to run the backup every $interval minutes."
}

# Function to remove the cron job
function remove_cron_job {
    clear
    display_welcome
    echo "Removing any existing cron jobs related to ArM Backuper Marzban..."
    (crontab -l | grep -v "$SCRIPT_PATH") | crontab -

    echo "Cron job removed successfully."
    read -p "Press any key to return to the main menu..." -n1 -s
}

# Function to uninstall the script
function uninstall {
    clear
    display_welcome
    echo "Are you sure you want to uninstall and delete all script-related files? (y/n)"
    read -p "Your choice: " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        (crontab -l | grep -v "$SCRIPT_PATH") | crontab -
        rm -f "$CONFIG_FILE" "$METHOD_FILE"
        
        echo "All script-related files and cron jobs have been deleted."
        echo "Clearing screen..."
        sleep 2
        clear
        exit 0
    else
        echo "Uninstallation cancelled."
    fi
}

# Check for --cron-backup flag to run the script from cron job
if [[ "$1" == "--cron-backup" ]]; then
    backup
    exit 0
fi

main_menu
