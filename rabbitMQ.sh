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

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>>"$LOGS_FILE"
VALIDATE $? "RabbitMQ Repo Backup"

dnf install -y rabbitmq-server &>>"$LOGS_FILE"
VALIDATE $? "RabbitMQ Installation"

systemctl enable rabbitmq-server &>>"$LOGS_FILE"
VALIDATE $? "RabbitMQ Enable Service"

systemctl start rabbitmq-server &>>"$LOGS_FILE"
VALIDATE $? "RabbitMQ Start Service"

rabbitmqctl add_user roboshop roboshop123 &>>"$LOGS_FILE"
VALIDATE $? "RabbitMQ Add User"

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>"$LOGS_FILE"
VALIDATE $? "RabbitMQ Set Permissions"
