#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/shellscript-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER

echo "script started executing at: $(date)" | tee -a $LOG_FILE

USERID=$(id -u)
if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR: please run with root user"
    exit 1
else
    echo -e "$G SUCCESS: You are root user"
fi 

#validation function used to find whether the given arguments are correctly installed or not
VALIDATE(){
    if [ $1 -eq 0 ]
    then 
        echo -e " $G  $2 is ..... Success" | tee -a $LOG_FILE
    else
        echo -e " $R  $2 is ... Failure" | tee -a $LOG_FILE
        exit 1
    fi  
}

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "DIsabling default nodejs"

dnf module enable nodejs:20 -y
VALIDATE $? "Enabling nodejs 20"

dnf install nodejs -y
VALIDATE $? "Installing nodejs:20"

id roboshop
if [ $? -ne 0 ]
then 
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating roboshop system user"
else
    echo -e "System user roboshop already created ... $Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading Catalogue"

rm -rf /app/*
cd /app
unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "unzipping Catalogue"

npm install &>>$LOG_FILE
VALIDATE $? "Installing Dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "COpying catalogue service"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable catalogue  &>>$LOG_FILE
systemctl start catalogue
VALIDATE $? "Starting Catalogue"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo 
dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Installing MongoDB Client"

STATUS=$(mongosh --host mongodb.eshwar.store --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -lt 0 ]
then
    mongosh --host mongodb.eshwar.store </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "Loading data into MongoDB"
else
    echo -e "Data is already loaded ... $Y SKIPPING $N"
fi