#!/bin/sh

ACMEHOME=/config/scripts/acme

usage() {
    echo "Usage: $0 -d <mydomain.com> [-d <additionaldomain.com>] -n <dns service>" \
         "-t <tag> [-t <additional tag>] -k <key> [-k <additional key>]" 1>&2; exit 1;
}

kill_and_wait() {
    local pid=$1
    [ -z $pid ] && return

    kill -s INT $pid 2> /dev/null
    while kill -s 0 $pid 2> /dev/null; do
        sleep 1
    done
}

log() {
    if [ -z "$2" ]
    then
        printf -- "%s %s\n" "[$(date)]" "$1"
    fi
}

# first parse our options
while getopts "hd:n:ht:hk:" opt; do
    case $opt in
        d) DOMAINS+=("$OPTARG");;
        n) DNS=$OPTARG;;
        t) TAGS+=("$OPTARG");;
        k) KEYS+=("$OPTARG");;
        *)
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
    kill_and_wait $(cat /var/run/lighttpd.pid)
fi

log "Executing acme.sh."
$ACMEHOME/acme.sh --issue $DNSARG $DOMAINARG --home $ACMEHOME \
    --keypath /tmp/server.key --fullchainpath /tmp/full.cer \
    --reloadcmd /config/scripts/reload.acme.sh

log "Starting gui service."
/usr/sbin/lighttpd -f /etc/lighttpd/lighttpd.conf
