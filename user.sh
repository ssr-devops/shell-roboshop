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

dnf module disable nodejs -y &>>"$LOGS_FILE"
VALIDATE $? "NodeJS Module Disable"

dnf module enable nodejs:20 -y &>>"$LOGS_FILE"
VALIDATE $? "NodeJS Module Enable"

dnf install nodejs -y &>>"$LOGS_FILE"
VALIDATE $? "NodeJS Installation"


id roboshop &>>"$LOGS_FILE"
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>"$LOGS_FILE"
    VALIDATE $? "Roboshop User Creation"
else
    echo -e "Roboshop User Already Exists....$Y SKIPPING $N" | tee -a "$LOGS_FILE"
fi

mkdir -p /app 
VALIDATE $? "App Directory Creation"

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>"$LOGS_FILE"
VALIDATE $? "User Download"

cd /app
VALIDATE $? "Change Directory to /app"

rm -rf /app/*
VALIDATE $? "Clean /app Directory"

unzip /tmp/user.zip &>>"$LOGS_FILE"
VALIDATE $? "User Unzip"

npm install &>>"$LOGS_FILE"
VALIDATE $? "User Dependencies Install"

cp "$SCRIPT_DIR/user.service" /etc/systemd/system/user.service &>>"$LOGS_FILE"
VALIDATE $? "User Service File Copy"

systemctl daemon-reload &>>"$LOGS_FILE"
VALIDATE $? "SystemD Daemon Reload" 

systemctl enable user &>>"$LOGS_FILE"
VALIDATE $? "User Service Enable"

systemctl start user &>>"$LOGS_FILE"
VALIDATE $? "User Service Start"
