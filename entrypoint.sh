#!/bin/bash

nohup greenbone-nvt-sync >/var/log/openvas/greenbone-nvt-sync &
nohup greenbone-scapdata-sync >/var/log/openvas/greenbone-scapdata-sync &
nohup greenbone-certdata-sync >/var/log/openvas/greenbone-certdata-sync &

DATAVOL=/var/lib/openvas/mgr/
OV_PASSWORD=${OV_PASSWORD:-admin}
ALLOW_HEADER_HOST=${ALLOW_HEADER_HOST:-localhost}

cat <<EOF >/etc/default/openvas-manager
LISTEN_ADDRESS="0.0.0.0"
PORT_NUMBER=9390
EOF

cat <<EOF >/etc/default/openvas-gsa
FOREGROUND=0
HTTP_ONLY=1 # To disable HTTPS
ALLOW_HEADER_HOST= $ALLOW_HEADER_HOST # To allow <host> as hostname/address part of a Host header
LISTEN_ADDRESS="0.0.0.0" # To set listening address
PORT_NUMBER=4000 # To set listening port number
#MANAGER_ADDRESS="127.0.0.1" To set manager address
#MANAGER_PORT_NUMBER=9390 # To set manager port number
#REDIRECT_PORT= # To set HTTP redirect port number
#HTTP_REDIRECT=1 # To enable http redirection:
#SSL_PRIVATE_KEY= # To set SSL private key path
#SSL_CERTIFICATE= # To set SSL certificate path
#DO_CHROOT=1 # To set chroot
#MANAGER_PORT_NUMBER=9390 # To set manager port number
#GNUTLS_PRIORITIES= # To set GNUTLS priorities string
#DH_PARAMS= # To set Diffie-Hellman parameters file path
#UNIX_SOCKET= # To set unix socket file path
#VERBOSE=1 # To set verbose
#HTTP_FRAME_OPTS= # To set HTTP frame options string
#HTTP_CSP= # To set HTTP csp header string
#HTTP_STS=1 # To set HSTS header
#HTTP_STS_MAX_AGE=31536000 # To set HSTS max-age time (seconds)
EOF

REDIS_CONF=${REDIS_CONF:-/etc/redis/redis.conf}
if [[ ${REDIS_CONF} == "/etc/redis/redis.conf" ]]; then
  cat <<EOF >/etc/redis/redis.conf
  unixsocket /var/run/redis/redis.sock
  unixsocketperm 700
  timeout 0
  databases 128
  maxclients    512
  daemonize yes
EOF
fi

redis-server ${REDIS_CONF}

echo "Testing redis status..."
X="$(redis-cli ping)"
while  [ "${X}" != "PONG" ]; do
        echo "Redis not yet ready..."
        sleep 1
        X="$(redis-cli ping)"
done
echo "Redis ready."

echo "Checking for empty volume"
[ -e "$DATAVOL/tasks.db" ] || (
  echo "Setting up user"
  /usr/sbin/openvasmd openvasmd --create-user=admin
  /usr/sbin/openvasmd --user=admin --new-password=${OV_PASSWORD}
)

echo "Restarting services"
/etc/init.d/openvas-scanner restart
/etc/init.d/openvas-manager restart
/etc/init.d/openvas-gsa restart

echo "Reloading NVTs"
openvasmd --rebuild --progress

echo "Checking setup"
./openvas-check-setup --v9

tail -F /var/log/openvas/*
