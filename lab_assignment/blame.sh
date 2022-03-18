#!/bin/bash

DOMAIN=""
IP=""

# check if there is a first argument
if [ $# -eq 0 ]
then
    echo "Enter domain, ip, website, or email"
    exit
fi

# https://www.linuxjournal.com/content/validating-ip-address-bash-script
valid_ip() {
    local  ip=$1
    local  stat=1
    
    # Check if the IP is valid
    # first check if the IP is in the correct format with regex
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
        && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

# check if the first argument is a valid domain
find_domain_info() {
    whois=$"whois $1"
    
    # search whois for abuse contact
    echo "ABUSE CONTACT"
    $whois | grep 'Org' | grep -v ":$" | grep 'Abuse'
}

whois_grep() {
    local whois_info=$1
    local grep_string=$2
    
    # search whois for the given string and important info
    echo "$grep_string Info"
    echo "$whois_info" | grep $grep_string | grep 'Name'
    echo "$whois_info" | grep $grep_string | grep 'Email'
    echo "$whois_info" | grep $grep_string | grep 'Phone'
}

whois_echo() {
    whois_info=`whois $1`
    # search whois for names
    echo "WHOIS - $1"
    whois_grep "$whois_info" 'Abuse'
    whois_grep "$whois_info" 'Admin'
}

dig_ip() {
    dig_info=`dig -x $1`
    # search dig for names
    echo "DIG - IP - $1"
    echo "$dig_info" | awk '/ANSWER SECTION:/,/Query time: /' | sed '$d' | sed '1d'
}

dig_domain() {
    dig_info=`dig $2 $1`
    # search dig for names
    echo "DIG - DOMAIN - $1"
    echo "$dig_info" | awk '/ANSWER SECTION:/,/Query time: /' | sed '$d' | sed '1d' | head -c -1
    echo ""
    # run who is for each ip in dig_info
    echo "$dig_info" | awk '/ANSWER SECTION:/,/Query time: /' | sed '$d' | sed '1d' | head -c -1 | awk '{print $5}' | while read ip; do
        whois_echo $ip
        echo ""
    done
}

nslookup_ip() {
    nslookup_info=`nslookup $1`
    # search nslookup for names
    echo "NSLOOKUP - IP - $1"
    # show first line of nslookup output
    echo "$nslookup_info" | head -1
    # extract the nameserver info
    if echo "$nslookup_info" | grep -oP 'name = \K.*' > /dev/null; then
        echo "Name Server: $(echo "$nslookup_info" | grep -oP 'name = \K.*')"
    fi
}

nslookup_domain() {
    nslookup_info=`nslookup $1`
    # search nslookup for names
    echo "NSLOOKUP - DOMAIN - $1"
    # show first line of nslookup output
    echo "$nslookup_info" | head -1
    # extract Server: IP address from first line
    server_ip=`echo "$nslookup_info" | head -1 | grep -oP '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'`
    echo ""
    whois_echo $server_ip
}

blame_ip() {
    echo "IP address: $IP"
    echo ""
    whois_echo $IP
    echo ""
    dig_ip $IP
    nslookup_ip $IP
}

blame_domain() {
    echo "Domain: $DOMAIN"
    echo ""
    whois_echo $DOMAIN
    echo ""
    dig_domain $DOMAIN
    # nslookup_domain $DOMAIN
}

# check if argument is an IP address
if valid_ip $1;
then
    IP=$1
    blame_ip
elif [[ $1 =~ ^[a-zA-Z0-9]+\.[a-zA-Z0-9]+$ ]];
then
    DOMAIN=$1
    blame_domain $DOMAIN
    # elif check for email
elif [[ $1 =~ ^[a-zA-Z0-9]+@[a-zA-Z0-9]+\.[a-zA-Z0-9]+$ ]];
then
    echo "Email: $1"
    # extract domain from email
    DOMAIN="${1/[^@]*@/}"
    blame_domain $DOMAIN
else
    echo "Argument is not a valid IP, domain, or email"
    exit
fi