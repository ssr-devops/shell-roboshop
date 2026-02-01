#!/bin/bash

USERID=$(id -u)
LOGS_DIR="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_DIR/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

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

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>"$LOGS_FILE"
VALIDATE $? "Catalogue Download"

cd /app
VALIDATE $? "Change Directory to /app"

rm -rf /app/*
VALIDATE $? "Clean /app Directory"

unzip /tmp/catalogue.zip &>>"$LOGS_FILE"
VALIDATE $? "Catalogue Unzip"

npm install &>>"$LOGS_FILE"
VALIDATE $? "NodeJS Dependencies Install"

cp catalogue.service /etc/systemd/system/catalogue.service &>>"$LOGS_FILE"
VALIDATE $? "Catalogue SystemD File Copy"

systemctl daemon-reload &>>"$LOGS_FILE"
VALIDATE $? "SystemD Daemon Reload"

systemctl enable catalogue &>>"$LOGS_FILE"
VALIDATE $? "Catalogue Service Enable"

systemctl start catalogue &>>"$LOGS_FILE"
VALIDATE $? "Catalogue Service Start"

systemctl status catalogue &>>"$LOGS_FILE"
VALIDATE $? "Catalogue Service Status Check"

cp mongo.repo /etc/yum.repos.d/mongo.repo &>>"$LOGS_FILE"
VALIDATE $? "MongoDB Repo Setup"

dnf install mongodb-org-shell -y &>>"$LOGS_FILE"
VALIDATE $? "MongoDB Shell Install"

INDEX=$( mongosh --host mongodb.ssrdevops.online --quiet --eval 'db.getMongo().getDBNames().indexOf("catalogue")' )

if [ $INDEX -le 0 ]; then
    mongosh --host mongodb.ssrdevops.online </app/schema/catalogue.js &>>"$LOGS_FILE"
    VALIDATE $? "Catalogue Schema Load"
else
    echo -e "Catalogue DB Already Exists....$Y SKIPPING $N" | tee -a "$LOGS_FILE"
fi

systemctl restart catalogue &>>"$LOGS_FILE"
VALIDATE $? "Catalogue Service Restart"






