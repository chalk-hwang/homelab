#!/bin/sh

set -x

tailscaled -statedir $TS_STATE_DIR -port 41650 &

sleep 10s
ps auxwwf

ip route del default
ip route add default via 10.2.0.30 dev eth0

tailscale up --auth-key=$TS_AUTHKEY --hostname=$TS_HOSTNAME $TS_EXTRA_ARGS

while [ 1 ]; do
  sleep 60
  date
done