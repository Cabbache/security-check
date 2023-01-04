#!/bin/bash

#TODO https://unix.stackexchange.com/questions/152294/keep-a-zenity-dialog-box-always-on-top-in-foreground

function exerr(){
	>&2 echo "$1"
	exit 1
}

function askPassword(){
	zenity --password --title "$1/$ALLOWED_FAILS"
}

function start_ticking(){
	sleep "$TIME_TO_SUBMIT"
	CMD
}

function cancel_trigger(){
	kill -s 0 "$1" 2>/dev/null || return
	kill "$1"
	wait "$1" 2>/dev/null
}

function signal_prompt(){
	PROMPT="$NOW"
}

CONF_PATH=~/.security-check/config.sh
[[ -f "$CONF_PATH" ]] || exerr "Could not find configuration file ($CONF_PATH)"

. "$CONF_PATH"
[[ -z "$PASSWORD" ]] && exerr "Bad config file"
[[ -z "$EVERY" ]] && exerr "Bad config file"
[[ -z "$TIME_TO_SUBMIT" ]] && exerr "Bad config file"
[[ -z "$ALLOWED_FAILS" ]] && exerr "Bad config file"
[[ "$(type -t CMD)" == "function" ]] || exerr "Bad config file"
echo "Loaded configuration (delay = $EVERY)"

trap signal_prompt SIGHUP

NOW="$(date +%s)"
PROMPT=$((NOW+EVERY))
while sleep 1
do
	NOW=$(date +%s)
	if [[ "$NOW" -lt "$PROMPT" ]]
	then
		continue
	fi

	start_ticking &
	TICK_PID=$!
	NUM_FAILS=0
	while [[ $NUM_FAILS -le $ALLOWED_FAILS ]] && [[ "$(askPassword $NUM_FAILS)" != "$PASSWORD" ]]
	do
		NUM_FAILS=$((NUM_FAILS+1))
	done

	if [[ $NUM_FAILS -gt $ALLOWED_FAILS ]]
	then
		CMD
		cancel_trigger "$TICK_PID"
		echo "$(date): Rejected"
	else
		cancel_trigger "$TICK_PID"
		echo "$(date): Accepted"
	fi

	NOW=$(date +%s)
	PROMPT=$((NOW+EVERY))
done
