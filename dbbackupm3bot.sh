#!/bin/bash
set -e

telegramBotToken=$(grep -o "\$botToken = '[^']*'" /var/www/html/m3botv1/baseInfo.php | cut -d"'" -f2)
telegramBotToken2=$(grep -o '\$botToken = "[^"]*"' /var/www/html/m3botv1/baseInfo.php | cut -d'"' -f2)
filepath="/var/www/html/m3botv1/baseInfo.php"
defaultChatID=$(grep -o "\$admin = [0-9]*" "$filepath" | awk '{print $3}')
# allow passing custom chat id as argument or via BACKUP_CHAT_ID env variable
chatID="${1:-${BACKUP_CHAT_ID:-$defaultChatID}}"

databaseUser=$(cat /var/www/html/m3botv1/baseInfo.php | grep '$dbUserName' | cut -d"'" -f2)
databasePassword=$(cat /var/www/html/m3botv1/baseInfo.php | grep '$dbPassword' | cut -d"'" -f2)
databaseName=$(cat /var/www/html/m3botv1/baseInfo.php | grep '$dbName' | cut -d"'" -f2)

backupDir='/tmp/db_backup'
mkdir -p "$backupDir"
backupFilename="m3bot_$(date +'%Y-%m-%d_%H-%M-%S').sql"
# use --single-transaction for faster dumps on InnoDB
mysqldump --single-transaction -u"$databaseUser" -p"$databasePassword" "$databaseName" > "$backupDir/$backupFilename"

telegramAPI="https://api.telegram.org/bot$telegramBotToken/sendDocument"
curl -F "chat_id=$chatID" -F "document=@$backupDir/$backupFilename" "$telegramAPI"
rm "$backupDir/$backupFilename"


