#!/bin/bash
C_TIME="`date +"%b %d %R:%S"`"
HOST_NAME="`hostname -f`"
NEW_DOMAIN=`curl -s https://frightanic.com/goodies_content/docker-names.php | sed /_/s//-/`
S_STRING="`echo $SSH_CLIENT | cut -f1 -d" "` port `echo $SSH_CLIENT | cut -f2 -d" "`"
CON_PID=`sudo tail -n 300 /var/log/auth.log | grep "$S_STRING" | cut -f2 -d"[" | cut -f1 -d"]" | tail -n 1 `
CON_PID=`sudo tail -n 300 /var/log/auth.log | grep "$CON_PID" | grep "User child is on pid " | rev | cut -d" " -f1 | rev | tail -n 1`
MY_DOMAIN=`sudo tail -n 300 /var/log/auth.log | grep "$CON_PID" | grep "tcpip-forward listen" | rev | cut -d" " -f3 | rev | tail -n 1`
MY_PORT=`sudo tail -n 300 /var/log/auth.log | grep "$CON_PID" | grep "tcpip-forward listen" | rev | cut -d" " -f1 | rev | tail -n 1`
MY_PORT=`echo $MY_PORT | cut -f1 -d"."`
EXIST=`grep -lr $MY_PORT /etc/nginx/sites-enabled/ | rev | cut -d"/" -f1 | rev | tail -n 1`

if [ "$MY_DOMAIN" = "localhost" ]; then 
	MY_DOMAIN=$NEW_DOMAIN
fi

if [ "$EXIST" = "" ] ; then
cat <<EOF > /tmp/$MY_DOMAIN.$HOST_NAME
server {
	listen 80;
	server_name $MY_DOMAIN.$HOST_NAME;
	location / {
	proxy_pass http://127.0.0.1:$MY_PORT;
	}
}
EOF
sudo mv /tmp/$MY_DOMAIN.$HOST_NAME /etc/nginx/sites-enabled/$MY_DOMAIN.$HOST_NAME
sudo nginx -s reload
sudo certbot --nginx -n -q --agree-tos --redirect --register-unsafely-without-email -d $MY_DOMAIN.$HOST_NAME
echo "Your Dynamic link is $MY_DOMAIN.$HOST_NAME"
else 
	echo "Your Domain Already registered $EXIST"
fi
env > /tmp/env
echo 'Hit CTRL+C to stop tunneling'
while :; do sleep 1; done
