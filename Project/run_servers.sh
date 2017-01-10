#!/bin/bash
# Server names
declare -a SERVERS=("Alford" "Holiday" "Welsh" "Ball" "Hamilton")
# Start Servers in background
for server in ${SERVERS[@]}; do
	echo Running $server
	python servers.py $server &
done
