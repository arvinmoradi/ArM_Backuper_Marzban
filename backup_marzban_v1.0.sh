#!/bin/bash

# Clear the terminal screen
clear

# Function to display the welcome message
function display_welcome {
    clear
    echo "********************************************"
    toilet -f big --gay "ArM ❤️ ShH" | sed 's/^/* /; s/$/ */'
    echo -e "\e[32mArM Backuper Marzban v1.0\e[0m" # Project name in green
    echo "********************************************"
}
# Function to display colorful messages
function display_message {
    local message=$1
    local color=$2
    echo -e "\e[${color}m$message\e[0m"
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
    echo "Dependencies installed."
}
function main_menu {
    # Setting up a general trap for SIGINT (CTRL+C) to exit the script cleanly
    trap exit_script SIGINT

    while true; do
        display_welcome
        display_status

        # Check if ArM Backuper Marzban is installed
        if check_installation; then
            echo -e "\e[32mArM Backuper Marzban is installed.\e[0m"
            echo "1) Backup"
            echo "2) Restore"
            echo "3) Edit Bot Info"
            echo "4) Edit Compression Method"
            echo "5) Set Cron Job"
            echo "6) Remove Cron Job"
            echo "7) Marzban Restart"
            echo "8) Uninstall"
            echo "9) Exit"

            read -p "Choose an option: " option
            
            case $option in
                1) backup ;;
                2) restore ;;
                3) edit_bot_info ;;
                4) edit_compression_method ;;
                5) set_cron_job ;;
                6) remove_cron_job ;;
                7) restart_marzban ;;    # Call the restart function for Marzban
                8) uninstall ;;
                9) exit_script ;;    # Proper exit
                *) echo -e "\e[31mInvalid option! Please choose again.\e[0m" ;;
            esac
        else
            echo -e "\e[31mArM Backuper Marzban is not installed.\e[0m"
            echo "1) Install"
            echo "2) Exit"

            read -p "Choose an option: " option
            
            case $option in
                1) 
                    install_dependencies
                    install_script
                    echo -e "\e[32mArM Backuper Marzban installed. Returning to main menu.\e[0m"
                    ;;
                2) exit_script ;;  # Proper exit
                *) echo -e "\e[31mInvalid option! Please choose again.\e[0m" ;;
            esac
        fi
    done
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
    cron_status=$(crontab -l 2>/dev/null | grep "$SCRIPT_PATH")
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

    # Display database type
    detect_database
    echo -e "\e[32mDatabase Type: $DB_TYPE\e[0m"

    echo "********************************************"
}
function detect_database {
    # Define the path to the .env file
    ENV_FILE="/opt/marzban/.env"

    # Check if the .env file exists
    if [ ! -f "$ENV_FILE" ]; then
        echo "Error: .env file not found!"
        DB_TYPE="Unknown"
        return
    fi

    # Check for MySQL by looking for MYSQL_ROOT_PASSWORD line with any value
    if grep -q '^[[:space:]]*MYSQL_ROOT_PASSWORD[[:space:]]*=' "$ENV_FILE"; then
        DB_TYPE="MySQL"
    else
        DB_TYPE="SQLite"
    fi
}

function return_to_main_menu {
    echo -e "\e[32mDatabase migration completed. Returning to main menu...\e[0m"
    main_menu
}

# Continue after the first restart and proceed with the second part
function continue_after_restart {
    echo -e "\e[33mFirst restart complete. Continuing with additional setup...\e[0m"

    # Second restart (or any other necessary setup) would go here
    # Example: Start the containers again and wait for user input
    echo -e "\e[33mStarting Marzban again... Waiting for manual termination.\e[0m"
    
    # Restart the containers in detached mode again
    docker-compose -f /opt/marzban/docker-compose.yml up -d

    # Monitor logs and wait for user input (CTRL+C) for final termination
    while true; do
        docker-compose -f /opt/marzban/docker-compose.yml logs --tail=10 | grep -q "Uvicorn running on http://0.0.0.0:8000"
        if [[ $? -eq 0 ]]; then
            echo -e "\e[32mMarzban is running. Press CTRL+C to stop and return to the main menu.\e[0m"
            break
        fi
        sleep 5
    done

    # Wait for user to press CTRL+C
    trap "echo -e '\e[31mExiting...'; docker-compose -f /opt/marzban/docker-compose.yml down; return_to_main_menu" SIGINT
    while true; do :; done  # Infinite loop until CTRL+C is pressed
}

