#!/bin/bash

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
    echo ""
    $whois | grep 'Org' | grep -v ":$" | grep 'Abuse'
    echo ""
}

whois_grep() {
    local whois_info=$1
    local grep_string=$2
    
    # search whois for the given string and important info
    echo ""
    echo "$grep_string Info"
    echo "$whois_info" | grep $grep_string | grep 'Name'
    echo "$whois_info" | grep $grep_string | grep 'Email'
    echo "$whois_info" | grep $grep_string | grep 'Phone'
    echo ""
}

whois_ip() {
    whois_info=`whois $1`
    # search whois for names
    echo "WHOIS - IP - $1"
    whois_grep "$whois_info" 'OrgAbuse'
    whois_grep "$whois_info" 'OrgTech'
    whois_grep "$whois_info" 'RTech'
}

domain=""
ip=""

# check if argument is an IP address
if valid_ip $1;
then
    ip=$1
    echo "IP address: $ip"
    echo ""
    whois_ip $ip
    echo ""
    echo "Dig"
    echo ""
    dig -x $ip
    echo ""
    echo "NSLookup"
    echo ""
    nslookup $ip
    echo ""
    echo "End"
    echo ""
    exit
fi

# # check if the argument is an email
# if [[ $1 =~ ^[^@]+@[^@]+\.[^@ \.]{2,}$ ]]
# then
#     # if it is an email, extract the domain
#     domain=$(echo $1 | sed 's/^.*@//')
# fi

# # check if the domain is a valid domain
# if [[ $domain =~ ^[^@ ]+\.[^@ \.]{2,}$ ]]
# then
#     # if it is a valid domain, run the whois command
#     whois $domain
# else
#     # if it is not a valid domain, exit
#     echo "Not a valid domain"
#     exit
# fi
