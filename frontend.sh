#!/bin/bash

USERID=$(id -u)
LOGS_DIR="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_DIR/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$PWD
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

dnf module list nginx &>>"$LOGS_FILE"
VALIDATE $? "NGINX Module List"

#Install Nginx
dnf module disable nginx -y &>>"$LOGS_FILE"
VALIDATE $? "NGINX Module Disable"

dnf module enable nginx:1.24 -y &>>"$LOGS_FILE"
VALIDATE $? "NGINX Module Enable"

dnf install nginx -y &>>"$LOGS_FILE"
VALIDATE $? "NGINX Installation"

systemctl enable nginx &>>"$LOGS_FILE"
VALIDATE $? "NGINX Enable Service"

systemctl start nginx &>>"$LOGS_FILE"
VALIDATE $? "NGINX Start Service"

rm -rf /usr/share/nginx/html/* &>>"$LOGS_FILE"
VALIDATE $? "NGINX HTML Cleanup"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>"$LOGS_FILE"
VALIDATE $? "Frontend Download"

cd /usr/share/nginx/html
VALIDATE $? "Change Directory to NGINX HTML"

unzip /tmp/frontend.zip &>>"$LOGS_FILE"
VALIDATE $? "Frontend Unzip"

cp $SCRIPT_DIR/frontend /etc/nginx/default.d/roboshop.conf &>>"$LOGS_FILE"
VALIDATE $? "NGINX Config Update"

systemctl restart nginx &>>"$LOGS_FILE"
VALIDATE $? "NGINX Restart Service"
