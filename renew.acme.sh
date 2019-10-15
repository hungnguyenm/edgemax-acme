#!/bin/sh

ACMEHOME=/config/scripts/acme

usage() {
    echo "Usage: $0 -d <mydomain.com> [-d <additionaldomain.com>] -n <dns service>" \
         "[-i set insecure flag] [-v enable acme verbose]" \
         "-t <tag> [-t <additional tag>] -k <key> [-k <additional key>]" 1>&2; exit 1;
}

kill_and_wait() {
    local pid=$1
    [ -z $pid ] && return

    kill -s INT $pid 2> /dev/null
    while kill -s SIGTERM $pid 2> /dev/null; do
        sleep 1
    done
}

log() {
    if [ -z "$2" ]
    then
        printf -- "%s %s\n" "[$(date)]" "$1"
    fi
}

INSECURE_FLAG=""
VERBOSE_FLAG=""

# first parse our options
while getopts ":hivd:n:t:k:" opt; do
    case $opt in
        d) DOMAINS+=("$OPTARG");;
        i) INSECURE_FLAG="--insecure";;
        n) DNS=$OPTARG;;
        t) TAGS+=("$OPTARG");;
        k) KEYS+=("$OPTARG");;
        v) VERBOSE_FLAG="--debug 2";;
        h | *)
          usage
          ;;
    esac
done
shift $((OPTIND -1))

# check for required parameters
if [ ${#DOMAINS[@]} -eq 0 ] || [ -z ${DNS+x} ] \
        || [ ${#TAGS[@]} -eq 0 ] || [ ${#KEYS[@]} -eq 0 ] || [ ${#TAGS[@]} -ne ${#KEYS[@]} ]; then
    usage
fi

# prepare flags for acme.sh
for val in "${DOMAINS[@]}"; do
     DOMAINARG+="-d $val "
done
DNSARG="--dns $DNS"

# prepare environment
for i in "${!TAGS[@]}"; do 
    export ${TAGS[$i]}="${KEYS[$i]}"
done

log "Stopping gui service."
if [ -e "/var/run/lighttpd.pid" ]
then
    # Yes, although we just checked for the PID, turns
    # out sometimes /var/run/lighttpd.pid is not populated
    # using "pidof" is a more reliable way (on ERX v1.10.5 at least)
    # to stop lighttpd
    kill_and_wait $(pidof lighttpd)
fi

log "Executing acme.sh."
sudo -u#1000 $ACMEHOME/acme.sh --issue $DNSARG $DOMAINARG --home $ACMEHOME \
    --keylength ec-384 --keypath /tmp/server.key --fullchainpath /tmp/full.cer \
    --log $ACMEHOME/acme.log \
    --reloadcmd /config/scripts/reload.acme.sh \
    $INSECURE_FLAG $VERBOSE_FLAG $@

log "Starting gui service."
/usr/sbin/lighttpd -f /etc/lighttpd/lighttpd.conf
