#! /bin/bash

TARGET=$1
WORKING_DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
RESULTS_PATH="$WORKING_DIR/results/$TARGET"
SUB_PATH="$RESULTS_PATH/subdomain"
WORDLIST_PATH="$WORKING_DIR/wordlists"
TOOLS_PATH="$WORKING_DIR/tools"
IP_PATH="$RESULTS_PATH/ip"

RED="\033[1;31m"
GREEN="\033[1;32m"
BLUE="\033[1;36m"
YELLOW="\033[1;33m"
RESET="\033[0m"

setUp() {

    echo -e "${RED}[+] Creating directories...${RESET}"
    mkdir -p $RESULTS_PATH $SUB_PATH $WORDLIST_PATH $IP_PATH $TOOLS_PATH
    echo -e "${BLUE}[*] $RESULTS_PATH${RESET}"
    echo -e "${BLUE}[*] $SUB_PATH\n${RESET}"

    # Setup wordlists
    echo -e "${GREEN}\n--==[ Downloading wordlists & other tools]==--${RESET}"
    if [ -e $WORDLIST_PATH/dns_all.txt 2>/dev/null ] && [ -e $WORDLIST_PATH/raft-large-words.txt 2>/dev/null ]; then
        echo -e "${BLUE}[!] Wordlists already downloaded...\n${RESET}"
    else
        echo -e "${RED}[+] Downloading wordlists...${RESET}"
        wget -O $WORDLIST_PATH/dns_all.txt https://gist.githubusercontent.com/jhaddix/86a06c5dc309d08580a018c66354a056/raw/96f4e51d96b2203f19f6381c8c545b278eaa0837/all.txt
        wget -O $WORDLIST_PATH/raft-large-words.txt https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/raft-large-words.txt
    fi
}

checkArgs() {
    if [[ $# -eq 0 ]]
    then
        echo -e "Usage: $0 <domain>\n"
        exit 1
    fi
}

huntForSubdomains() {
    
    #echo -e "${GREEN}\n--==[ Enumerating subdomains ]==--${RESET}"
    #runBanner "Amass"
    #/snap/bin/amass enum -d $TARGET -o $SUB_PATH/amass.txt

    runBanner "Subfinder"
    /usr/local/go/bin/subfinder -d $TARGET -t 50 $TARGET -nW --silent -o $SUB_PATH/subfinder.txt

    echo -e "${RED}\n[+] Combining subdomains...${RESET}"
    cat $SUB_PATH/*.txt | sort | awk '{print tolower($0)}' | uniq > $SUB_PATH/final-subdomains.txt
    echo -e "${BLUE}[*] Check the list of subdomains at $SUB_PATH/final-subdomains.txt${RESET}"
}

resolveIpAddresses(){
    echo -e "${GREEN}\n--==[ Resolving IP addresses ]==--${RESET}"
    runBanner "massdns"
    $TOOLS_PATH/massdns/bin/massdns -r $TOOLS_PATH/massdns/lists/resolvers.txt -q -t A -o S -w $IP_PATH/massdns.raw $SUB_PATH/final-subdomains.txt
    cat $IP_PATH/massdns.raw | grep -e ' A ' |  cut -d 'A' -f 2 | tr -d ' ' > $IP_PATH/massdns.txt
    cat $IP_PATH/*.txt | sort -V | uniq > $IP_PATH/final-ips.txt
    echo -e "${BLUE}[*] Check the list of IP addresses at $IP_PATH/final-ips.txt${RESET}"
}

runBanner(){
    name=$1
    echo -e "${RED}\n[+] Running $name...${RESET}"
}

setUp
huntForSubdomains
resolveIpAddresses