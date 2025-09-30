#!/bin/sh
# entrypoint.sh

# Usage: ./entrypoint.sh udp 51820 app-wireguard 51820
#        ./entrypoint.sh tcp 5000  app-wireguard 5000

PROTO="$1"
LOCAL_PORT="$2"
REMOTE_HOST="$3"
REMOTE_PORT="$4"

if [ -z "$PROTO" ] || [ -z "$LOCAL_PORT" ] || [ -z "$REMOTE_HOST" ] || [ -z "$REMOTE_PORT" ]; then
  echo "Usage: $0 <tcp|udp> <local_port> <remote_host> <remote_port>"
  exit 1
fi

# Start socat in background to forward localhost -> remote
if [ "$PROTO" = "udp" ]; then
  socat UDP4-LISTEN:$LOCAL_PORT,fork,reuseaddr,bind=127.0.0.1 UDP4:$REMOTE_HOST:$REMOTE_PORT &
elif [ "$PROTO" = "tcp" ]; then
  socat TCP4-LISTEN:$LOCAL_PORT,fork,reuseaddr,bind=127.0.0.1 TCP4:$REMOTE_HOST:$REMOTE_PORT &
else
  echo "Unsupported protocol: $PROTO"
  exit 1
fi

echo "Forwarding $PROTO localhost:$LOCAL_PORT → $REMOTE_HOST:$REMOTE_PORT"

# Give socat time to start
sleep 1

# Start pinggy on the local port
exec pinggy $PROTO $LOCAL_PORT