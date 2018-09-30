#!/bin/bash

# Copyright (C) 2014-2017 Blackosx
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# =======================================================================================
# Helper Functions/Routines
# =======================================================================================

# ---------------------------------------------------------------------------------------
CheckAndFixBlankSavePath()
{
    if [ "$SAVE_DIR" == "" ]; then
        SAVE_DIR="$appRootPath"
        echo "*Save path - Default: Will use $SAVE_DIR" >> "$gTmpPreLogFile"
    fi
}

# ---------------------------------------------------------------------------------------
DoesSavePathExist()
{
    passedPath="$1"
    if [ -d "$passedPath" ]; then
        echo "*Save path verify: Path exists." >> "${gTmpPreLogFile}"
        return 0
    else
        echo "*Save path verify: Path does not exist." >> "${gTmpPreLogFile}"
        return 1
    fi
}

# ---------------------------------------------------------------------------------------
CheckPathIsWriteable()
{
    local passedDir="$1"

    local isWriteable=1
    touch "$passedDir"/test 2>/dev/null && rm -f "$passedDir"/test || isWriteable=0
    local reportsFolderOwner=$( ls -ld "$passedDir" | awk '{print $3}' )

    if [ ! "$DD_BOSS" == "$reportsFolderOwner" ] || [ $isWriteable -eq 0 ]; then
        echo "*Save path verify: Path is not writeable." >> "${gTmpPreLogFile}"
        return 1
    else
        echo "*Save path verify: Path is writeable." >> "${gTmpPreLogFile}"
        return 0
    fi
}