# Return to the main menu
function return_to_main_menu {
    echo -e "\e[32mReturning to main menu...\e[0m"
    main_menu
}


# Function to handle the CTRL + C signal during the Marzban restart process
function ctrl_c_restarting_marzban() {
    echo -e "\n\e[32mMarzban successfully restarted.\e[0m"
    main_menu
}
# Function to handle CTRL + C signal in the main menu
function ctrl_c_main_menu() {
    echo -e "\nExiting..."
    exit 0
}
# Function to properly exit the script
function exit_script() {
    # Restore the default trap before exiting
    trap - INT
    echo -e "\nGoodbye!"
    exit 0
}
function restart_marzban {
    echo -e "\e[33mRestarting Marzban...\e[0m"

    # Set a temporary trap for SIGINT (CTRL+C) within this function only
    trap 'echo -e "\n\e[32mMarzban successfully restarted.\e[0m"; return' SIGINT

    # Restart the Marzban service in the background
    marzban restart &

    MARZBAN_PID=$!  # Get the process ID of the restart command

    # Monitor the logs to detect when Marzban has started successfully
    while true; do
        # Fetch the log and check for the specific line indicating Marzban has started
        log_line=$(docker logs marzban 2>&1 | grep -m 1 "Uvicorn running on http://")

        if [[ ! -z "$log_line" ]]; then
            echo -e "\e[32mMarzban successfully restarted.\e[0m"
            break
        fi

        sleep 1
    done

    # Wait for the Marzban restart process to complete or for CTRL+C to be pressed
    wait $MARZBAN_PID

    # Reset the trap to its default behavior
    trap - SIGINT
}
function check_bot_info {
    local BOT_TOKEN
    local CHAT_ID
    while true; do
        # Get bot token and chat ID from user
        read -p "Please enter your Bot Token: " BOT_TOKEN
        read -p "Please enter your Chat ID: " CHAT_ID

        # Check if Bot Token is valid by calling getMe method
        BOT_CHECK=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getMe")
        if [[ "$BOT_CHECK" == *"true"* ]]; then
            echo -e "\e[32mBot Token is valid.\e[0m"
        else
            echo -e "\e[31mInvalid Bot Token! Please enter correct information.\e[0m"
            continue
        fi

        # Check if Chat ID is valid by sending a test message
        SEND_TEST=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/sendMessage?chat_id=$CHAT_ID&text=TestMessage")
        if [[ "$SEND_TEST" == *"\"ok\":true"* ]]; then
            echo -e "\e[32mChat ID is valid.\e[0m"
            break
        else
            echo -e "\e[31mInvalid Chat ID! Please enter correct information.\e[0m"
        fi
    done

    # Save valid bot info to config file
    echo "BOT_TOKEN=\"$BOT_TOKEN\"" > "$CONFIG_FILE"
    echo "CHAT_ID=\"$CHAT_ID\"" >> "$CONFIG_FILE"
    echo -e "\e[32mBot information saved successfully.\e[0m"
}

