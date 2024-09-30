function install_script {
    echo "Please enter your Telegram bot information:"
    read -p "Telegram Bot Token: " BOT_TOKEN
    read -p "Chat ID: " CHAT_ID
    echo "BOT_TOKEN=\"$BOT_TOKEN\"" > "$CONFIG_FILE"
    echo "CHAT_ID=\"$CHAT_ID\"" >> "$CONFIG_FILE"
    
    echo "Which compression method would you like to use?"
    echo "1) gzip"
    echo "2) xz"
    read -p "Enter the number for your choice (1 or 2): " COMP_METHOD
    
    case $COMP_METHOD in
        1) 
            echo "COMPRESSION_METHOD=\"1\"" > "$METHOD_FILE"
            ;;
        2)
            echo "COMPRESSION_METHOD=\"2\"" > "$METHOD_FILE"
            ;;
        *)
            echo "Invalid option! Exiting."
            exit 1
            ;;
    esac

    # Download the backup script to /usr/local/bin
    curl -o /usr/local/bin/arm_bm.sh https://raw.githubusercontent.com/arvinmroadi/ArM_Backuper_Marzban/main/backup_marzban.sh
    chmod +x /usr/local/bin/arm_bm.sh

    echo "Installation complete. You can now use the command 'arm_bm' to run the script."
    
    # Automatically run the script after installation
    /usr/local/bin/arm_bm.sh
}
