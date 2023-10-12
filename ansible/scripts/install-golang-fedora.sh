#!/bin/bash

if ! command -v go &>/dev/null; then
    curl -OL https://go.dev/dl/go1.21.1.linux-amd64.tar.gz
    sudo tar -C /usr/local -xvf go1.21.1.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee -a ~/.profile >/dev/null
    source ~/.profile
fi
    