#!/bin/bash

USERID=$(id -u)
LOGS_DIR="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_DIR/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
MONGODB_HOST=mongodb.ssrdevops.online
CATLOGUE_HOST=catalogue.ssrdevops.online


if [ "$USERID" -ne 0 ]; then
    echo -e "$R Please run as root $N" | tee -a "$LOGS_FILE"
    exit 1
fi

mkdir -p "$LOGS_DIR"

VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "$R $2 FAILURE $N" | tee -a "$LOGS_FILE"
        exit 1
    else
        echo -e "$G $2 SUCCESS $N" | tee -a "$LOGS_FILE"
    fi
}

dnf install mysql-server -y &>>"$LOGS_FILE"
VALIDATE $? "MySQL Installation"

systemctl enable mysqld &>>"$LOGS_FILE"
VALIDATE $? "MySQL Enable Service"

systemctl start mysqld &>>"$LOGS_FILE"
VALIDATE $? "MySQL Start Service"

mysql_secure_installation --set-root-pass RoboShop@1 &>>"$LOGS_FILE"
VALIDATE $? "MySQL Secure Installation"

