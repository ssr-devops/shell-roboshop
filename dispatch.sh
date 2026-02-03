#!/bin/bash

USERID=$(id -u)
LOGS_DIR="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_DIR/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$PWD
MYSQL_HOST=mysql.ssrdevops.online
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

dnf install golang -y &>>"$LOGS_FILE"
VALIDATE $? "Golang Installation"

id roboshop &>>"$LOGS_FILE"
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>"$LOGS_FILE"
    VALIDATE $? "Roboshop User Creation"
else
    echo -e "Roboshop User Already Exists....$Y SKIPPING $N" | tee -a "$LOGS_FILE"
fi

mkdir -p /app 
VALIDATE $? "App Directory Creation"

curl -L -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip &>>"$LOGS_FILE"
VALIDATE $? "Dispatch Download"

cd /app
VALIDATE $? "Change Directory to /app"

rm -rf /app/*
VALIDATE $? "Clean /app Directory"

unzip /tmp/dispatch.zip &>>"$LOGS_FILE"
VALIDATE $? "Dispatch Unzip"

cd /app
VALIDATE $? "Change Directory to /app"

go mod init dispatch &>>"$LOGS_FILE"
VALIDATE $? "Go Mod Init"

go get &>>"$LOGS_FILE"
VALIDATE $? "Go Get Dependencies"   

go build &>>"$LOGS_FILE"
VALIDATE $? "Go Build"

cp $SCRIPT_DIR/dispatch.service /etc/systemd/system/dispatch.service &>>"$LOGS_FILE"
VALIDATE $? "Dispatch Service Copy"

systemctl daemon-reload &>>"$LOGS_FILE"
VALIDATE $? "SystemD Daemon Reload"

systemctl enable dispatch &>>"$LOGS_FILE"
VALIDATE $? "Dispatch Service Enable"

systemctl start dispatch &>>"$LOGS_FILE"
VALIDATE $? "Dispatch Service Start"