# Function to install the script and get Telegram info and compression method
function install_script {
    clear
    display_welcome
    
    # Display prompts for Telegram bot setup
    echo -e "\e[36mPlease enter your Telegram bot information:\e[0m"

    local valid_bot_info=false

    # Loop until valid bot info is provided
    while [ "$valid_bot_info" = false ]; do
        # Get the bot token from the user
        echo -e "\e[33mTelegram Bot Token:\e[0m \e[32m(You can get it from @BotFather)\e[0m"
        read -p "Enter your Telegram Bot Token: " BOT_TOKEN

        # Get the chat ID from the user
        echo -e "\e[33mChat ID:\e[0m \e[32m(Your Telegram chat ID)\e[0m"
        read -p "Enter your Chat ID: " CHAT_ID

        # Check if the bot token and chat ID are valid
        if check_bot_info "$BOT_TOKEN" "$CHAT_ID"; then
            echo -e "\e[32mBot Token and Chat ID are valid. Saving configuration...\e[0m"
            {
                echo "BOT_TOKEN=\"$BOT_TOKEN\""
                echo "CHAT_ID=\"$CHAT_ID\""
            } > "$CONFIG_FILE"
            valid_bot_info=true
            
            # # Send success message to bot only if the information is valid
            # curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="ArM Backuper Marzban : The bot was successfully detected" > /dev/null

            echo -e "\e[32mTelegram configuration saved successfully.\e[0m"
        else
            echo -e "\e[31mInvalid Bot Token or Chat ID! Please enter correct information.\e[0m"
        fi
    done

    # Go to the next step: Choose compression method
    choose_compression_method
}
# Function to check the validity of bot token and chat ID
function check_bot_info {
    local BOT_TOKEN="$1"
    local CHAT_ID="$2"

    # Check the validity of bot token and chat ID without sending any real message
    local response=$(curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/getUpdates")

    if echo "$response" | grep -q '"ok":true'; then
        return 0  # Valid bot info
    else
        return 1  # Invalid bot info
    fi
}

# Function to choose compression method
function choose_compression_method {
    # Display options for compression method
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

    echo -e "\e[32mCompression method saved.\e[0m"
}

# Function to check the validity of bot token and chat ID
function check_bot_info {
    local BOT_TOKEN="$1"
    local CHAT_ID="$2"

    # Check the validity of bot token and chat ID without sending any real message
    local response=$(curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/getUpdates")

    if echo "$response" | grep -q '"ok":true'; then
        return 0  # Valid bot info
    else
        return 1  # Invalid bot info
    fi
}

# Function to choose compression method
function choose_compression_method {
    # Display options for compression method
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

    echo -e "\e[32mCompression method saved.\e[0m"
}

# Function to check the validity of bot token and chat ID
function check_bot_info {
    local BOT_TOKEN="$1"
    local CHAT_ID="$2"

    # Send a test message to check if the bot token and chat ID are valid
    local response=$(curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="Checking bot info" -d disable_notification=true)
    
    if echo "$response" | grep -q '"ok":true'; then
        return 0  # Valid bot info
    else
        return 1  # Invalid bot info
    fi
}

# Function to choose compression method
function choose_compression_method {
    # Display options for compression method
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

    echo -e "\e[32mCompression method saved.\e[0m"
}

# Function to check the validity of bot token and chat ID
function check_bot_info {
    local BOT_TOKEN="$1"
    local CHAT_ID="$2"

    # Send a test message to check if the bot token and chat ID are valid
    local response=$(curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="ArM Backuper Marzban : The bot was successfully detected")
    
    if echo "$response" | grep -q '"ok":true'; then
        return 0  # Valid bot info
    else
        return 1  # Invalid bot info
    fi
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
    ARCHIVE_NAME_1="arm_DB_backup_$(date +%Y%m%d_%H%M%S).$ARCHIVE_EXT"
    ARCHIVE_NAME_2="arm_opt_backup_$(date +%Y%m%d_%H%M%S).$ARCHIVE_EXT"

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

    # Function to split files larger than 49MB
    # Function to split files larger than 49MB and send to Telegram
    function split_and_send {
        local archive_name=$1
        local part_prefix="${archive_name}_part"
        display_message "Checking size of $archive_name..." "36"

        # Check if file size is greater than 49MB
        if [ $(stat -c%s "$archive_name") -gt 51380224 ]; then
            display_message "File is larger than 49MB. Splitting the file..." "33"
            split -b 49M "$archive_name" "$part_prefix"
            
            for part in ${part_prefix}*; do
                display_message "Sending $part to Telegram..." "36"
                curl -F chat_id="$CHAT_ID" -F document=@"$part" "https://api.telegram.org/bot$BOT_TOKEN/sendDocument" > /dev/null 2>&1
                
                if [ $? -eq 0 ]; then
                    display_message "$part sent to Telegram successfully." "32"
                    rm -f "$part"
                    display_message "Deleted $part from the server." "36"
                else
                    display_message "Failed to send $part to Telegram!" "31"
                    exit 1
                fi
                
                # Add a small delay to avoid rate limiting by Telegram
                sleep 2
            done

            rm -f "$archive_name"
            display_message "Deleted the original large file $archive_name from the server." "36"
        else
            display_message "Sending $archive_name to Telegram..." "36"
            curl -F chat_id="$CHAT_ID" -F document=@"$archive_name" "https://api.telegram.org/bot$BOT_TOKEN/sendDocument" > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                display_message "$archive_name sent to Telegram successfully." "32"
                rm -f "$archive_name"
                display_message "Deleted $archive_name from the server." "36"
            else
                display_message "Failed to send $archive_name to Telegram!" "31"
                exit 1
            fi
        fi
    }

    # Send both files to Telegram (splitting if necessary)
    split_and_send "$ARCHIVE_NAME_1"
    split_and_send "$ARCHIVE_NAME_2"

    # Display final 100% progress
    echo -ne "\e[34mProgress: [\e[32m####################\e[34m] 100%\n\e[0m"
    display_message "Backup and file transfer completed successfully." "32"

    # Wait for user input before returning to the main menu
    read -p "Press any key to return to the main menu..." -n1 -s
}
# Funciton Restore
function restore {
    clear
    display_message "Starting restore process..." "36"

    # Set paths for the database and OPT files
    DIR_PATH_1="/var/lib/marzban/"
    DIR_PATH_2="/opt/marzban/"
    BACKUP_PREFIX="/root/arm_DB_backup"
    ARCHIVE_EXT="tar.gz"  # Or you can take this from user input
    RESTORE_FILE="/root/Temp_Restore/arm_DB_restore.$ARCHIVE_EXT"

    # Create temporary directory for reassembling
    TEMP_DIR="/root/Temp_Restore"
    mkdir -p "$TEMP_DIR"

    # Step 1: Check if there is a full backup file or split parts
    display_message "Checking for full backup, split parts, or multiple parts..." "33"

    # First check if we have split parts (files ending with _partxx)
    if ls ${BACKUP_PREFIX}*.tar.gz_part* 1> /dev/null 2>&1; then
        display_message "Found split DB backup parts..." "33"
        
        # Combine all parts to create the full backup file
        cat ${BACKUP_PREFIX}*.tar.gz_part* > "$TEMP_DIR/combined_backup.tar.gz"
        RESTORE_FILE="$TEMP_DIR/combined_backup.tar.gz"
        
        if [ $? -eq 0 ]; then
            display_message "Successfully reassembled large DB backup into $RESTORE_FILE." "32"
            # Remove the DB backup parts after reassembling
            rm -f ${BACKUP_PREFIX}*.tar.gz_part*
            display_message "Removed large backup parts from /root directory." "32"
        else
            display_message "Error reassembling the large DB backup!" "31"
            read -p "Press any key to return to the main menu..." -n1 -s
            return
        fi

    # Check for a single full backup file (no "_part" in name)
    elif ls ${BACKUP_PREFIX}*.tar.gz 1> /dev/null 2>&1; then
        # If full backup exists (a single complete file without _partxx)
        RESTORE_FILE=$(ls ${BACKUP_PREFIX}*.tar.gz | grep -v "_part" | head -n 1)
        display_message "Found full backup file: $RESTORE_FILE" "32"
    else
        # Display error message and wait for user input before returning to main menu
        display_message "Error: No DB backup file or parts found!" "31"
        read -p "Press any key to return to the main menu..." -n1 -s
        return
    fi

    # Step 2: Delete previous contents from the target directory
    display_message "Deleting all contents in $DIR_PATH_1 before restore..." "33"
    rm -rf "$DIR_PATH_1"/*

    if [ $? -eq 0 ]; then
        display_message "Successfully deleted all contents in $DIR_PATH_1." "32"
    else
        display_message "Failed to delete contents of $DIR_PATH_1." "31"
        read -p "Press any key to return to the main menu..." -n1 -s
        return
    fi

    # Step 3: Move the reassembled backup (or single file) to the database directory
    display_message "Moving backup to $DIR_PATH_1..." "33"
    mv "$RESTORE_FILE" "$DIR_PATH_1"

    if [ $? -eq 0 ]; then
        display_message "Successfully moved backup to $DIR_PATH_1." "32"
    else
        display_message "Failed to move backup to $DIR_PATH_1!" "31"
        read -p "Press any key to return to the main menu..." -n1 -s
        return
    fi

    # Step 4: Extract the backup in the target directory
    display_message "Extracting backup in $DIR_PATH_1..." "33"
    if [[ "$RESTORE_FILE" == *.tar.gz ]]; then
        tar -xzf "$DIR_PATH_1/$(basename $RESTORE_FILE)" -C "$DIR_PATH_1"
    else
        tar -xJf "$DIR_PATH_1/$(basename $RESTORE_FILE)" -C "$DIR_PATH_1"
    fi

    if [ $? -eq 0 ]; then
        display_message "Backup extracted successfully." "32"
    else
        display_message "Failed to extract the backup!" "31"
        read -p "Press any key to return to the main menu..." -n1 -s
        return
    fi

    # Step 5: Delete the backup archive file to save space
    display_message "Deleting the backup archive..." "33"
    rm -f "$DIR_PATH_1/$(basename $RESTORE_FILE)"

    if [ $? -eq 0 ]; then
        display_message "Successfully deleted the backup archive." "32"
    else
        display_message "Failed to delete the backup archive!" "31"
        read -p "Press any key to return to the main menu..." -n1 -s
        return
    fi

    # Step 6: Restore OPT files (dynamic file detection with wildcard)
    display_message "Restoring the OPT files..." "33"

    # Use wildcard to find the correct OPT backup file
    ARCHIVE_OPT=$(ls /root/arm_opt_backup*.tar.* 2>/dev/null)

    if [ -z "$ARCHIVE_OPT" ]; then
        display_message "Error: OPT backup archive not found!" "31"
        read -p "Press any key to return to the main menu..." -n1 -s
        return
    fi

    # Extract the OPT archive to the target directory
    display_message "Extracting OPT archive: $ARCHIVE_OPT" "33"

    if [[ "$ARCHIVE_OPT" == *.tar.gz ]]; then
        tar -xzf "$ARCHIVE_OPT" -C "$DIR_PATH_2"
    elif [[ "$ARCHIVE_OPT" == *.tar.xz ]]; then
        tar -xJf "$ARCHIVE_OPT" -C "$DIR_PATH_2"
    else
        display_message "Error: Unsupported archive format!" "31"
        read -p "Press any key to return to the main menu..." -n1 -s
        return
    fi

    if [ $? -eq 0 ]; then
        display_message "Successfully restored the OPT files." "32"
        rm -f "$ARCHIVE_OPT"
    else
        display_message "Failed to restore the OPT files!" "31"
        read -p "Press any key to return to the main menu..." -n1 -s
        return
    fi

    display_message "Restore process completed successfully!" "32"
    read -p "Press any key to return to the main menu..." -n1 -s
}

# Function to edit bot info
function edit_bot_info {
    clear
    display_welcome
    echo -e "\e[36mCurrent Bot Info:\e[0m"
    
    # Load the current bot info from the config file
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        echo -e "\e[32mBot Token: $BOT_TOKEN\e[0m"
        echo -e "\e[32mChat ID: $CHAT_ID\e[0m"
    else
        echo -e "\e[31mNo bot information found!\e[0m"
    fi

    # Loop until valid bot info is provided
    while true; do
        read -p "Enter new Telegram Bot Token: " NEW_BOT_TOKEN
        read -p "Enter new Chat ID: " NEW_CHAT_ID
        
        # Call check_bot_info to validate the token and chat ID
        if check_bot_info "$NEW_BOT_TOKEN" "$NEW_CHAT_ID"; then
            echo -e "\e[32mBot Token and Chat ID are valid.\e[0m"
            break
        else
            echo -e "\e[31mInvalid Bot Token or Chat ID! Please enter correct information.\e[0m"
        fi
    done

    # Save the new valid bot info to the config file
    echo "BOT_TOKEN=\"$NEW_BOT_TOKEN\"" > "$CONFIG_FILE"
    echo "CHAT_ID=\"$NEW_CHAT_ID\"" >> "$CONFIG_FILE"
    
    echo -e "\e[32mBot info updated successfully.\e[0m"
}

# Function to edit compression method
function edit_compression_method {
    clear
    display_welcome

    # Display current compression method
    echo -e "\e[32mCurrent Compression Method:\e[0m"
    source "$METHOD_FILE"
    echo -e "\e[34mCompression Method: $COMPRESSION_METHOD\e[0m"

    # Prompt user to choose compression method
    echo -e "\e[36mWhich compression method would you like to use?\e[0m"
    echo -e "\e[33m1) gzip\e[0m"
    echo -e "\e[33m2) xz\e[0m"
    read -p $'\e[35mEnter the number for your choice (1 or 2): \e[0m' COMP_METHOD

    
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

    echo -e "\e[32mCron job removed successfully.\e[0m"
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