# ---------------------------------------------------------------------------------------
LoadPreviousSettingsFromUserPrefs()
{

    local prevOptions

    # Check for preferences file
    if [ -f "$gUserPrefsFile".plist ]; then

        oIFS="$IFS"; IFS=$'\n'
        local readVar=( $( defaults read "$gUserPrefsFile" 2>/dev/null ) )
        IFS="$oIFS"

        # get total count of lines, less one for zero based index.
        local count=(${#readVar[@]}-1)

        # Check first line and last line of prefs file actually is an open and closing curly brace.
        if [[ "${readVar[0]}" == "{" ]] && [[ "${readVar[$count]}" == "}" ]]; then

            echo "*Reading ${gUserPrefsFile}.plist" >> "$gTmpPreLogFile"

            # Ignore first and last elements as they will be an opening and closing brace.
            for (( x=1; x<$count; x++ ))
            do

                # separate items
                local tmpOption="${readVar[$x]%=*}"
                local tmpValue="${readVar[$x]#*=}"

                # Remove whitespace
                tmpOption="${tmpOption//[[:space:]]}"

                # Check for save directory.
                if [ "$tmpOption" == "SaveDirectory" ]; then

                    # Remove quotes and semicolon from the returned string
                    tmpValue=$( echo "$tmpValue" | tr -d '";' )

                    # Remove any leading white space
                    tmpValue=$( echo "${tmpValue#* }" )

                    # Escape any spaces - but not for El Capitan
                    osVer=$( uname -r )
                    osVer="${osVer%%.*}"
                    if [ $osVer -lt 15 ]; then
                        tmpValue=$( echo "$tmpValue" | sed 's/ /\\ /g' )
                    fi
                    SAVE_DIR="$tmpValue"
                    echo "*Found save path $SAVE_DIR" >> "$gTmpPreLogFile"

                else

                    # Remove whitespace
                    tmpValue="${tmpValue//[[:space:]]}"

                fi

                # If true AND the app was initiated from the Finder (not command line) then set options for loading.
                if [ "$tmpValue" == "True;" ]; then

                    prevOptions="${prevOptions}${tmpOption},"
                    echo "*Found previous option: $tmpOption" >> "$gTmpPreLogFile"

                fi

            done
            
            if [ "$prevOptions" != "" ]; then

              # remove trailing comma
              prevOptions="${prevOptions%?}"

              if [ $COMMANDLINE -eq 0 ]; then
                SendToUI "@UserLastOptions@${prevOptions}@"
              else
                gPrevUserChoices="$prevOptions"
              fi

            fi

        else
            echo "*$gUserPrefsFile does not contain opening and closing curly braces." >> "$gTmpPreLogFile"
        fi

    else

        echo "*$gUserPrefsFile not found." >> "$gTmpPreLogFile"
        SendToUI "@UserLastOptions@@"

    fi
}

# ---------------------------------------------------------------------------------------
CheckSymLink()
{
    if [ -L /usr/local/bin/darwindumper ]; then

        local checkSymLink=$( readlink -n /usr/local/bin/darwindumper )

        if [ ! "$checkSymLink" == "$SELF_PATH" ]; then

            # Existing symlink doesn't match this. Give the user the option to update?
            echo "*Symlink check: Symlink exists, but does not point to this version of the app." >> "$gTmpPreLogFile"

            # write status to temp file for UI to use.
            SendToUI "@Symlink@Update@"

        else

            echo "*Symlink check: Symlink exists and is correct." >> "$gTmpPreLogFile"
            SendToUI "@Symlink@Okay@"

        fi

    else

        # No symlink exists. Give the user the option to create one?
        echo "*Symlink check: Symlink has not been created." >> "$gTmpPreLogFile"

        # write status to temp file for UI to use.
        SendToUI "@Symlink@Create@"

    fi
}

# ---------------------------------------------------------------------------------------
ClearAuthMessage()
{
    SendToUI "@ClearAuth@@"
}

# ---------------------------------------------------------------------------------------
ClearSaveDirectory()
{
    # delete save path from prefs
    defaults delete "$gUserPrefsFile" SaveDirectory

    SAVE_DIR=""
}

# ---------------------------------------------------------------------------------------
OpenSaveDirectory()
{
    if [ -d "$SAVE_DIR" ]; then
        open "$SAVE_DIR"
    fi
}

# ---------------------------------------------------------------------------------------
UIReturnSymlink()
{
    local uiReturn="$1"

    # remove everything up until, and including, the last colon
    uiReturn="${uiReturn##*@}"

    if [[ $uiReturn == *Symlink ]]; then # NOTE: uiReturn can be either "Create Symlink", "Update Symlink" or "Delete Symlink"

      /usr/bin/osascript -e "do shell script \"$SUDOCHANGES \" & \"@Symlink\" & \"@$SELF_PATH\" & \"@$uiReturn\" with administrator privileges"

      # Get the status of the app symlink
      CheckSymLink

      ClearAuthMessage

    fi
}

# ---------------------------------------------------------------------------------------
WritePrefsToFile()
{

    WriteSavePath()
    {
        [[ -f "$gUserPrefsFile" ]] && defaults delete "$gUserPrefsFile" "SaveDirectory"

        if [[ "$SAVE_DIR" == *\(* ]] || [[ "$SAVE_DIR" == *\)* ]]; then
            defaults write "$gUserPrefsFile" SaveDirectory "'$SAVE_DIR'"
        else
            defaults write "$gUserPrefsFile" SaveDirectory "$SAVE_DIR"
        fi
    }

    if [ "$1" != "SaveDir" ]; then

        # Delete existing prefs file
        [[ -f "$gUserPrefsFile".plist ]] && defaults delete "$gUserPrefsFile"

        # Read the passed commands.
        oIFS="$IFS"; IFS=$','
        uiReturnArray=($(echo "$1"))
        IFS="$oIFS"

        # Loop through each option
        for (( x=0; x<${#uiReturnArray[@]}; x++ ))
        do

            # Remove unwanted characters and parse results.
            case "${uiReturnArray[$x]##*@}" in
                "privacy")                 defaults write "$gUserPrefsFile" privacy True ;;
                "Report")                  defaults write "$gUserPrefsFile" Report True ;;
                "ArchiveZip")              defaults write "$gUserPrefsFile" ArchiveZip True ;;
                "ArchiveLzma")             defaults write "$gUserPrefsFile" ArchiveLzma True ;;
                "ArchiveNone")             defaults write "$gUserPrefsFile" ArchiveNone True ;;
                "acpi")                    defaults write "$gUserPrefsFile" acpi True ;;
                "acpiFromMem")             defaults write "$gUserPrefsFile" acpiFromMem True ;;
                "codecid")                 defaults write "$gUserPrefsFile" codecid True ;;
                "cpuinfo")                 defaults write "$gUserPrefsFile" cpuinfo True ;;
                "biosSystem")              defaults write "$gUserPrefsFile" biosSystem True ;;
                "biosVideo")               defaults write "$gUserPrefsFile" biosVideo True ;;
                "devprop")                 defaults write "$gUserPrefsFile" devprop True ;;
                "diskLoaderConfigs")       defaults write "$gUserPrefsFile" diskLoaderConfigs True ;;
                "bootLoaderBootSectors")   defaults write "$gUserPrefsFile" bootLoaderBootSectors True ;;
                "diskPartitionInfo")       defaults write "$gUserPrefsFile" diskPartitionInfo True ;;
                "dmi")                     defaults write "$gUserPrefsFile" dmi True ;;
                "edid")                    defaults write "$gUserPrefsFile" edid True ;;
                "bootlogF")                defaults write "$gUserPrefsFile" bootlogF True ;;
                "bootlogK")                defaults write "$gUserPrefsFile" bootlogK True ;;
                "firmmemmap")              defaults write "$gUserPrefsFile" firmmemmap True ;;
                "memory")                  defaults write "$gUserPrefsFile" memory True ;;
                "ioreg")                   defaults write "$gUserPrefsFile" ioreg True ;;
                "kernelinfo")              defaults write "$gUserPrefsFile" kernelinfo True ;;
                "kexts")                   defaults write "$gUserPrefsFile" kexts True ;;
                "lspci")                   defaults write "$gUserPrefsFile" lspci True ;;
                "rcscripts")               defaults write "$gUserPrefsFile" rcscripts True ;;
                "nvram")                   defaults write "$gUserPrefsFile" nvram True ;;
                "opencl")                  defaults write "$gUserPrefsFile" opencl True ;;
                "power")                   defaults write "$gUserPrefsFile" power True ;;
                "rtc")                     defaults write "$gUserPrefsFile" rtc True ;;
                "sip")                     defaults write "$gUserPrefsFile" sip True ;;
                "smc")                     defaults write "$gUserPrefsFile" smc True ;;
                "sysprof")                 defaults write "$gUserPrefsFile" sysprof True ;;
                "noshow")                  defaults write "$gUserPrefsFile" noshow True ;;
            esac
        done
      
        WriteSavePath
    
    else

        # DD_SaveDirectorySet
        WriteSavePath
        
    fi

    # Set the ownership & permissions so it's readable.
    # This covers the case where creating the file as root.
    setPrefsOwnPerms
}

# ---------------------------------------------------------------------------------------
UIReturnRunRequest()
{
    local passedCommands="$1"

    if [ $gFaceless -eq 0 ]; then
        WritePrefsToFile "$passedCommands"
    fi

    # Discover if user chose to run as root or not.
    local discoverRoot="${passedCommands##*=}"
    discoverRoot="${discoverRoot%%,*}"
    
    if [ $discoverRoot -eq 1 ]; then

        # User chose to run as root.

        # Escape any spaces and double the backslashes for Applescript
        DARWINDUMPER_ESCAPED=$(printf %q "$DARWINDUMPER")
        SAVE_DIR_ESCAPED=$(printf %q "$SAVE_DIR")
        DARWINDUMPER_ESCAPED=$( echo "$DARWINDUMPER_ESCAPED" | sed 's/\\/\\\\/g' )
        SAVE_DIR_ESCAPED=$( echo "$SAVE_DIR_ESCAPED" | sed 's/\\/\\\\/g' )

        # Launch through Applescript
        /usr/bin/osascript -e "do shell script \"$DARWINDUMPER_ESCAPED \" & \"$passedCommands\" & \"±$SAVE_DIR_ESCAPED\" with administrator privileges"

    elif [ $discoverRoot -eq 0 ]; then

        # User chose to run without root privileges.
        "$DARWINDUMPER" "$passedCommands" "±$SAVE_DIR"
        runOrQuit=1

    fi

    return $runOrQuit
}

