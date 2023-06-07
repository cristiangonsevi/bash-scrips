#!/bin/bash

# Liberar memoria RAM
echo "Liberando memoria RAM..."
sudo sync && sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches' && sudo sh -c 'echo 1 > /proc/sys/vm/drop_caches'
sudo swapoff -a && sudo swapon -a
