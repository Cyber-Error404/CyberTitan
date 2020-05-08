#!/bin/bash

# User Management
echo "Enter names of all authorized users press (CTRL + D) to stop"
awk -F'[/:]' '{if ($3 >= 1000 && $3 != 65534) print $1}' /etc/passwd  > users.txt # find all users on the computer
users=(`cat users.txt`) # output all users to a file named users.txt
arr=()
while IFS= read -r l; do
arr+=( "$l" )
done
printf '%s\n' "${arr[@]}" > Allowed_Users.txt # put all the authorized users into a text file
Allowed_Users=(`cat Allowed_Users.txt`)
Array3=()
for i in "${users[@]}"; do
    skip=
    for j in "${Allowed_Users[@]}"; do
        [[ $i == $j ]] && { skip=1; break; }
    done
    [[ -n $skip ]] || Array3+=("$i")
done
printf '%s\n' "${Array3[@]}" > Non_Users.txt
Non_Users=(`cat Non_Users.txt`)
for i in "${Array3[@]}"; do 
    sudo deluser $i
    done
for i in "${arr[@]}"; do 
    read -r -p "Is "+$i+"an admin? [y/N] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
    then
        adduser $i sudo
    else
        deluser $i sudo
    fi
    done

#Secure root
sudo sed -i '/^PermitRootLogin/ c\PermitRootLogin no' /etc/ssh/sshd_config
sudo passwd -l root
sudo service ssh restart

#Disable guest account
echo "allow-guest=false" >> /etc/lightdm/lightdm.conf

#Change password expiration requirements
sudo sed -i '/^PASS_MAX_DAYS/ c\PASS_MAX_DAYS   90' /etc/login.defs
sudo sed -i '/^PASS_MIN_DAYS/ c\PASS_MIN_DAYS   7'  /etc/login.defs
sudo sed -i '/^PASS_WARN_AGE/ c\PASS_WARN_AGE   14' /etc/login.defs
sudo apt-get -y install libpam-cracklib
sudo sed -i '1 s/^/auth optional pam_tally.so deny=5 unlock_time=1800 onerr=fail audit even_deny_root_account silent\n/' /etc/pam.d/common-auth
sudo sed -i '1 s/^/password requisite pam_cracklib.so minlen=8 remember=5 difok=3 dcredit=-1 ucredit=-1 lcredit=-1 ocredit=-\n/' /etc/pam.d/common-password

#Enable firewall
sudo ufw enable 

#Enable syn cookie protection
sysctl -n net.ipv4.tcp_syncookies

#Disable IPv6
echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf

#Disable IP Forwarding
echo 0 | sudo tee /proc/sys/net/ipv4/ip_forward

#Prevent IP Spoofing
echo "nospoof on" | sudo tee -a /etc/host.conf

#Delete nmap and zenmap
sudo apt-get purge nmap
sudo apt-get purge zenmap

#Delete samba
Sudo service smbd stop
Sudo service samba stop

#Check for malware
sudo apt-get -y purge hydra*
sudo apt-get -y purge john*
sudo apt-get -y purge nikto*
sudo apt-get -y purge netcat*

#Check for media files
for suffix in   mp3 mov mp4 avi mpg mpeg flac m4a flv ogg gif png jpg jpeg wav wma aac bmp img exe msi
do
  find / -name *.$suffix -type f -delete
done

#Update
sudo apt-get update
sudo apt-get upgrade
