#!/usr/bin/env bash

# if [ -z "${FLY_DB_APP}" ]
#   then
#     echo "ENV FLY_DB_APP not found, fly database app name"
#     exit 1
# fi

# fly pg create "${FLY_DB_APP}";

# You can run app launch to create database and app. 
# If a database already exists then current database can preferably be reused
function check_database_exists(){
    [[ $(fly pg list) = *$FLY_DB_APP* ]] && return
    false
}

if check_database_exists; then
    fly app launch
    fly pg attach $FLY_DB_APP --database-user $DB_USER --database-name $DB_NAME
else
    fly app launch
    # Scrap database information
fi
# dont create a new db
# TODO pass args
fly app launch;


flyctl secrets set APP_DATABASE__USERNAME=<todo> \
APP_DATABASE__PASSWORD=<todo> \
APP_DATABASE__HOST=<todo> \
APP_DATABASE__PORT=<todo> \
APP_DATABASE__DATABASE_NAME=<todo>

