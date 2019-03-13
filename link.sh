#!/bin/bash

trap ctrl_c INT
function ctrl_c() {
        echo "Got CTRL-C, lets clean up..."
	sudo rm /etc/nginx/sites-enabled/$MY_DOMAIN.$HOST_NAME
	sudo nginx -s reload
	exit 0
}

C_TIME="`date +"%b %d %R:%S"`"
HOST_NAME="`hostname -f`"

echo "Welcome, let me gather some info..."

S_STRING="`echo $SSH_CLIENT | cut -f1 -d" "` port `echo $SSH_CLIENT | cut -f2 -d" "`"
CON_PID=`sudo tail -n 300 /var/log/auth.log | grep "$S_STRING" | cut -f2 -d"[" | cut -f1 -d"]" | tail -n 1 `
CON_PID=`sudo tail -n 300 /var/log/auth.log | grep "$CON_PID" | grep "User child is on pid " | rev | cut -d" " -f1 | rev | tail -n 1`
MY_DOMAIN=`sudo tail -n 300 /var/log/auth.log | grep "$CON_PID" | grep "tcpip-forward listen" | rev | cut -d" " -f3 | rev | tail -n 1 | sed /_/s//-/`
MY_PORT=`sudo tail -n 300 /var/log/auth.log | grep "$CON_PID" | grep "tcpip-forward listen" | rev | cut -d" " -f1 | rev | tail -n 1 | cut -f1 -d"."`
MY_PORT=`echo $MY_PORT | cut -f1 -d"."`

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
server {
	listen 80;
	server_name $MY_DOMAIN.$HOST_NAME;
	location / {
	proxy_pass http://127.0.0.1:$MY_PORT;
	gzip off;
	proxy_set_header Host $host;
	}
}
EOF
	sudo mv /tmp/$MY_DOMAIN.$HOST_NAME /etc/nginx/sites-enabled/$MY_DOMAIN.$HOST_NAME
	sudo nginx -s reload
	sudo certbot --nginx -n -q --agree-tos --redirect --register-unsafely-without-email -d $MY_DOMAIN.$HOST_NAME
	echo "All done, your link is https://$MY_DOMAIN.$HOST_NAME"

echo 'Hit CTRL+C to stop tunneling'
while [ "$(ps -q $CON_PID -o cmd=)" != "" ]; do
        sleep 5;
done
