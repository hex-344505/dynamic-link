#!/bin/bash

trap ctrl_c INT

function ctrl_c() {
        echo "Got CTRL-C, lets clean up..."
	sudo rm /etc/nginx/sites-enabled/$MY_DOMAIN.$HOST_NAME
	sudo nginx -s reload
	sudo rm /var/log/nginx/$MY_DOMAIN.$HOST_NAME
	exit 0
}


C_TIME="`date +"%b %d %R:%S"`"
HOST_NAME="`hostname -f`"

echo "Welcome, let me gather some info..."

S_STRING="`echo $SSH_CLIENT | cut -f1 -d" "` port `echo $SSH_CLIENT | cut -f2 -d" "`"
CON_PID=`sudo tail -n 300 /var/log/auth.log | grep "$S_STRING" | tail -n 1 | cut -f2 -d"[" | cut -f1 -d"]"`
CON_PID=`sudo tail -n 300 /var/log/auth.log | grep "$CON_PID" | grep "User child is on pid " | tail -n 1 | rev | cut -d" " -f1 | rev`
SSTR=`sudo tail -n 300 /var/log/auth.log | grep "$CON_PID" | grep "tcpip-forward listen" | tail -n 1 `
MY_DOMAIN=`echo $SSTR | rev | cut -d" " -f3 | rev | sed /_/s//-/`
MY_PORT=`echo $SSTR | rev | cut -d" " -f1 | rev | cut -f1 -d"."`
MY_PUTTY=`sudo tail -n 300 /var/log/auth.log | grep "$CON_PID" | grep "session_pty_req" | rev | cut -d" " -f1 | rev | tail -n 1 `
if [ "$MY_PORT" -lt "1024" ]; then
	echo "Sorry, Mario! But our princess is in another castle!"
	echo "Try to use port between 1025 and 65535"
	exit 0
fi

if [ "$MY_DOMAIN" = "localhost" ]; then 
	NEW_DOMAIN=`curl -s https://frightanic.com/goodies_content/docker-names.php | sed /_/s//-/`
        echo "You dont select name, so ill name it $NEW_DOMAIN.$HOST_NAME"
	MY_DOMAIN=$NEW_DOMAIN
fi

cat <<EOF > /tmp/$MY_DOMAIN.$HOST_NAME
map \$http_upgrade \$connection_upgrade {
        default upgrade;
        ''      close;
    }

server {
        listen 80;
        server_name $MY_DOMAIN.$HOST_NAME;
        access_log /var/log/nginx/$MY_DOMAIN.$HOST_NAME web-req;
        error_log /var/log/nginx/$MY_DOMAIN.$HOST_NAME warn;
        location / {
        proxy_pass http://127.0.0.1:$MY_PORT;
        proxy_set_header Host $MY_DOMAIN.$HOST_NAME; 
        gzip off;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
        proxy_set_header X-Forwarded-Proto https;
        }
}
EOF
	sudo mv /tmp/$MY_DOMAIN.$HOST_NAME /etc/nginx/sites-enabled/$MY_DOMAIN.$HOST_NAME
	sudo nginx -s reload
	sudo certbot --nginx -n -q --agree-tos --redirect --register-unsafely-without-email -d $MY_DOMAIN.$HOST_NAME
	echo "All done, your link is https://$MY_DOMAIN.$HOST_NAME"

echo 'Hit CTRL+C to stop tunneling'
echo 'HTTP Requests'
echo '-------------'

tail -f /var/log/nginx/$MY_DOMAIN.$HOST_NAME | write link $MY_PUTTY &

while [ "$(ps -q $CON_PID -o cmd=)" != "" ]; do 
	sleep 5; 
done