# ---------------------------------------------------------------------------------------
setPrefsOwnPerms()
{
    if [ -f "$gUserPrefsFile".plist ]; then
        chmod 755 "$gUserPrefsFile".plist
        chown "$DD_BOSS":"$DD_BOSSGROUP" "$gUserPrefsFile".plist
    fi
}

# ---------------------------------------------------------------------------------------
runDarwinDumperScript()
{
    local passedCommands="$1"

    UIReturnRunRequest "$passedCommands"
    runOrQuit=$? # Will initiate exit of main loop.
}

# ---------------------------------------------------------------------------------------
runCommandLine()
{
    local passedUser="$1"
    local passedCommands="$2"

    CheckAndFixBlankSavePath

    echo "Save path: $SAVE_DIR"

    DoesSavePathExist "$SAVE_DIR"
    local pathExist=$? # 1 = no / 0 = yes
    
    if [ ${pathExist} = 1 ]; then

        echo "--------------------------------------------------------------------"
        echo "*Save path: Error - Save path does not exist." >> "${gTmpPreLogFile}"
        echo "Custom save path from user prefs does not exist, setting to default"
        SAVE_DIR=""
        CheckAndFixBlankSavePath
        echo "Save path is now: $SAVE_DIR"
        echo "--------------------------------------------------------------------"

    fi

    CheckPathIsWriteable "$SAVE_DIR"
    local WriteablePath=$? # 1 = no / 0 = yes

    # If path is writable but DarwinDumperReports directory does not exist,
    # then create report directory. Only run if successful.
    if [ ${WriteablePath} = 0 ]; then

        runDarwinDumperScriptCL "$passedUser" "$passedCommands"

    else

        echo "----------------------------------------------------------------------------"
        echo "Save path is not writeable."
        echo "----------------------------------------------------------------------------"
        exit 1

    fi

}

# ---------------------------------------------------------------------------------------
runDarwinDumperScriptCL()
{
    local passedUser="$1"
    local passedCommands="$2"

    if [ $gFaceless -eq 0 ]; then
        WritePrefsToFile "$passedCommands"
    fi

    if [ "$passedUser" == "" ]; then

        # Run main script - without root privileges.
        "$DARWINDUMPER" "$passedCommands" "±$SAVE_DIR"

    elif [ "$passedUser" == "r" ]; then

        # Run main script - with root privileges.
        sudo "$DARWINDUMPER" "$passedCommands" "±$SAVE_DIR"

    fi
}

# ---------------------------------------------------------------------------------------
RemoveFile()
{
    if [ -f "$1" ]; then
        rm "$1"
    fi
}

# ---------------------------------------------------------------------------------------
ClearTopOfMessageLog()
{
    # removes the first line of the log file.
    local log=$(tail -n +2 "$1"); > "$1" && if [ "$log" != "" ]; then echo "$log" > "$1"; fi
}

# =======================================================================================
# After Initialisation Routines
# =======================================================================================

# ---------------------------------------------------------------------------------------
CleanUp()
{
    [[ DEBUG -eq 1 ]] && WriteLinesToLog
    [[ DEBUG -eq 1 ]] && WriteToLog "${debugIndent}CleanUp()"

    RemoveFile "$logJsToBash"
    RemoveFile "$logFile"
    RemoveFile "$logBashToJs"

    if [ -d "${TEMPDIR}" ]; then
        rm -rf "${TEMPDIR}"
    fi
}

#===============================================================
# Main
#===============================================================

# Note: This script needs to exit when the parent app is closed.

scriptPid=$( echo "$$" )                          # Get process ID of this script
appPid=$( ps -p ${pid:-$$} -o ppid= )             # Get process ID of parent

# http://stackoverflow.com/a/697552
# get the absolute path of the executable
SELF_PATH=$(cd -P -- "$(dirname -- "$0")" && pwd -P) && SELF_PATH=$SELF_PATH/$(basename -- "$0")

# resolve symlinks
while [[ -h $SELF_PATH ]]; do
    # 1) cd to directory of the symlink
    # 2) cd to the directory of where the symlink points
    # 3) get the pwd
    # 4) append the basename
    DIR=$(dirname -- "$SELF_PATH")
    SYM=$(readlink "$SELF_PATH")
    SELF_PATH=$(cd "$DIR" && cd "$(dirname -- "$SYM")" && pwd)/$(basename -- "$SYM")
done

source "${SELF_PATH%/*}"/shared.sh

# Globals
gSipStr=""
gLkStr=""
SAVE_DIR=""
gPrevUserChoices=""

