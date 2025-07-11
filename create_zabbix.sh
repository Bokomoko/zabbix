#!/bin/bash
# this script creates infrastructure for Zabbix in podman
# Usage: ./create_zabbix.sh
set -e
# Define variables
docker network create --subnet 172.20.0.0/16 --ip-range 172.20.240.0/20 zabbix-net
