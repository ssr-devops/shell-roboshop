#!/bin/bash

USERID=$(id -u)
LOGS_DIR="/var/log/shell-practice"
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

echo -e "$Y Installing MongoDB Repo $N" | tee -a "$LOGS_FILE"
cp mongo.repo /etc/yum.repos.d/mongo.repo &>>"$LOGS_FILE"
VALIDATE $? "MongoDB Repo Setup"

dnf install mongodb-org -y &>>"$LOGS_FILE"
VALIDATE $? "MongoDB Installation"

systemctl enable mongod &>>"$LOGS_FILE"
VALIDATE $? "MongoDB Enable Service"

systemctl start mongod &>>"$LOGS_FILE"
VALIDATE $? "MongoDB Start Service"

sed -i -e 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf &>>"$LOGS_FILE"
VALIDATE $? "MongoDB Config Update"

systemctl restart mongod &>>"$LOGS_FILE"
VALIDATE $? "MongoDB Restart Service"