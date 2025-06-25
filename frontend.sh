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

dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "Disabling nginx"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "ENabling nginx"

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "Installing nginx"

systemctl enable ngnix &>>$LOG_FILE
systemctl start nginx
VALIDATE $? "Starting nginx"

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VALIDATE $? "Removing default conent"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
VALIDATE $? "Downloading frontend"

cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "unzipping frontend"

rm -rf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "Remove default nginx conf"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "copying nginx.conf"

systemctl restart nginx
VALIDATE $? "Resatring nginx"