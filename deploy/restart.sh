#!/bin/bash

#Define Directory and Port
DEPLOY_DIRECTORY=/home/deploy
NGINX_DIRECTORY=/etc/nginx/conf.d

#Function Define
function Python_Running_Config(){
  python3 -m venv venv
  source venv/bin/activate
  pip install -r requirements.txt
  nohup flask --app app run --port=$APP_PORT > nohup.out 2>&1 &
  sleep 5
}

function Nginx_Check(){
  sudo nginx -t
  if [[ $? == 0 ]]; then
    echo "Nginx Syntax Success"
  else
    echo "Nginx Syntax Error!!"
    exit 1
  fi
}

function Health_Check() {
  if [[ $(curl -s 127.0.0.1:$APP_PORT/health_check | grep -o "OK") ]];
    then
  echo "Health_Check OK"
    else
  echo "Health_Check Fail"
  exit 1
  fi
}

#Script Start
cd $DEPLOY_DIRECTORY

if [[ -n $(cat $NGINX_DIRECTORY/*) ]]; then
  echo "This is not first Deploy"
  
  #Nginx Port 확인
  CURRENT_PORT=$(cat $NGINX_DIRECTORY/cicd_*.conf | grep -E -o "127.0.0.1:[0-9]{1,5}" | cut -d ":" -f2)
  echo "CURRNET_PORT is $CURRENT_PORT"

  #Target Port 확인
  if [[ $CURRENT_PORT == "5000" ]]; then
    echo "5000 is not TARGET_PORT"
    APP_DIRECTORY=$DEPLOY_DIRECTORY/lendit2
    TARGET_PORT=5001
  else
    echo "5000 is TARGET_PORT"
    APP_DIRECTORY=$DEPLOY_DIRECTORY/lendit
    TARGET_PORT=5000
  fi

  echo "TARGET_PORT IS $TARGET_PORT and APP_DIRECTORY is $APP_DIRECTORY"

  #Python Port Kill and Status Check
  echo "Python_$CURRENT_PORT is Running and kill now"
  fuser -k $CURRENT_PORT/tcp

  if [[ $(fuser $CURRENT_PORT/tcp) ]]; then
    echo "$CURRENT_PORT is alive, Error!"
    exit 1
  else
    echo "$CURRENT_PORT is dead, Success!"
  fi

  #Copy APP
  cp source/app.py $APP_DIRECTORY

  #Pyhton Build
  APP_PORT=$TARGET_PORT
  cd $APP_DIRECTORY
  if [[ -d venv ]]; then
    source venv/bin/activate
    nohup flask --app app run --port=$APP_PORT > nohup.out 2>&1 &
    sleep 5
  else  
    Python_Running_Config #Function Use
    #Python_Target_PORT Status Check
    if [[ $(fuser $TARGET_PORT/tcp) ]]; then
      echo "Python_$TARGET_PORT is Running!"  
    else
      echo "Python_$TARGET_PORT is Not Running, Failed!"
      exit 1
    fi
  fi

  #Nginx File Copy
  echo "Nginx file Copy"
  sudo rm -f $NGINX_DIRECTORY/cicd_$CURRENT_PORT.conf
  sudo cp $DEPLOY_DIRECTORY/cicd_$TARGET_PORT.conf $NGINX_DIRECTORY/

  #Nginx Syntax_Check
  Nginx_Check #Function Use
  sudo systemctl reload nginx

  #Health_Check 
  Health_Check #Function Use

  echo "Script Finished"
  exit 0
else
  echo "This is First Deploy"
  
  #현재 포트 지정
  CURRENT_PORT=5000
  echo "CURRENT_PORT is $CURRENT_PORT"
  
  #폴더 생성 및 APP파일 복사
  mkdir lendit lendit2
  cp source/app.py $DEPLOY_DIRECTORY/lendit
  xargs -n 1 cp -v requirements.txt <<<"$DEPLOY_DIRECTORY/lendit $DEPLOY_DIRECTORY/lendit2"
  cd $DEPLOY_DIRECTORY/lendit
  
  #Python 설정
  APP_PORT=$CURRENT_PORT
  Python_Running_Config  #Function Use
  #Python_Currnet_PORT Status Check
  if [[ $(fuser $CURRENT_PORT/tcp) ]]; then
      echo "Python_$CURRENT_PORT is Running!"  
  else
      echo "Python_$CURRENT_PORT is Not Running, Failed!"
      exit 1
  fi

  #Nginx복사
  cd $DEPLOY_DIRECTORY
  sudo cp cicd_$CURRENT_PORT.conf $NGINX_DIRECTORY/
  
  #Nginx Syntax_Check
  Nginx_Check  #Function Use
  sudo systemctl start nginx
  
  #Health_Check
  Health_Check  #Function Use
  echo "Script Finished"
  exit 0
fi