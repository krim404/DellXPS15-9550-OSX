#!/bin/bash

# Set out other directory paths based on SELF_PATH
PUBLIC_DIR="${SELF_PATH%/*}"
PUBLIC_DIR="${PUBLIC_DIR%/*}"
ASSETS_DIR="$PUBLIC_DIR"/assets
SCRIPTS_DIR="$PUBLIC_DIR"/bash
DATA_DIR="$PUBLIC_DIR"/data
DRIVERS_DIR="$PUBLIC_DIR"/drivers
IMAGES_DIR="$PUBLIC_DIR"/images
JSSCRIPTS_DIR="$PUBLIC_DIR"/scripts
STYLESDIR="$PUBLIC_DIR"/styles
TOOLS_DIR="$PUBLIC_DIR"/Tools
WORKING_PATH="${HOME}/Library/Application Support"
APP_DIR_NAME="DarwinDumper"
TEMPDIR="/tmp/${APP_DIR_NAME}"

gUserPrefsFileName="org.tom.DarwinDumper"
gUserPrefsFile="$HOME/Library/Preferences/$gUserPrefsFileName"

# Set out file paths
logFile="${TEMPDIR}/ ${APP_DIR_NAME}Log.txt"
logJsToBash="${TEMPDIR}/jsToBash" # Note - this is created in AppDelegate.m
logBashToJs="${TEMPDIR}/bashToJs" # Note - this is created in AppDelegate.m
gTmpPreLogFile="$TEMPDIR"/tmplogfile

# Other script paths
DARWINDUMPER="${SCRIPTS_DIR}/DarwinDumper.sh"
SUDOCHANGES="${SCRIPTS_DIR}/uiSudoChangeRequests.sh"

# Web files
JQUERYMIN="${JSSCRIPTS_DIR}/jquery-3.1.0.min.js"
JQUERYUIMIN="${JSSCRIPTS_DIR}/jquery-ui.min.js"
JQUERYUISTRUCTURE="${STYLESDIR}/common/jquery-ui.structure.min.css"
JQUERYUITHEMEREPORT="${STYLESDIR}/report/jquery-ui.theme.min.css"

# Globals
debugIndent="    "
gLogIndent="          "
debugIndentTwo="${debugIndent}${debugIndent}"
gFaceless=0
COMMANDLINE=0
DEBUG=0

# Here we save the current user and group ID's and use them in the
# DarwinDumper script when setting ownership/permissions of the dump
# folder, even if the user opt to run the dumps with root privileges.
DD_BOSS=`id -unr` #export DD_BOSS=`id -unr`
DD_BOSSGROUP=`id -gnr` #export DD_BOSSGROUP=`id -gnr`

# The problem with the above is if the user has invoked sudo with root privileges
# and runs DarwinDumper then the UID will be root and the save folder will be
# created and owned by root.
# Here we check to see if the current user is root and if yes then change it
# using the environment variable $HOME.
if [ "$DD_BOSS" == "root" ]; then
    DD_BOSS=$(echo "${HOME##*/}")
    DD_BOSSGROUP=`id -g -n ${DD_BOSS}`
fi

# Common Functions
# ---------------------------------------------------------------------------------------
WriteToLog() {
    if [ $COMMANDLINE -eq 0 ]; then
        printf "${1}\n" >> "$logFile"
    else
        printf "${1}\n"
    fi
}

# ---------------------------------------------------------------------------------------
WriteLinesToLog() {
    if [ $COMMANDLINE -eq 0 ]; then
        if [ $DEBUG -eq 1 ]; then
            printf "${debugIndent}===================================\n" >> "$logFile"
        else
            printf "===================================\n" >> "$logFile"
        fi
    else
        printf "===================================\n"
    fi
}

# ---------------------------------------------------------------------------------------
SendToUI() {
    if [ $COMMANDLINE -eq 0 ]; then
        [[ DEBUG -eq 1 ]] && echo "**DBG_BASHsent:$1" >> "$logFile"
        echo "$1" >> "$logBashToJs"
    else
        echo "$1" >> "$TEMPDIR"/dd_ui_return
    fi
}

# ---------------------------------------------------------------------------------------
CheckOsVersion()
{
    local osVer=$( uname -r )
    echo ${osVer%%.*}
}

# ---------------------------------------------------------------------------------------
GetOsName()
{
    local osVer=$( uname -r )
    local osVer=${osVer%%.*}
    local osName=""

    if [ "$osVer" == "8" ]; then
	    osName="Tiger"
    elif [ "$osVer" == "9" ]; then
	    osName="Leopard"
    elif [ "$osVer" == "10" ]; then
	    osName="SnowLeopard"
    elif [ "$osVer" == "11" ]; then
	    osName="Lion"
    elif [ "$osVer" == "12" ]; then
	    osName="MountainLion"
    elif [ "$osVer" == "13" ]; then
	    osName="Mavericks"
    elif [ "$osVer" == "14" ]; then
	    osName="Yosemite"
    elif [ "$osVer" == "15" ]; then
	    osName="ElCapitan"
    elif [ "$osVer" == "16" ]; then
	    osName="Sierra"
    elif [ "$osVer" == "17" ]; then
	    osName="High Sierra"
    else
	    osName="Unknown"
    fi

    echo "$osName"  # This line acts as a return to the caller.
}
