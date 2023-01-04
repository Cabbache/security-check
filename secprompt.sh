#!/bin/bash
PID="$(systemctl show --property MainPID --value security-check)"
if [[ "$PID" -eq 0 ]]
then
	>&2 echo "Cannot get PID"
	exit 1
fi
kill -s SIGHUP "$PID"
echo "SIGHUP sent"
