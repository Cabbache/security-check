#!/bin/bash

PASSWORD="change"
EVERY=43200 #Ask for password every this many seconds
TIME_TO_SUBMIT=60 #If password is not input after this many seconds, then trigger
ALLOWED_FAILS=1 #If password entered is incorrect more than this, then trigger

#Function to call if password is not entered
#This may, or may not be running in a subprocess to the script
function CMD(){
	sudo poweroff
}
