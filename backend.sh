#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
echo "Please enter DB password:"
read -s mysql_root_password


VALIDATE(){
   if [ $1 -ne 0 ]
   then
        echo -e "$2...$R FAILURE $N"
        exit 1
    else
        echo -e "$2...$G SUCCESS $N"
    fi
}

if [ $USERID -ne 0 ]
then
    echo "Please run this script with root access."
    exit 1 # manually exit if error comes.
else
    echo "You are super user."
fi

dnf module disable nodejs -y &>>$LOGFILE
VALIDATE $? "Disabling default nodejs"

dnf module enable nodejs:20 -y &>>$LOGFILE
VALIDATE $? "Enabling nodejs 20 version"

dnf install nodejs -y &>>$LOGFILE
VALIDATE $? "Install nodejs"

id expense &>>$LOGFILE
if [ $? -ne 0 ]
then 
    useradd expense &>>$LOGFILE
    VALIDATE $? "Create expense user"
else
    echo -e "expense user already exist ... $Y SKIPPING $N"
fi

mkdir -p /app &>>$LOGFILE
VALIDATE $? "create app directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOGFILE
VALIDATE $? "Download code"

cd /app

rm -rf /app/*

unzip /tmp/backend.zip &>>$LOGFILE 
VALIDATE $? "Unzip backend code"

cd /app

npm install &>>$LOGFILE
VALIDATE $? "install nodejs dependecies"

#check repo and path
cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service &>>$LOGFILE
VALIDATE $? "Copy backend service"

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "reload daemon"

systemctl start backend &>>$LOGFILE
VALIDATE $? "START BACKEND"

systemctl enable backend &>>$LOGFILE
VALIDATE $? "Enable backend"

dnf install mysql -y &>>$LOGFILE
VALIDATE $? "INSTALL MYSQL client "

mysql -h db.daws78s.site -uroot -p${mysql_root_password} < /app/schema/backend.sql &>>$LOGFILE
VALIDATE $? "Schema loading"

systemctl restart backend &>>$LOGFILE
VALIDATE $? "Restart backend"