# Find version of main app.
mainAppInfoFilePath="${SELF_PATH%Resources*}"
DD_VER=$( /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$mainAppInfoFilePath"/Info.plist  )
export DD_VER

csrStat="$TOOLS_DIR/csrstat"

# Check os version
osVer=$(CheckOsVersion)
if [ $osVer -ge 14 ]; then # Yosemite and newer

    # Check for csr-active-config hex setting
    sicHex=$( "$csrStat" | grep -o '(0x.*' | cut -c10-11 | tr [[:lower:]] [[:upper:]] )

    declare -a csrArr

	csrArr=($( "$csrStat" | grep -o '(.*' | tail -n 10 | tr -d '()' ))
	[[ "${csrArr[0]}" == "enabled" ]] && gCSR_ALLOW_APPLE_INTERNAL=1       || gCSR_ALLOW_APPLE_INTERNAL=0
	[[ "${csrArr[1]}" == "enabled" ]] && gCSR_ALLOW_UNTRUSTED_KEXTS=0      || gCSR_ALLOW_UNTRUSTED_KEXTS=1
	[[ "${csrArr[2]}" == "enabled" ]] && gCSR_ALLOW_TASK_FOR_PID=0         || gCSR_ALLOW_TASK_FOR_PID=1
	[[ "${csrArr[3]}" == "enabled" ]] && gCSR_ALLOW_UNRESTRICTED_FS=0      || gCSR_ALLOW_UNRESTRICTED_FS=1
	[[ "${csrArr[4]}" == "enabled" ]] && gCSR_ALLOW_KERNEL_DEBUGGER=0      || gCSR_ALLOW_KERNEL_DEBUGGER=1
	[[ "${csrArr[5]}" == "enabled" ]] && gCSR_ALLOW_UNRESTRICTED_DTRACE=0  || gCSR_ALLOW_UNRESTRICTED_DTRACE=1
	[[ "${csrArr[6]}" == "enabled" ]] && gCSR_ALLOW_UNRESTRICTED_NVRAM=0   || gCSR_ALLOW_UNRESTRICTED_NVRAM=1
	[[ "${csrArr[7]}" == "enabled" ]] && gCSR_ALLOW_DEVICE_CONFIGURATION=0 || gCSR_ALLOW_DEVICE_CONFIGURATION=1
	[[ "${csrArr[8]}" == "enabled" ]] && gCSR_ALLOW_ANY_RECOVERY_OS=0      || gCSR_ALLOW_ANY_RECOVERY_OS=1
	[[ "${csrArr[9]}" == "enabled" ]] && gCSR_ALLOW_UNAPPROVED_KEXTS=0     || gCSR_ALLOW_UNAPPROVED_KEXTS=1

    # Save info for UI to notify user of what cannot be done.
    gSipStr="${gCSR_ALLOW_UNAPPROVED_KEXTS},${gCSR_ALLOW_ANY_RECOVERY_OS},${gCSR_ALLOW_DEVICE_CONFIGURATION},${gCSR_ALLOW_UNRESTRICTED_NVRAM},${gCSR_ALLOW_UNRESTRICTED_DTRACE},${gCSR_ALLOW_APPLE_INTERNAL},${gCSR_ALLOW_KERNEL_DEBUGGER},${gCSR_ALLOW_TASK_FOR_PID},${gCSR_ALLOW_UNRESTRICTED_FS},${gCSR_ALLOW_UNTRUSTED_KEXTS}"
    export gSipStr

    sicBin=$(echo "$gSipStr" | tr -d ',')

    # Check for loaded kexts as they may be in the prelinked kernel already.
    gDrvLoadedD=0 # DirectHW.kext
    gDrvLoadedP=0 # MacPmem.kext
    gDrvLoadedR=0 # RadeonPCI.kext
    gDrvLoadedV=0 # VoodooHDA.kext
    gDrvLoadedA=0 # AppleIntelInfo

    kextstat | grep "DirectHW" &>/dev/null && gDrvLoadedD=1
    kextstat | grep "MacPmem" &>/dev/null && gDrvLoadedP=1
    kextstat | grep "RadeonPCI" &>/dev/null && gDrvLoadedR=1
    kextstat | grep "VoodooHDA" &>/dev/null && gDrvLoadedV=1
    kextstat | grep "com.pikeralpha.driver.AppleIntelInfo" &>/dev/null && gDrvLoadedA=1

    gLkStr="${gDrvLoadedD},${gDrvLoadedP},${gDrvLoadedR},${gDrvLoadedV},${gDrvLoadedA}"
    export gLkStr

else

    gCSR_ALLOW_UNTRUSTED_KEXTS=1
    gCSR_ALLOW_UNRESTRICTED_FS=1
    gCSR_ALLOW_TASK_FOR_PID=1
    gCSR_ALLOW_KERNEL_DEBUGGER=1
    gCSR_ALLOW_APPLE_INTERNAL=1
    gCSR_ALLOW_UNRESTRICTED_DTRACE=1
    gCSR_ALLOW_UNRESTRICTED_NVRAM=1
    gCSR_ALLOW_DEVICE_CONFIGURATION=1
    gCSR_ALLOW_ANY_RECOVERY_OS=1
    gCSR_ALLOW_UNAPPROVED_KEXTS=1

fi

# Was this script called from a script or the command line
identityCallerCheck=`ps -o stat= -p $$`
if [ "${identityCallerCheck:1:1}" == "+" ]; then
    # Called from command line so interpret arguments.

    # For getopts info: http://wiki.bash-hackers.org/howto/getopts_tutorial
    argumentsToPass=""
    wasDumpChosen=0

    # Check if any arguments were passed at all.
    if [ $# -ne 0 ]; then

        mkdir -p "$TEMPDIR"

        # Redirect all log file output to stdout
        COMMANDLINE=1

        # The final built app has this script located at:
        # /DarwinDumper.app/Contents/Resources/public/bash/script
        # So to find the application containing directory we have to move up 6 dirs.
        appRootPath="${SELF_PATH}"
        for (( x=1; x<=6; x++ ))
        do
            appRootPath="${appRootPath%/*}"
        done

        [[ "$appRootPath" == "" ]] && appRootPath="/"

        while getopts ":a:d:hlo:p:sv" opt; do
            case $opt in

              a) # ARCHIVES - Check the arguments
                 oIFS="$IFS"; IFS=$','
                 for o in $OPTARG
                 do
                     case "$o" in
                        "zip")              argumentsToPass="${argumentsToPass},ArchiveZip" ;;
                        "lzma")             argumentsToPass="${argumentsToPass},ArchiveLzma" ;;
                        "none")             argumentsToPass="${argumentsToPass},ArchiveNone" ;;
                             *)             echo "Invalid archive option: -$OPTARG" >&2
                                            exit 1
                                            ;;
                     esac
                 done
                 ;;

              d) # DUMPS -  Check the arguments
                 oIFS="$IFS"; IFS=$','
                 for o in $OPTARG
                 do
                     case "$o" in
                        "acpi")              argumentsToPass="${argumentsToPass},acpi"
                                             wasDumpChosen=1 ;;
                        "acpiFromMem")       argumentsToPass="${argumentsToPass},acpiFromMem"
                                             wasDumpChosen=1 ;;
                        "audio")             argumentsToPass="${argumentsToPass},codecid"
                                             wasDumpChosen=1
                                             if [ $gCSR_ALLOW_UNTRUSTED_KEXTS -eq 0 ] && [ $gDrvLoadedV -eq 0 ]
                                             then
                                                 echo "---------------------------------------------------------------"
                                                 echo "OS X System Integrity Protection is Enabled for unsigned kexts."
                                                 echo "This means the VoodooHDA.kext cannot be loaded. The dump will"
                                                 echo "still be able to gather some information but not all."
                                             fi
                                             ;;
                        "biosSystem")        if [ $gCSR_ALLOW_UNTRUSTED_KEXTS -eq 0 ] && [ $gDrvLoadedD -eq 0 ]
                                             then
                                                 echo "---------------------------------------------------------------"
                                                 echo "OS X System Integrity Protection is Enabled for unsigned kexts."
                                                 echo "This means the DirectHW.kext cannot be loaded and flashrom will"
                                                 echo "therefore not work."
                                             else
                                                 argumentsToPass="${argumentsToPass},biosSystem"
                                                 wasDumpChosen=1
                                             fi
                                             ;;
                        "biosVideo")         argumentsToPass="${argumentsToPass},biosVideo"
                                             wasDumpChosen=1
                                             if [ $gCSR_ALLOW_UNTRUSTED_KEXTS -eq 0 ] && [ $gDrvLoadedR -eq 0 ]
                                             then
                                                 echo "---------------------------------------------------------------"
                                                 echo "OS X System Integrity Protection is Enabled for unsigned kexts."
                                                 echo "This means the RadeonPCI.kext cannot be loaded. The dump will"
                                                 echo "still be able to gather some information but not all."
                                             fi
                                             ;;
                        "bootlogF")          argumentsToPass="${argumentsToPass},bootlogF"
                                             wasDumpChosen=1 ;;
                        "bootlogK")          argumentsToPass="${argumentsToPass},bootlogK"
                                             wasDumpChosen=1 ;;
                        "cpuinfo")           argumentsToPass="${argumentsToPass},cpuinfo"
                                             wasDumpChosen=1 
                                             if [ $gCSR_ALLOW_UNTRUSTED_KEXTS -eq 0 ] && [ $gDrvLoadedA -eq 0 ]
                                             then
                                                 echo "---------------------------------------------------------------"
                                                 echo "OS X System Integrity Protection is Enabled for unsigned kexts."
                                                 echo "This means the AppleIntelInfo.kext cannot be loaded. The dump will"
                                                 echo "still be able to gather some information but not all."
                                             fi
                                             ;;
                        "devprop")           argumentsToPass="${argumentsToPass},devprop"
                                             wasDumpChosen=1 ;;
                        "diskLoaderConfigs") argumentsToPass="${argumentsToPass},diskLoaderConfigs"
                                             wasDumpChosen=1 ;;
                        "bootLoaderBootSectors")   argumentsToPass="${argumentsToPass},bootLoaderBootSectors"
                                             wasDumpChosen=1 ;;
                        "diskVolumeXuid")    argumentsToPass="${argumentsToPass},diskVolumeXuid"
                                             wasDumpChosen=1 ;;
                        "diskPartitionInfo") argumentsToPass="${argumentsToPass},diskPartitionInfo"
                                             wasDumpChosen=1 ;;
                        "dmi")               argumentsToPass="${argumentsToPass},dmi"
                                             wasDumpChosen=1 ;;
                        "edid")              argumentsToPass="${argumentsToPass},edid"
                                             wasDumpChosen=1 ;;
                        "firmmemmap")        if [ $gCSR_ALLOW_UNRESTRICTED_DTRACE -eq 0 ]
                                             then
                                                 echo "---------------------------------------------------------------"
                                                 echo "OS X System Integrity Protection is Enabled for dtrace."
                                                 echo "This means the firmware memory map dtrace script will fail."
                                             else
                                                 argumentsToPass="${argumentsToPass},firmmemmap"
                                                 wasDumpChosen=1
                                             fi
                                             ;;
                        "memory")            argumentsToPass="${argumentsToPass},memory"
                                             wasDumpChosen=1 ;;
                        "ioreg")             argumentsToPass="${argumentsToPass},ioreg"
                                             wasDumpChosen=1 ;;
                        "kernelinfo")        argumentsToPass="${argumentsToPass},kernelinfo"
                                             wasDumpChosen=1 ;;
                        "kexts")             argumentsToPass="${argumentsToPass},kexts"
                                             wasDumpChosen=1 ;;
                        "lspci")             if [ $gCSR_ALLOW_UNTRUSTED_KEXTS -eq 0 ] && [ $gDrvLoadedD -eq 0 ]
                                             then
                                                 echo "---------------------------------------------------------------"
                                                 echo "OS X System Integrity Protection is Enabled for unsigned kexts."
                                                 echo "This means the DirectHW.kext cannot be loaded and lspci will"
                                                 echo "therefore not work."
                                             else
                                                 argumentsToPass="${argumentsToPass},lspci"
                                                 wasDumpChosen=1
                                             fi
                                             ;;
                        "nvram")             argumentsToPass="${argumentsToPass},nvram"
                                             wasDumpChosen=1 ;;
                        "opencl")            argumentsToPass="${argumentsToPass},opencl"
                                             wasDumpChosen=1 ;;
                        "power")             argumentsToPass="${argumentsToPass},power"
                                             wasDumpChosen=1 ;;
                        "rcscripts")         argumentsToPass="${argumentsToPass},rcscripts"
                                             wasDumpChosen=1 ;;
                        "rtc")               argumentsToPass="${argumentsToPass},rtc"
                                             wasDumpChosen=1 ;;
                        "sip")               argumentsToPass="${argumentsToPass},sip"
                                             wasDumpChosen=1 ;;
                        "smc")               argumentsToPass="${argumentsToPass},smc"
                                             wasDumpChosen=1 ;;
                        "sysprof")           argumentsToPass="${argumentsToPass},sysprof"
                                             wasDumpChosen=1 ;;
                        *)                   echo "Invalid dump: -$OPTARG" >&2
                                             exit 1
                                             ;;
                     esac
                 done
                 ;;

              h) echo ""
                 echo "    -a                      Archive Options"
                 echo "                            ----------------------------------------------------"
                 echo "        zip                 Compress final dump folder using .zip"
                 echo "        lzma                Compress final dump folder using .lzma"
                 echo "        none                Do not compress the final dump folder"
                 echo ""
                 echo "    -d                      Dump Options"
                 echo "                            ----------------------------------------------------"
                 echo "        acpi                Extract ACPI tables from ioreg and decompile them."
                 echo "        acpiFromMem         Extract any valid ACPI tables from memory.*"
                 echo "        audio               Run the getcodecid tool & temporarily install"
                 echo "                            VoodooHDA.kext to run the getdump tool.*"
                 echo "        biosSystem          Run the flashrom tool to dump system BIOS to file.*"
                 echo "        biosVideo           Temporarily installs RadeonPCI.kext then runs the"
                 echo "                            RadeonDump tool to dump video bios. This option"
                 echo "                            will also decode the video bios if ATI vendor ID*"
                 echo "        bootlogF            Extracts the firmware boot log from ioreg (bdmesg)."
                 echo "        bootlogK            Saves kernel system messages from boot time."
                 echo "        cpuinfo             Get CPU info*"
                 echo "        devprop             Extract device-properties from ioreg and convert"
                 echo "                            using the gfxutil tool."
                 echo "        diskLoaderConfigs   Scan mounted volumes for bootloader configuration"
                 echo "                            files.* Note: requires root privileges to mount &"
                 echo "                            read the EFI system partition."
                 echo "        bootLoaderBootSectors     Combines diskutil list with added boot-sector / "
                 echo "                            bootloader info.* Note: requires root privileges"
                 echo "                            to mount & read the EFI system partition."
                 echo "        diskVolumeXuid      Dump all Volume UUID's and Unique Partition GUID's*"
                 echo "                            Note: requires root privileges to mount & read the"
                 echo "                            EFI system partition."
                 echo "        diskPartitionInfo   Save partition info from fdisk440 & gpt command."
                 echo "                            Scan and interpret the disk sectors to build a view"
                 echo "                            of the partition tables"
                 echo "                            Note: requires root privileges to mount & read the"
                 echo "                            EFI system partition."
                 echo "        dmi                 Runs the smbios-reader tool then decodes the info"
                 echo "                            using the dmidecode tool."
                 echo "        edid                Extracts IODisplayEDID data from ioreg, then decodes"
                 echo "                            it using the edid-decode tool."
                 echo "        firmmemmap          Runs the FirmwareMemoryMap DTrace script to show the"
                 echo "                            physical memory map from EFI.*"
                 echo "        memory              Loads MacPmem.kext driver and then proceeds to write"
                 echo "                            selected memory regions to disk.*"
                 echo "        ioreg               Extract the live Registry to text file(s) and create"
                 echo "                            IORegistry Web Viewer data structure."
                 echo "        kernelinfo          Dump CPU & Hardware info using /usr/sbin/sysctl"
                 echo "        kexts               Runs /usr/sbin/kextstat to dump the list of"
                 echo "                            currently loaded kernel extensions. Also run Pike's"
                 echo "                            lzvn tool to list prelinked kexts"
                 echo "        lspci               Temporarily installs DirectHW.kext then runs the"
                 echo "                            lspci tool to dump hardware information.*"
                 echo "        rcscripts           Saves any rc.local and rc.shutdown.local scripts."
                 echo "        nvram               Dump the contents of NVRAM."
                 echo "        opencl              Runs the oclinfo tool to print data for compliant"
                 echo "                            OpenCL devices."
                 echo "        power               Dump power related info for sleep and hibernate."     
                 echo "        rtc                 Runs the cmosDumperForOsx tool to dump the current"
                 echo "                            RTC registers."
                 echo "        sip                 Runs Pike's cststat program to kernel get SIP status."
                 echo "        smc                 Dumps all SMC keys to file using the SMC_util3 tool."
                 echo "        sysprof             Runs /usr/sbin/system_profiler to save mini (non-"
                 echo "                            sensitive contents) files (.xml and .txt)."
                 echo ""
                 echo "    -l                      Last settings (Use last options saved in user prefs)"
                 echo ""
                 echo "    -o                      Options"
                 echo "                            ----------------------------------------------------"
                 echo "        html                Build an HTML report file from dump information."
                 echo "        private             Mask sensitive data within all the dumps."
                 echo ""
                 echo "    -p                      Pre-Configured Options"
                 echo "                            ----------------------------------------------------"
                 echo "        1                   Runs every dump that does not require root"
                 echo "                            privileges, creates an HTML report & archives the"
                 echo "                            final dump folder using .zip"
                 echo "                            ** Use this option on it's own."
                 echo "        2                   Runs every dump including those that require root"
                 echo "                            privileges, creates an HTML report & archives the"
                 echo "                            final dump folder using .zip."
                 echo "                            ** Use this option on it's own."
                 echo "        3                   Same as p1 but with privacy enabled."
                 echo "        4                   Same as p2 but with privacy enabled."
                 echo ""
                 echo "    -s                      Print SIP status."
                 echo ""
                 echo "    -v                      Print the version."
                 echo ""
                 echo ""
                 echo " Note: Items marked with an * require root privileges, to either run at all or"
                 echo "       to perform completely."
                 echo ""
                 echo "Example: darwindumper -d bootLoaderBootSectors -o html -a zip -r"
                 echo "Example: darwindumper -d smc,edid"
                 echo "Example: darwindumper -d devprop,audio,bootlogF,lspci"
                 echo "Example: darwindumper -p1"
                 echo "Example: darwindumper -l"
                 echo ""
                 ;;

              l) # LAST used options - read from user prefs.
                 LoadPreviousSettingsFromUserPrefs

                 #if [ -f "$TEMPDIR"/dd_user_last_options ]; then
                 if [ "$gPrevUserChoices" != "" ]; then

                     echo "---------------------------------------------------------------"
                     echo "Processing last options: $gPrevUserChoices"

                     declare -a allDumps=(ArchiveZip acpi acpiFromMem codecid cpuinfo biosSystem biosVideo diskLoaderConfigs devprop bootLoaderBootSectors diskVolumeXuid diskPartitionInfo dmi edid bootlogF bootlogK firmmemmap memory ioreg kernelinfo kexts lspci rcscripts nvram opencl power rtc smc sysprof)
                    
                     oIFS="$IFS"
                     IFS=$',' read -r -a readOptions <<< "$gPrevUserChoices"
                     IFS="$oIFS"

                     for (( o=0; o<${#readOptions[@]}; o++ ))
                     do
                         if [ $gCSR_ALLOW_UNTRUSTED_KEXTS -eq 0 ]; then
                             if [ "${readOptions[$o]}" == "codecid" ] && [ $gDrvLoadedV -eq 0 ]; then
                                 echo "---------------------------------------------------------------"
                                 echo "OS X System Integrity Protection is Enabled for unsigned kexts."
                                 echo "This means the VoodooHDA.kext cannot be loaded. But the audio"
                                 echo "dump still be able to gather some information but not all."
                             fi
                             if [ "${readOptions[$o]}" == "biosSystem" ] && [ $gDrvLoadedD -eq 0 ]; then
                                 echo "---------------------------------------------------------------"
                                 echo "OS X System Integrity Protection is Enabled for unsigned kexts."
                                 echo "This means the DirectHW.kext cannot be loaded and flashrom will"
                                 echo "therefore not work."
                             fi
                             if [ "${readOptions[$o]}" == "biosVideo" ] && [ $gDrvLoadedR -eq 0 ]; then
                                 echo "---------------------------------------------------------------"
                                 echo "OS X System Integrity Protection is Enabled for unsigned kexts."
                                 echo "This means the RadeonPCI.kext cannot be loaded. The dump will"
                                 echo "still be able to gather some information but not all."
                             fi
                             if [ "${readOptions[$o]}" == "cpuinfo" ] && [ $gDrvLoadedA -eq 0 ]; then
                                 echo "---------------------------------------------------------------"
                                 echo "OS X System Integrity Protection is Enabled for unsigned kexts."
                                 echo "This means the AppleIntelInfo.kext cannot be loaded. The dump will"
                                 echo "still be able to gather some information but not all."
                             fi
                         fi
                         if [ $gCSR_ALLOW_UNRESTRICTED_DTRACE -eq 0 ]; then
                             if [ "${readOptions[$o]}" == "firmmemmap" ]; then
                                 echo "---------------------------------------------------------------"
                                 echo "OS X System Integrity Protection is Enabled for dtrace."
                                 echo "This means the firmware memory map dtrace script will fail."
                             fi
                         fi

                         for (( d=0; d<${#allDumps[@]}; d++ ))
                         do
                             if [ "${allDumps[$d]}" == "${readOptions[$o]}" ]; then
                                 wasDumpChosen=1
                             fi
                        done
                        argumentsToPass="$argumentsToPass,${readOptions[$o]}"
                     done
                 fi

                 if [ $wasDumpChosen -eq 0 ]; then
                     echo "Failed to read any previous dump options from prefs file."
                     echo "Please use a different option."
                     exit 1
                 fi
                 ;;

              o) # OPTIONS - Check the arguments
                 oIFS="$IFS"; IFS=$','
                 for o in $OPTARG
                 do
                     case "$o" in
                        "html")                   argumentsToPass="${argumentsToPass},Report" ;;
                        "private")                argumentsToPass="${argumentsToPass},privacy" ;;
                                *)                echo "Invalid option: -$OPTARG" >&2
                                                  exit 1
                                                  ;;
                     esac
                 done
                 ;;

              p) # PRECONFIGURED - Check the arguments
                 if [ "$OPTARG" == "1" ]; then
                     # Run all without root privileges
                     argumentsToPass=",ArchiveZip,acpi,codecid,cpuinfo,devprop,dmi,edid,bootlogF,bootlogK,ioreg,kernelinfo,kexts,rcscripts,nvram,opencl,power,rtc,sip,smc,sysprof,Report"
                     wasDumpChosen=1
                 elif [ "$OPTARG" == "2" ]; then
                    # Run as root
                     argumentsToPass=",ArchiveZip,acpi,acpiFromMem,codecid,cpuinfo,biosSystem,biosVideo,cpuinfo,diskLoaderConfigs,devprop,bootLoaderBootSectors,diskVolumeXuid,diskPartitionInfo,dmi,edid,bootlogF,bootlogK,firmmemmap,memory,ioreg,kernelinfo,kexts,lspci,rcscripts,nvram,opencl,power,rtc,sip,smc,sysprof,Report"
                     wasDumpChosen=1
                 elif [ "$OPTARG" == "3" ]; then
                     # Run all without root privileges and with privacy enabled
                     argumentsToPass=",ArchiveZip,acpi,codecid,cpuinfo,devprop,dmi,edid,bootlogF,bootlogK,ioreg,kernelinfo,kexts,rcscripts,nvram,opencl,rtc,sip,smc,sysprof,Report,privacy"
                     wasDumpChosen=1
                 elif [ "$OPTARG" == "4" ]; then
                    # Run as root and with privacy enabled
                     argumentsToPass=",ArchiveZip,acpi,acpiFromMem,codecid,cpuinfo,biosSystem,biosVideo,diskLoaderConfigs,devprop,bootLoaderBootSectors,diskVolumeXuid,diskPartitionInfo,dmi,edid,bootlogF,bootlogK,firmmemmap,memory,ioreg,kernelinfo,kexts,lspci,rcscripts,nvram,opencl,power,rtc,sip,smc,sysprof,Report,privacy"
                     wasDumpChosen=1
                 fi
                 ;;
                 
              s) if [ $osVer -ge 15 ]; then # El Capitan or newer
                     echo "This OS X version supports Security Integrity Protection"
                     echo "SIP configuration: $sicBin (Internal kernel value: 0x$sicHex)"                 
                 elif [ $osVer -eq 14 ]; then # Yosemite
                     echo "SIP is not fully implemented in this version of OS X"
                     echo "SIP configuration: $sicBin (Internal kernel value: 0x$sicHex)"  
                 else
                     echo "SIP is not used in this version of OS X"
                 fi
                 exit 1
                 ;;

              v) echo "DarwinDumper v$DD_VER"
                 exit 1
                 ;;

              \?)
                 echo "Invalid option: -$OPTARG" >&2
                 exit 1
                 ;;

              :)
                 echo "Option -$OPTARG requires an argument." >&2
                 exit 1
                 ;;

            esac
        done

        if [ ! "$argumentsToPass" == "" ]; then

            # Check to see if a dump was asked for
            if [ $wasDumpChosen -eq 1 ]; then

                # Check if any dumps require root privileges
                declare -a rootDumps=(acpiFromMem codecid cpuinfo biosSystem biosVideo diskLoaderConfigs bootLoaderBootSectors diskVolumeXuid diskPartitionInfo firmmemmap memory lspci)
                rootFlag=0
                for (( r=0; r<${#rootDumps[@]}; r++ ))
                do
                    # do the arguments contain a dump requiring root privileges?
                    if test "${argumentsToPass#*${rootDumps[$r]}}" != "$argumentsToPass"; then
                        rootFlag=1
                    fi
               done

               echo "---------------------------------------------------------------"

               if [ $rootFlag -eq 1 ]; then
                    echo "Root privileges are required to complete this task."
                    argumentsToPass=":Root=1${argumentsToPass}"
                    runCommandLine "r" "$argumentsToPass"
               else
                    argumentsToPass=":Root=0${argumentsToPass}"
                    runCommandLine "" "$argumentsToPass"
               fi

            fi
        else
            exit 1
        fi
        
        CleanUp
        exit 0

    else
        # No arguments were passed
        echo "usage: [-a zip,lzma,none] [-d acpi,acpiFromMem,audio,biosSystem,biosVideo,codecid,cpuinfo,devprop,diskLoaderConfigs,bootLoaderBootSectors,diskVolumeXuid,diskPartitionInfo,dmi,edid,bootlogF,bootlogK,firmmemmap,memory,ioreg,kernelinfo,kexts,lspci,rcscripts,nvram,opencl,power,rtc,sip,smc,sysprof] [-h] [-l] [-o html,private] [-p 1,2,3,4] [-v]"
    fi

else

    SendToUI "@Debug@${DEBUG}@"  

    # Populate UI with version number    
    SendToUI "@Version@${DD_VER}@"

    # The final built app has this script located at:
    # /DarwinDumper.app/Contents/Resources/public/bash/script
    # So to find the application containing directory we have to move up 6 dirs.
    appRootPath="${SELF_PATH}"
    for (( x=1; x<=6; x++ ))
    do
        appRootPath="${appRootPath%/*}"
    done

    # Write actual app path to file also, so UI can compare paths
    # To know if a custom path is being used.
    SendToUI "@AppPath@${appRootPath}@"

    # Check prefs for previously used settings and to find if the user
    # previously set a custom directory for the DarwinDumperReports folder.
    if [ $gFaceless -eq 0 ]; then
        LoadPreviousSettingsFromUserPrefs
    fi

    if [ "$gSipStr" != "" ] && [ "$gLkStr" != "" ]; then
        SendToUI "@csrBitsAndKexts@${gSipStr}:${gLkStr}@"
    fi

    # Feedback for command line
    echo "Initialisation complete. Entering loop."

    # Remember parent process id
    parentId=$appPid

    # Provide feedback.
    echo "DarwinDumper user interface is running."
    echo "Waiting for user..."

    # If save path was populated from prefs, send to UI
    if [ "$SAVE_DIR" == "" ]; then
      CheckAndFixBlankSavePath    
    fi

    SendToUI "@SaveDirectoryPath@${SAVE_DIR}@"  

    # Check to see if symbolic link in /usr/local/bin/ has been created.
    CheckSymLink

    #===============================================================
    # Main Message Loop for responding to UI feedback
    #===============================================================
        
    # The messaging system is event driven and quite simple.
    # Run a loop for as long as the parent process ID still exists
    while [ "$appPid" == "$parentId" ];
    do
        sleep 0.25                                # Check every 1/4 second.
        logLine=$(head -n 1 "$logJsToBash")       # Read first line of log file
        
        [[ $DEBUG -eq 1 ]] && [[ "$logLine" != "" ]] && echo "+${logLine}" >> "$gTmpPreLogFile"

        #===============================================================
        # Add any possible strings below that could be sent from javascript
        #===============================================================

        if [[ "$logLine" == *DD_Run* ]]; then
            ClearTopOfMessageLog "$logJsToBash"
            commands="${logLine##*@}"
            runDarwinDumperScript "$commands"
            SendToUI "@Done@@"
        elif [[ "$logLine" == *DD_Symlink* ]]; then        
            ClearTopOfMessageLog "$logJsToBash"
            UIReturnSymlink "$logLine"
        elif [[ "$logLine" == *DD_SaveDirectoryClear* ]]; then
            ClearTopOfMessageLog "$logJsToBash"
            ClearSaveDirectory
            CheckAndFixBlankSavePath
            SendToUI "@SaveDirectoryPath@${SAVE_DIR}@"
        elif [[ "$logLine" == *DD_SaveDirectoryOpen* ]]; then
            ClearTopOfMessageLog "$logJsToBash"
            OpenSaveDirectory
        elif [[ "$logLine" == *DD_SaveDirectorySet* ]]; then
            ClearTopOfMessageLog "$logJsToBash"
            SAVE_DIR="${logLine#*@}"
            WritePrefsToFile "SaveDir"
        else
            ClearTopOfMessageLog "$logJsToBash"
        fi

        appPid=$( ps -p ${pid:-$$} -o ppid= )     # Get process ID of parent
    done

    CleanUp
    exit 0
fi
