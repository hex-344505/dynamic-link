# dynamic-link
Serveo OWN Alternative
OS Ubuntu 18.04.1 LTS
Need nginx ssh and sudo
auto clean up after Ctrl+C

Highlights

edit /etc/hostname - put there FQDN of your server

add DNS recor to your zone 
*.<server-name>   <server ip>

cat /etc/ssh/sshd_config	
.....	
LogLevel DEBUG	
.....	
Match User link	
	PermitTTY yes	
	ForceCommand /etc/ssh/link.sh	

adduser link	

cat /etc/sudoers	
....	
%link ALL=NOPASSWD:ALL	


chmod 755 /etc/ssh/link.sh	


USAGE Example	

ssh -R 4026:127.0.0.1:80 link@link.example.com		

ssh -R own-name:4026:127.0.0.1:80 link@link.example.com		



