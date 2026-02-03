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

dnf install python3 gcc python3-devel -y &>>"$LOGS_FILE"
VALIDATE $? "Python3 Installation"  

id roboshop &>>"$LOGS_FILE"
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>"$LOGS_FILE"
    VALIDATE $? "Roboshop User Creation"
else
    echo -e "Roboshop User Already Exists....$Y SKIPPING $N" | tee -a "$LOGS_FILE"
fi

mkdir -p /app 
VALIDATE $? "App Directory Creation"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>"$LOGS_FILE"
VALIDATE $? "Payment Download"

cd /app
VALIDATE $? "Change Directory to /app"

rm -rf /app/*
VALIDATE $? "Clean /app Directory"

unzip /tmp/payment.zip &>>"$LOGS_FILE"
VALIDATE $? "Payment Unzip"

cd /app
VALIDATE $? "Change Directory to /app"

pip3 install -r requirements.txt &>>"$LOGS_FILE"
VALIDATE $? "Python Dependencies Installation"

cp "$SCRIPT_DIR/payment.service" /etc/systemd/system/payment.service &>>"$LOGS_FILE"
VALIDATE $? "Payment Service Copy"

systemctl daemon-reload &>>"$LOGS_FILE"
VALIDATE $? "SystemD Daemon Reload"

systemctl enable payment &>>"$LOGS_FILE"
VALIDATE $? "Payment Enable Service"

systemctl start payment &>>"$LOGS_FILE"
VALIDATE $? "Payment Start Service"


