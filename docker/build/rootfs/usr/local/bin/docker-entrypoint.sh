#!/bin/bash

# Start geth in the background
geth --goerli --http --http.addr 0.0.0.0 --config /etc/geth/geth.toml &>/var/log/geth.log &

# By default, assume we are running prysm if only options are given to command.
if [[ "${1}" = -* ]]; then
    set -- prysm "$@"
fi

exec $(eval "echo $@")

