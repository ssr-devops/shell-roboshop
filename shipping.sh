#!/bin/bash

USERID=$(id -u)
LOGS_DIR="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_DIR/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
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

dnf install maven -y &>>"$LOGS_FILE"
VALIDATE $? "Maven Installation"

id roboshop &>>"$LOGS_FILE"
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>"$LOGS_FILE"
    VALIDATE $? "Roboshop User Creation"
else
    echo -e "Roboshop User Already Exists....$Y SKIPPING $N" | tee -a "$LOGS_FILE"
fi

mkdir -p /app 
VALIDATE $? "App Directory Creation"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>"$LOGS_FILE"
VALIDATE $? "Shipping Download"

cd /app
VALIDATE $? "Change Directory to /app"

rm -rf /app/*
VALIDATE $? "Clean /app Directory"

unzip /tmp/shipping.zip &>>"$LOGS_FILE"
VALIDATE $? "Shipping Unzip"

cd /app
VALIDATE $? "Change Directory to /app"

mvn clean package &>>"$LOGS_FILE"
VALIDATE $? "Maven Build"

mv target/shipping-1.0.jar shipping.jar &>>"$LOGS_FILE"
VALIDATE $? "Shipping Jar Move"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>>"$LOGS_FILE"
VALIDATE $? "Shipping Service File Copy"

systemctl daemon-reload &>>"$LOGS_FILE"
VALIDATE $? "SystemD Daemon Reload"

systemctl enable shipping &>>"$LOGS_FILE"
VALIDATE $? "Shipping Service Enable"

systemctl start shipping &>>"$LOGS_FILE"
VALIDATE $? "Shipping Service Start"    

dnf install mysql -y &>>"$LOGS_FILE"
VALIDATE $? "MySQL Client Installation" 

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>"$LOGS_FILE"
VALIDATE $? "Shipping DB Schema Load"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql &>>"$LOGS_FILE"
VALIDATE $? "App User Schema Load"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>"$LOGS_FILE"
VALIDATE $? "Master Data Load"

systemctl restart shipping &>>"$LOGS_FILE"
VALIDATE $? "Shipping Service Restart"

