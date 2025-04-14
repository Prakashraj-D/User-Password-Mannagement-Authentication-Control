#!/bin/bash

# User and SSH Key Management Script
# Ensure the script is run with superuser privileges
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

# Function to generate and add SSH keys for a user
generate_ssh_key() {
    local username=$1
    local ssh_dir="/home/$username/.ssh"
    local ssh_key="$ssh_dir/id_rsa"

    # Check if the user exists
    if ! id "$username" &>/dev/null; then
        echo "User $username does not exist."
        return 1
    fi

    # Create .ssh directory if it doesn't exist
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"

    # Generate SSH key pair
    ssh-keygen -t rsa -b 2048 -f "$ssh_key" -N "" -C "$username@$(hostname)" &>/dev/null
    if [[ $? -eq 0 ]]; then
        echo "SSH key generated for user $username."
    else
        echo "Failed to generate SSH key for user $username."
        return 1
    fi

    # Add the public key to authorized_keys
    cat "${ssh_key}.pub" >> "$ssh_dir/authorized_keys"
    chmod 600 "$ssh_dir/authorized_keys"
    chown -R "$username:$username" "$ssh_dir"

    echo "Public key added to $username's authorized_keys."
}

# Menu for user and SSH key management
while true; do
    echo "============================================="
    echo "User and SSH Key Management"
    echo "============================================="
    echo "1. Add a new user"
    echo "2. Set or change user password"
    echo "3. Generate and add SSH key for a user"
    echo "4. Lock a user account"
    echo "5. Unlock a user account"
    echo "6. Show authentication logs"
    echo "7. Exit"
    echo "============================================="
    read -p "Enter your choice (1-7): " choice

    case $choice in
        1)
            # Add a new user
            read -p "Enter the username to add: " username
            useradd "$username"
            if [[ $? -eq 0 ]]; then
                echo "User $username added successfully."
            else
                echo "Failed to add user $username."
            fi
            ;;
        2)
            # Set or change user password
            read -p "Enter the username: " username
            passwd "$username"
            ;;
        3)
            # Generate and add SSH key for a user
            read -p "Enter the username: " username
            generate_ssh_key "$username"
            ;;
        4)
            # Lock a user account
            read -p "Enter the username to lock: " username
            usermod -L "$username"
            if [[ $? -eq 0 ]]; then
                echo "User $username locked successfully."
            else
                echo "Failed to lock user $username."
            fi
            ;;
        5)
            # Unlock a user account
            read -p "Enter the username to unlock: " username
            usermod -U "$username"
            if [[ $? -eq 0 ]]; then
                echo "User $username unlocked successfully."
            else
                echo "Failed to unlock user $username."
            fi
            ;;
        6)
            # Show authentication logs
            echo "Showing authentication logs (last 10 lines):"
            tail -n 10 /var/log/secure
            ;;
        7)
            # Exit script
            echo "Exiting. Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid choice. Please try again."
            ;;
    esac
done
