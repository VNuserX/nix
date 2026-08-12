#!/bin/bash
# Secure backup script with password encryption

BACKUP_NAME="backup-dot-working"
SOURCE_DIRS=("$HOME/working/" "$HOME/scripts/" "$HOME/vault/" "$HOME/.config/rclone/rclone.conf")
#SOURCE_DIRS=("/tmp/working/")
#ARCHIVE_PASSWORD=$(openssl rand -base64 32)  # Random strong password
ARCHIVE_PASSWORD=$(cat $HOME/.backup/backup)

echo "Creating encrypted backup..."
tar czpf - "${SOURCE_DIRS[@]}" | \
gpg --batch --passphrase "$ARCHIVE_PASSWORD" \
    --symmetric --cipher-algo AES256 \
    -o "/tmp/$BACKUP_NAME.tar.gz.gpg"

rclone sync "/tmp/$BACKUP_NAME.tar.gz.gpg" google-drive:vault --progress
rm "/tmp/$BACKUP_NAME.tar.gz.gpg"

# gpg -d backup-dot-working.tar.gz.gpg|tar xzvf - -C /tmp
# echo "Password for $BACKUP_NAME.tar.gz.gpg is:"
# echo "$ARCHIVE_PASSWORD" | tee "$BACKUP_NAME.password.txt"
# gpg --armor --encrypt --recipient your@email.com "$BACKUP_NAME.password.txt"
# rm -f "$BACKUP_NAME.password.txt"
