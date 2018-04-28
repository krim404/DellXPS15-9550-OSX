#!/bin/sh

# A script to read an interpret a disk's boot/partition sectors.
# Copyright (C) 2013-2017 Blackosx <darwindumper@yahoo.com>
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
# =======================================================================
#
# This script:
# 1- gathers information about the available disks, partitions,
# volumes, and bootloaders on the system. The information is then saved
# to a temporary file for later processing by the main DarwinDumper script.
#
# 2 - dumps any bootloader user config files it finds in an Extra or EFI
# folder at the same path as a found boot file.
#
# 3 - dumps the volume UUID's and GUID's to a UIDs.txt file.
#
# The idea for identifying boot sector code was taken from the original
# Chameleon package installer script where it checked for the existence of
# LILO. I'd since added further checks for the different stage0 versions
# and the windows disk signature to the later chameleon package installer
# scripts - see for example CheckDiskMicrocode.sh.
#
# It's been tested on 10.5, 10.6, 10.7 & 10.8. I'm aware of one issue
# under 10.5 where the disk size of the first disk has been shown as
# zero size but I've been unable to reproduce this behaviour.
#
# I would like to add detection for more stage 0 loaders, for example
# GRUB and anything else that people use in make the script more concise.
#
# Also note, that the current detection for existing known loaders is
# based on matching against known hex values so it relies on the code
# staying the same. If then, for example, the Chameleon boot0 code
# changes then it could affect identification.
#
# *************************************************************************************
# The script requires 4 arguments passed to it when called.
# 1 - Path    : Directory to save dumps
# 2 - 1 or 0  : Dump bootloader configuration files.
#               Creates a folder named BootloaderConfigFiles and in that, copies the
#               complete folder structure(s) leading to a pre-defined config file.
# 3 - 1 or 0  : Dump diskutil list & identify known bootloader code.
#               This option creates the following .txt files:
#               Hex dump of each disks' boot and partition sectors (1 file per disk).
#               diskutil list result.
#               /tmp/diskutilLoaderInfo.txt (an intermediary file for later processing).
# 4 - 1 or 0  : Dump disk partition table information and disk/volume UUIDs.
#               Creates a .txt file for each disk and a file named UIDs.txt
#
# Note: 1 enables the routine, 0 disables the routine.
# *************************************************************************************
#
# Thanks to STLVNUB, Slice and dmazar for extensive testing, bug fixing & suggestions
#
# ---------------------------------------------------------------------------------------
Initialise()
{
    # get the absolute path of the executable
    SELF_PATH=$(cd -P -- "$(dirname -- "$0")" && pwd -P) && SELF_PATH=$SELF_PATH/$(basename -- "$0")
    source "${SELF_PATH%/*}"/shared.sh

    # String arrays for storing diskutil info.
    declare -a duContent
    declare -a duSize
    declare -a duVolumeName
    declare -a duIdentifier
    declare -a duWholeDisks
    declare -a allDisks

    # If running this script locally then set BootSectDir,
    # otherwise get BootSectDir from passed argument.
    if [ "$1" == "" ]; then
        dumpFolderPath="${SELF_PATH}"
    else
        dumpFolderPath="$1"
    fi


    if [ "$2" == "0" ]; then
        gRunBootloaderConfigFiles=0
    else
        gRunBootloaderConfigFiles=1
        SendToUI "@DF@S:diskLoaderConfigs@"
    fi
    if [ "$3" == "0" ]; then
        gRunDiskutilAndLoaders=0
    else
        gRunDiskutilAndLoaders=1
        SendToUI "@DF@S:bootLoaderBootSectors@"
    fi
    if [ "$4" == "0" ]; then
        gRunDisks=0
    else
        gRunDisks=1
        SendToUI "@DF@S:diskPartitionInfo@"
    fi

    fdisk440="$TOOLS_DIR/fdisk440"
    bgrep="$TOOLS_DIR/bgrep"

    # Resources - Scripts
    bdisk="$SCRIPTS_DIR/bdisk.sh"
    
    gBootloadersTextBuildFile=""
    gXuidBuildFile="Device@Name@Volume UUID@Unique partition GUID"
    gXuidBuildFile="$gXuidBuildFile \n"
    gXuidBuildFile="$gXuidBuildFile"$(printf " @ @(Example Usage: Kernel flag rd=uuid boot-uuid=)@(Example Usage: Clover Hide Volume)\n")
    gXuidBuildFile="$gXuidBuildFile \n"

    gESPMountPrefix="ddTempMp"
    UefiFileMatchList="$DATA_DIR/uefi_loaders.txt"
    gUefiKnownFiles=( $( < "$UefiFileMatchList" ) )
    gRootPriv=0
    gSystemVersion=$(CheckOsVersion)    
}

# ---------------------------------------------------------------------------------------
CheckRoot()
{
    if [ "`whoami`" != "root" ]; then
        #echo "Running this requires you to be root."
        #sudo "$0"
        gRootPriv=0
    else
        gRootPriv=1
    fi
}

# ---------------------------------------------------------------------------------------
DumpDiskUtilAndLoader()
{
    local checkSystemVersion
    local activeSliceNumber
    local diskPositionInArray
    local mbrBootCode
    local pbrBootCode
    local partitionActive
    local targetFormat
    local mountPointWasCreated
    local efiMountedIsVerified
    local espWasMounted=0
    local gpt=0
    local mounted
    local byteFiveTen=""
    local diskUtilInfoDump=""
    local fileSystemPersonality=""
    local mediaName=""
    local volumeName=""
    local partitionname=""
    local diskSectorDumpFile=""
    local diskUtilLoaderInfoFile="$TEMPDIR"/diskutilLoaderInfo.txt
    local xuidFile="$gDumpFolderDisks"/UIDs.txt

    # ---------------------------------------------------------------------------------------
    ConvertUnitPreSL()
    {
        local passedNumber="$1"
        local numberLength=$( echo "${#passedNumber}")
        local convertedNumber

        if [ $numberLength -le 15 ] && [ $numberLength -ge 13 ]; then # TB
            convertedNumber=$(((((passedNumber/1024)/1024)/1024)/1024))" TB"
        elif [ $numberLength -le 12 ] && [ $numberLength -ge 10 ]; then # GB
            convertedNumber=$((((passedNumber/1024)/1024)/1024))" GB"
        elif [ $numberLength -le 9 ] && [ $numberLength -ge 7 ]; then # MB
            convertedNumber=$(((passedNumber/1024)/1024))" MB"
        elif [ $numberLength -le 6 ] && [ $numberLength -ge 4 ]; then # KB
            convertedNumber=$((passedNumber/1024))" KB"
        fi
        echo "$convertedNumber"
    }

    # ---------------------------------------------------------------------------------------
    ConvertUnit()
    {
        local passedNumber="$1"
        local numberLength=$( echo "${#passedNumber}")
        local convertedNumber

        if [ $numberLength -le 15 ] && [ $numberLength -ge 13 ]; then # TB
            convertedNumber=$((passedNumber/1000000000000))" TB"
        elif [ $numberLength -le 12 ] && [ $numberLength -ge 10 ]; then # GB
            convertedNumber=$((passedNumber/1000000000))" GB"
        elif [ $numberLength -le 9 ] && [ $numberLength -ge 7 ]; then # MB
            convertedNumber=$((passedNumber/1000000))" MB"
        elif [ $numberLength -le 6 ] && [ $numberLength -ge 4 ]; then # KB
            convertedNumber=$((passedNumber/100))" KB"
        fi
        echo "$convertedNumber"
    }

    # ---------------------------------------------------------------------------------------
    # Function to search for key in plist and return all associated strings in an array.
    # Will find multiple matches
    FindMatchInPlist()
    {
        local keyToFind="$1"
        local typeToFind="$2"
        declare -a plistToRead=("${!3}")
        local foundSection=0

        for (( n=0; n<${#plistToRead[@]}; n++ ))
        do
            [[ "${plistToRead[$n]}" == *"<key>$keyToFind</key>"* ]] && foundSection=1
            if [ $foundSection -eq 1 ]; then
                [[ "${plistToRead[$n]}" == *"</array>"* ]] || [[ "${plistToRead[$n]}" == *"</dict>"* ]] && foundSection=0
                if [[ "${plistToRead[$n]}" == *"$typeToFind"* ]]; then
                    tmp=$( echo "${plistToRead[$n]#*>}" )
                    tmp=$( echo "${tmp%<*}" )
                    tmpArray+=("$tmp")
                fi
            fi
        done
    }

    # ---------------------------------------------------------------------------------------
    # Function to search for key in plist and return all associated strings in an array.
    # Will only find a single match
    FindMatchInSlicePlist()
    {
        local keyToFind="$1"
        local typeToFind="$2"
        declare -a plistToRead=("${!3}")
        local foundSection=0

        for (( n=0; n<${#plistToRead[@]}; n++ ))
        do
            [[ "${plistToRead[$n]}" == *"<key>$keyToFind</key>"* ]] && foundSection=1
            if [ $foundSection -eq 1 ]; then
                [[ "${plistToRead[$n]}" == *"</array>"* ]] || [[ "${plistToRead[$n]}" == *"</dict>"* ]] || [[ ! "${plistToRead[$n]}" == *"<key>$keyToFind</key>"* ]] && foundSection=0
                if [[ "${plistToRead[$n]}" == *"$typeToFind"* ]]; then
                    tmp=$( echo "${plistToRead[$n]#*>}" )
                    tmp=$( echo "${tmp%<*}" )

                    if [ "$tmp" == EF57347C-0000-11AA-AA11-00306543ECAC ]; then
                        tmp="APFS Container Scheme"
                    fi

                    if [ "$tmp" == 41504653-0000-11AA-AA11-00306543ECAC ]; then
                        tmp="APFS Volume"
                    fi

                    tmpArray+=("$tmp")
                    echo "$tmp" # return to caller
                    break
                fi
            fi
        done
    }

    # ---------------------------------------------------------------------------------------
    BuildDiskUtilStringArrays()
    {
        # Six global string arrays are used for holding the disk information
        # that the DumpDiskUtilAndLoader() function walks through and uses.
        # They are declared in function Initiase().

        declare -a tmpArray
        declare -a diskUtilPlist
        declare -a allDisks
        declare -a WholeDisks
        declare -a diskUtilSliceInfo

        local checkSystemVersion
        local recordAdded=0
        local humanSize=0
        local oIFS="$IFS"
        IFS=$'\n'

        # print feedback to command line.
        echo "Reading disk information..."

        # Read Diskutil command in to array rather than write to file.
	    diskUtilPlist=( $( diskutil list -plist ))

	    unset tmpArray
        FindMatchInPlist "AllDisks" "string" "diskUtilPlist[@]"
        allDisks=("${tmpArray[@]}")

        unset tmpArray
        FindMatchInPlist "WholeDisks" "string" "diskUtilPlist[@]"
        wholeDisks=("${tmpArray[@]}")

        for (( s=0; s<${#allDisks[@]}; s++ ))
        do
            if [[ "${allDisks[$s]}" == *disk* ]]; then
                duIdentifier+=("${allDisks[$s]}")
                unset diskUtilSliceInfo
                diskUtilSliceInfo=( $( diskutil info -plist /dev/${duIdentifier[$s]} ))

                # Read and save Content
                tmp=$( FindMatchInSlicePlist "Content" "string" "diskUtilSliceInfo[@]" )
                duContent+=("$tmp")

                # Read and save TotalSize
                tmp=$( FindMatchInSlicePlist "TotalSize" "integer" "diskUtilSliceInfo[@]" )

                if [ $gSystemVersion -gt 9 ]; then
                    humanSize=$(ConvertUnit "${tmp}")
                else
                    humanSize=$(ConvertUnitPreSL "${tmp}")
                fi

                duSize+=("$humanSize")

                # Read and save VolumeName
                tmp=$( FindMatchInSlicePlist "VolumeName" "string" "diskUtilSliceInfo[@]" )

                if [ ! "${tmp}" == "" ]; then
                    duVolumeName+=( "${tmp}" )
                else
                    duVolumeName+=(" ")
                fi
  	          (( recordAdded++ ))
            fi
        done

        # Add content to duWholeDisks array.. Why do I need this?
        for (( n=0; n<${#wholeDisks[@]}; n++ ))
        do
            if [[ "${wholeDisks[$n]}" == *disk* ]]; then
                duWholeDisks+=("${wholeDisks[$n]#*    }")
            fi
        done

        # Before leaving, check all string array lengths are equal.
        if [ ${#duVolumeName[@]} -ne $recordAdded ] || [ ${#duContent[@]} -ne $recordAdded ] || [ ${#duSize[@]} -ne $recordAdded ] || [ ${#duIdentifier[@]} -ne $recordAdded ]; then
            echo "Error- Disk Utility string arrays are not equal lengths!"
            echo "records=$recordAdded V=${#duVolumeName[@]} C=${#duContent[@]} S=${#duSize[@]} I=${#duIdentifier[@]}"
            exit 1
        fi
    }

    # ---------------------------------------------------------------------------------------
    BuildXuidTextFile()
    {
        local passedTextLine="$1"

        if [ ! "$passedTextLine" == "" ]; then
            gXuidBuildFile="$gXuidBuildFile"$(printf "$passedTextLine\n")
            gXuidBuildFile="$gXuidBuildFile \n"
        fi
    }

   # ---------------------------------------------------------------------------------------
    GrabXUIDs()
    {
        local passedIdentifier="$1"
        local passedVolumeName="$2"

        local uuid=$( Diskutil info /dev/$passedIdentifier | grep "Volume UUID:" | awk '{print $3}' )
        local guid=$( ioreg -lxw0 -pIODeviceTree | grep -A 10 $passedIdentifier | sed -ne 's/.*UUID" = //p' | tr -d '"' | head -n1 )
        local volumeNameToDisplay="/Volumes/${passedVolumeName}"

        # Check for a blank UUID and replace with spaces so the padding is correct
        # in the UIDs.txt file.
        if [ "${uuid}" == "" ]; then
            uuid="                                    "
        fi
        BuildXuidTextFile "$passedIdentifier@${volumeNameToDisplay}@${uuid}@${guid}"
    }

    # ---------------------------------------------------------------------------------------
    ConvertAsciiToHex()
    {
        # Convert ascii string to hex
        # from http://www.commandlinefu.com/commands/view/6066/convert-ascii-string-to-hex
        echo "$1" | xxd -ps | sed -e ':a' -e 's/\([0-9]\{2\}\|^\)\([0-9]\{2\}\)/\1\\x\2/;ta' | tr '[:lower:]' '[:upper:]'
    }

    # ---------------------------------------------------------------------------------------
    FindStringInExecutable()
    {
        local passedString="$1"
        local passedFile="$2"
        local selection=""

        local hexString=$( ConvertAsciiToHex "$passedString" )
        hexString="${hexString%%0A*}"

        # Find offset(hex) of passedHex in file.
        offsetH=$( "$bgrep" "$hexString" "$passedFile" )
        
        if [ "$offsetH" != "" ]; then

            # Grab 128 hex bytes from offset, removing any line breaks.
            selection=$( tail -c +$((0x${offsetH##*: }+1)) "$passedFile" | head -c 128 | xxd -p | tr -d '\n' )

            # Trim at first occurrence of 0x0A. (Chameleon uses 0x0A as terminator)
            selection="${selection%%0a*}"

            # Trim at first occurrence of 0x00. (Clover uses 0x00 as terminator)
            selection="${selection%00*}"

            # Insert \x every two chars
            selection=$( echo "$selection" | sed 's/\(..\)/\1\\x/g' )

            # Strip ending \x
            selection="${selection%%\\x}"

            # Add preceding \x
            selection="\x$selection"

            # Convert hex to ASCII
            selection=$( printf '%b\n' "$selection" )

        fi

        # Return
        echo "$selection"
    }

    # ---------------------------------------------------------------------------------------
    IsStringPresent()
    {
        local searchString="$1"
        local bootFile="$2"
        local fileContains=$( grep -l "$searchString" "$bootFile" )

        echo "$fileContains" # Return
    }

    # ---------------------------------------------------------------------------------------
    CheckForBootFiles()
    {
        local passedVolumeName="/Volumes/$1"
        local passedDevice="$2"
        local bootFileCount=0
        local bootFiles=()
        local loaderVersion=""
        local firstRead=""
        local versionInfo=""
        local refitString=""
        local oIFS="$IFS"
        local checkMagic=""

        # Start checking for filenames beginning with boot
        # ignoring any boot* files with .extensions.
        bootFileCount=`find 2>/dev/null "${passedVolumeName}"/boot* -depth 0 -type f ! -name "*.*" | wc | awk '{print $1}'`
        if [ $bootFileCount -gt 0 ]; then
            (( bootFileCount-- )) # reduce by one so for loop can run from zero.
            IFS=$'\n'
            bootFiles=( $(find "${passedVolumeName}"/boot* -depth 0 -type f ! -name "*.*" 2>/dev/null) )
            IFS="$oIFS"
            for (( b=0; b<=$bootFileCount; b++ ))
            do
                loaderVersion=""
                currentBootfile="${bootFiles[$b]}"
                if [ -f "$currentBootfile" ]; then

                    # Check file is not a stage 0 or stage 1 file
                    checkMagic=$(dd 2>/dev/null ibs=2 count=1 skip=255 if="$currentBootfile" | xxd -p)
                    if [ ! "$checkMagic" == "55aa" ]; then

                        # Try to match a string inside the boot file.
                        fileContains=$( IsStringPresent "Chameleon" "$currentBootfile" )
                        if [ ! "$fileContains" == "" ]; then
                            revision=$( FindStringInExecutable "Darwin/x86 boot" "$currentBootfile" )
                            loaderVersion="Chameleon${revision##*Chameleon}"
                        fi
                        fileContains=$( IsStringPresent "Clover" "$currentBootfile" )
                        if [ ! "$fileContains" == "" ]; then
                            revision=$( FindStringInExecutable "Clover revision:" "$currentBootfile" )
                            loaderVersion="Clover r${revision##*: }"
                        fi
                        fileContains=$( IsStringPresent "RevoBoot" "$currentBootfile" )
                        if [ ! "$fileContains" == "" ]; then
                            loaderVersion="RevoBoot"
                        fi
                        fileContains=$( IsStringPresent "Windows Boot" "$currentBootfile" )
                        if [ ! "$fileContains" == "" ]; then
                            loaderVersion="Windows Boot Manager"
                        fi
                        fileContains=$( IsStringPresent "EFILDR20" "$currentBootfile" )
                        if [ ! "$fileContains" == "" ]; then
                            loaderVersion="XPC Efildr20 loader"
                        fi
                        BuildBootLoadersTextFile "BF:${currentBootfile##*/}"
                        BuildBootLoadersTextFile "S2:$loaderVersion"
                    fi
                fi
        	done
        fi
    }

    # ---------------------------------------------------------------------------------------
    CheckForEfildrFiles()
    {
        local passedVolumeName="/Volumes/$1"
        local passedDevice="$2"
        local efildFileCount=0
        local efildFiles=()
        local loaderVersion
        local oIFS="$IFS"
        local checkMagic=""

        # Start checking for filenames beginning with boot
        #ignoring any boot* files with .extensions.
        efildFileCount="$( find 2>/dev/null "${passedVolumeName}"/Efild* -type f ! -name "*.*"| wc | awk '{print $1}' )"
        if [ $efildFileCount -gt 0 ]; then
            (( efildFileCount-- )) # reduce by one so for loop can run from zero.
            IFS=$'\n'
            efildFiles=( $(find "${passedVolumeName}"/Efild* -type f ! -name "*.*" 2>/dev/null) )
            IFS="$oIFS"
            for (( b=0; b<=$efildFileCount; b++ ))
            do
                loaderVersion=""
                bytesRead=$( dd 2>/dev/null if=${efildFiles[$b]} bs=512 count=1 | perl -ne '@a=split"";for(@a){printf"%02x",ord}'  )
                if [ "${bytesRead:1020:2}" == "55" ]; then
                    case "${bytesRead:0:8}" in
                        "eb589049")
                            case "${bytesRead:286:2}" in
                                "79") loaderVersion="XPC Efildr20" ;;
                                "42") loaderVersion="EBL Efildr20" ;;
                            esac
                            ;;
                        "eb0190bd")
                            case "${bytesRead:286:2}" in
                                "3b") loaderVersion="XPC Efildgpt" ;;
                            esac
                            ;;
                    esac
                fi
                BuildBootLoadersTextFile "BF:${efildFiles[$b]##*/}"
                if [ ! "$loaderVersion" == "" ]; then
                    BuildBootLoadersTextFile "S2:$loaderVersion"
                fi
            done
        fi
    }

    # ---------------------------------------------------------------------------------------
    CheckForUEFIfiles()
    {
        local passedVolumeName="/Volumes/$1"
        local passedDevice="$2"
        local versionInfo=""
        local lineRead=""
        local fileContains=""

        for (( n=0; n<${#gUefiKnownFiles[@]}; n++ )) #gUefiKnownFiles is built in Initialise()
        do
            lineRead="${gUefiKnownFiles[$n]}"
            versionInfo=""
            if [ -f "${passedVolumeName}${lineRead}" ]; then
                if [ "${lineRead##*/}" == "BootX64.efi" ] || [ "${lineRead##*/}" == "BootIA32.efi" ]; then
                    # This could be one of many files renamed as BootX64.efi
                    fileContains=$( IsStringPresent "Clover" "${passedVolumeName}${lineRead}" )
                    if [ ! "$fileContains" == "" ]; then
                        revision=$( FindStringInExecutable "Clover revision:" "${passedVolumeName}${lineRead}" )
                        versionInfo="Clover r${revision##*: }"
                    else
                        fileContains=$( IsStringPresent "microsoft" "${passedVolumeName}${lineRead}" )
                        if [ ! "$fileContains" == "" ]; then
                            versionInfo="Windows"
                        else
                            fileContains=$( IsStringPresent "elilo" "${passedVolumeName}${lineRead}" )
                            if [ ! "$fileContains" == "" ]; then
                                 versionInfo="ELILO"
                            fi
                        fi
                    fi
                fi
                if [[ "${lineRead##*/}" == Clover* ]]; then
                    fileContains=$( IsStringPresent "Clover" "${passedVolumeName}${lineRead}" )
                    if [ ! "$fileContains" == "" ]; then
                        revision=$( FindStringInExecutable "Clover revision:" "${passedVolumeName}${lineRead}" )
                        versionInfo="Clover r${revision##*: }"
                    fi
                fi
                #BuildBootLoadersTextFile "UF:${lineRead##*/}"
                BuildBootLoadersTextFile "UF:$lineRead" # Include full path.
                BuildBootLoadersTextFile "U2:$versionInfo"
            fi
        done
    }

    # ---------------------------------------------------------------------------------------
    FindAndCopyUserPlistFiles()
    {
        local passedVolumeName="/Volumes/$1"
        local passedDevice="$2"
        local searchPlist=""
        local dirToMake=""
        local oIFS="$IFS"

        # ---------------------------------------------------------------------------------------
        SaveFiles()
        {
            local passedFile="$1"
            local passedDevice="$2"
            local passedVolumeName="$3"

            WriteToLog "${gLogIndent}Found ${passedFile}"
            dirToMake="${passedFile%/*}"
            dirToMake=$( echo "$dirToMake" | sed "s/\/Volumes\//${passedDevice}-/g" )
            mkdir -p "$gDumpFolderBootLoaderConfigs/$dirToMake"
            if [ -d "$gDumpFolderBootLoaderConfigs/$dirToMake" ]; then
                cp "$passedFile" "$gDumpFolderBootLoaderConfigs/$dirToMake"
                # if nvram.plist then unhide file
                if [[ "$passedFile" == *nvram.plist* ]]; then
                    WriteToLog "${gLogIndent}Unhiding $gDumpFolderBootLoaderConfigs/$dirToMake/nvram.plist"
                    chflags nohidden "$gDumpFolderBootLoaderConfigs/$dirToMake/nvram.plist"
                fi
            else
                WriteToLog "${gLogIndent}Error: Failed to create directory: $gDumpFolderBootLoaderConfigs/$dirToMake"
            fi
        }

        WriteToLog "${gLogIndent}Searching for Bootloader files on $passedDevice"

        IFS=$'\n'
        if [ -d "${passedVolumeName}/Extra" ]; then
            searchPlist=""
            searchPlist=( $(find "${passedVolumeName}/Extra" -type f -name 'org.chameleon.Boot.plist') )
            if [ ! "$searchPlist" == "" ]; then
                for (( p=0; p<${#searchPlist[@]}; p++ ))
                do
                    SaveFiles "${searchPlist[$p]}" "$passedDevice" "$passedVolumeName"
                    # Copy also a SMBIOS.plist file if it exists.
                    searchPath="${searchPlist[$p]%/*}"
                    if [ -f "$searchPath"/SMBIOS.plist ]; then
                        cp "$searchPath"/SMBIOS.plist "$gDumpFolderBootLoaderConfigs/$dirToMake"
                    fi
                done
            fi
        fi

        if [ -d "${passedVolumeName}/EFI" ]; then
            # Could be with Clover, XPC, Ozmosis or Genuine Mac
            # Check for Clover config.plist file
            searchPlist=""
            searchPlist=( $(find "${passedVolumeName}/EFI" -type f -name 'config.plist' 2>/dev/null) )
            if [ ! "$searchPlist" == "" ]; then
                for (( p=0; p<${#searchPlist[@]}; p++ ))
                do
                    SaveFiles "${searchPlist[$p]}" "$passedDevice" "$passedVolumeName"
                done
                FindAndListCloverDriverFiles "$1" "${passedDevice}"
                FindAndCopyRefitConfFile "$1" "${passedDevice}"
            fi

            # Check for XPC settings files
            searchPlist=""
            searchPlist=( $(find "${passedVolumeName}/EFI" -type f -name 'settings.plist' -o -name 'xpc_patcher.plist' -o -name 'xpc_smbios.plist' 2>/dev/null) )
            for (( p=0; p<${#searchPlist[@]}; p++ ))
            do
                SaveFiles "${searchPlist[$p]}" "$passedDevice" "$passedVolumeName"
            done

            # Check for Ozmosis Defaults file
            searchPlist=""
            searchPlist=( $(find "${passedVolumeName}/EFI" -type f -name 'Defaults.plist' 2>/dev/null) )
            for (( p=0; p<${#searchPlist[@]}; p++ ))
            do
                SaveFiles "${searchPlist[$p]}" "$passedDevice" "$passedVolumeName"
            done
        fi

        if [ -d "${passedVolumeName}/Library" ]; then
            searchPlist=""
            searchPlist=( $(find "${passedVolumeName}/Library" -type f -name 'com.apple.Boot.plist' 2>/dev/null) )
            for (( p=0; p<${#searchPlist[@]}; p++ ))
            do
                SaveFiles "${searchPlist[$p]}" "$passedDevice" "$passedVolumeName"
            done
        fi

        # Check for Clover nvram.plist files
        if [ -d "${passedVolumeName}" ]; then
            searchNvramPlist=$(find "${passedVolumeName}/" -maxdepth 1 -type f -name 'nvram.plist' 2>/dev/null)
            if [ ! "$searchNvramPlist" == "" ]; then
                searchNvramPlist=$( echo "${searchNvramPlist}" | sed 's/\/\//\//g' )
                SaveFiles "$searchNvramPlist" "$passedDevice" "$passedVolumeName"
            fi
        fi
        IFS="$oIFS"
    }

    # ---------------------------------------------------------------------------------------
    FindAndListCloverDriverFiles()
    {
        local passedVolumeName="/Volumes/$1/EFI"
        local passedDevice="$2"
        local driverFolders=(drivers32 drivers64 drivers64UEFI "Clover/drivers32" "Clover/drivers64" "Clover/drivers64UEFI")
        local versionInfo=""
        local fileContains=""

        for (( q=0; q<${#driverFolders[@]}; q++ ))
        do
            if [ -d "${passedVolumeName}"/"${driverFolders[$q]}" ]; then

                dirToMake="${passedVolumeName}"/"${driverFolders[$q]}"
                dirToMake=$( echo "$dirToMake" | sed "s/\/Volumes\//${passedDevice}-/g" )

                # Create a Clover Drivers List.txt file inside a duplicate directory structure.
                #mkdir -p "$gDumpFolderBootLoaderDrivers/$dirToMake"
                #ls -al "${passedVolumeName}"/"${driverFolders[$q]}" > "${gDumpFolderBootLoaderDrivers}/${dirToMake}/Clover Drivers List.txt"

                # Create a single Clover Drivers List.txt file without any directory structure.
                [ ! -d "$gDumpFolderBootLoaderDrivers" ] && mkdir -p "$gDumpFolderBootLoaderDrivers/"
                echo "================================================" >> "${gDumpFolderBootLoaderDrivers}/Clover Drivers List.txt"
                echo "${passedDevice}" >> "${gDumpFolderBootLoaderDrivers}/Clover Drivers List.txt"
                echo "================================================" >> "${gDumpFolderBootLoaderDrivers}/Clover Drivers List.txt"
                ls -nAhlTU "${passedVolumeName}"/"${driverFolders[$q]}"/*.efi >> "${gDumpFolderBootLoaderDrivers}/Clover Drivers List.txt"

                # Get driver revisions.
                searchDrivers=( $(find "${passedVolumeName}"/"${driverFolders[$q]}" -depth 1 -name '*.efi') )
                if [ ${#searchDrivers[@]} -gt 0 ]; then
                    echo "---------" >> "${gDumpFolderBootLoaderDrivers}/Clover Drivers List.txt"
                    echo "Versions:" >> "${gDumpFolderBootLoaderDrivers}/Clover Drivers List.txt"
                    for (( ds=0; ds<${#searchDrivers[@]}; ds++ ))
                    do
                        fileContains=$( IsStringPresent "revision" "${searchDrivers[$ds]}" )
                        if [ ! "$fileContains" == "" ]; then
                            versionInfo=$( FindStringInExecutable "Clover revision" "${searchDrivers[$ds]}" )
                            echo "${searchDrivers[$ds]##*/} (${versionInfo})" >> "${gDumpFolderBootLoaderDrivers}/Clover Drivers List.txt"
                        else
                            echo "${searchDrivers[$ds]##*/} (Unknown)" >> "${gDumpFolderBootLoaderDrivers}/Clover Drivers List.txt"
                        fi
                    done
                    echo "" >> "${gDumpFolderBootLoaderDrivers}/Clover Drivers List.txt"
                fi

            fi
        done
    }

    # ---------------------------------------------------------------------------------------
    FindAndCopyRefitConfFile()
    {
        local passedVolumeName="$1"
        local passedDevice="$2"
        local initialPath="/Volumes/$passedVolumeName"
        local secondaryPaths=("/EFI/BOOT" "/EFI/Clover")

        for (( q=0; q<${#secondaryPaths[@]}; q++ ))
        do
            local pathToSearch="${initialPath}${secondaryPaths[$q]}"
            if [ -f "${pathToSearch}"/refit.conf ]; then
                dirToMake="${pathToSearch}"
                dirToMake=$( echo "$dirToMake" | sed "s/\/Volumes\//${passedDevice}-/g" )
                mkdir -p "$gDumpFolderBootLoaderConfigs/$dirToMake"
                cp "${pathToSearch}"/refit.conf "$gDumpFolderBootLoaderConfigs/$dirToMake"

            fi
        done
    }

    # ---------------------------------------------------------------------------------------
    GetDiskMediaName()
    {
        local passedDevice="$1"
        local diskname=$(diskutil info "$passedDevice" | grep "Media Name")

        diskname="${diskname#*:      }"
        echo "$diskname" # This line acts as a return to the caller.
    }

    # ---------------------------------------------------------------------------------------
    FindMbrBootCode()
    {
        local passedDevice="$1"
        local stage0CodeDetected=""
        local bytesRead=$( dd 2>/dev/null if="/dev/$passedDevice" bs=512 count=1 | perl -ne '@a=split"";for(@a){printf"%02x",ord}' )
        if [ "${bytesRead:1020:2}" == "55" ]; then
            case "${bytesRead:210:6}" in
                "0a803c") stage0CodeDetected="boot0" ;;
                "0b807c") stage0CodeDetected="boot0hfs" ;;
                "742b80") stage0CodeDetected="boot0md" ;;
                "ee7505") stage0CodeDetected="boot0md (dmazar v1)" ;;
                "742b80") stage0CodeDetected="boot0md (dmazar boot0workV2)" ;;
                "a300e4") stage0CodeDetected="boot0 (dmazar timing)" ;;
                "09803c") stage0CodeDetected="boot0xg" ;; # Became boot0 in Chameleon r2507
                "09f604") stage0CodeDetected="boot0 (ExFAT)" ;; # From Chameleon r2507
                "060000") stage0CodeDetected="DUET" ;;
                "75d280") stage0CodeDetected="Windows XP MBR" ;;
                "760868") stage0CodeDetected="Windows Vista,7 MBR" ;;
                "0288c2") stage0CodeDetected="GRUB" ;;
            esac

            # If code is not yet identified then check for renamed boot0 and boot0hfs files.
            # See Clover commit r1560   http://sourceforge.net/p/cloverefiboot/code/1560/
            if [ "$stage0CodeDetected" == "" ]; then
                case "${bytesRead:860:14}" in
                    "626f6f74307373") stage0CodeDetected="boot0ss (Signature Scanning)" ;;
                    "626f6f74306166") stage0CodeDetected="boot0af (Active First) " ;;
                esac
            fi

            # If code is not yet identified then check is it blank?
            if [ "$stage0CodeDetected" == "" ]; then
                if [ "${bytesRead:0:32}" == "00000000000000000000000000000000" ] ; then
                    stage0CodeDetected="None"
                fi
            fi
            # If code is not yet identified then check for known structures
            if [ "$stage0CodeDetected" == "" ]; then
                if [ "${bytesRead:164:16}" == "4641543332202020" ] ; then #FAT32
                    if [ "${bytesRead:6:16}" == "4d53444f53352e30" ]; then
                        stage0CodeDetected="FAT32 MSDOS 5.0 Boot Disk"
                    fi
                    if [ "${bytesRead:262:20}" == "4e6f6e2d73797374656d" ]; then
                        stage0CodeDetected="FAT32 Non-System Disk"
                    fi
                fi
                if [ "${bytesRead:108:16}" == "4641543136202020" ]; then #FAT16
                    if [ "${bytesRead:6:16}" == "4d53444f53352e30" ]; then
                        stage0CodeDetected="FAT16 MSDOS 5.0 Boot Disk"
                    fi
                    if [ "${bytesRead:206:20}" == "4e6f6e2d73797374656d" ]; then
                        stage0CodeDetected="FAT16 Non-System Disk"
                    fi
                fi

            fi
            # If code is not yet identified then mark as Unknown.
            if [ "$stage0CodeDetected" == "" ]; then
                stage0CodeDetected="Unknown (If you know, please report)."
            fi
        fi

        # Check of existence of the string GRUB as it can
        # appear at a different offsets depending on version.
        if [[ "${bytesRead}" == *475255422000* ]]; then
            stage0CodeDetected="GRUB"
            # TO DO - How to detect grub version?
        fi

        echo "$stage0CodeDetected" # This line acts as a return to the caller.
    }

    # ---------------------------------------------------------------------------------------
    FindPbrBootCode()
    {
        local passedDevice="$1"
        local stage1CodeDetected=""
        local pbrBytesToGrab=1024
        local bytesRead=$( dd 2>/dev/null if="/dev/r$passedDevice" bs=$pbrBytesToGrab count=1 | perl -ne '@a=split"";for(@a){printf"%02x",ord}' )
        local byteFiveTen="${bytesRead:1020:2}"

    	if [ "$byteFiveTen" == "55" ]; then
            if [ "${bytesRead:0:16}" == "fa31c08ed0bcf0ff" ]; then
                case "${bytesRead:126:2}" in
                    "a3") stage1CodeDetected="Chameleon boot1h" ;;
                    "a2") stage1CodeDetected="boot1h" ;; # 01/04/15 - Clover and Chameleon now both have same boot1h
                    "66") case "${bytesRead:194:4}" in
                            "d007") stage1CodeDetected="Clover boot1h2" ;;
                            "8813") stage1CodeDetected="Clover boot1altV3" ;;
                          esac
                esac
            fi
            if [ "${bytesRead:180:12}" == "424f4f542020" ]; then
                if [ "${bytesRead:0:4}" == "e962" ] || [ "${bytesRead:0:4}" == "eb63" ]; then
                    case "${bytesRead:290:2}" in
                        "bf") stage1CodeDetected="Chameleon boot1f32" ;;
                        "b9") stage1CodeDetected="Clover boot1f32alt" ;;
                    esac
                fi
            fi
            if [ "${bytesRead:0:4}" == "eb76" ]; then
               case "${bytesRead:398:2}" in
                    "6d") stage1CodeDetected="boot1x" ;;
                    "9f") stage1CodeDetected="Clover boot1xalt" ;;
                esac
            fi
            if [ "${bytesRead:0:4}" == "eb58" ]; then
                case "${bytesRead:180:12}" in
                    "33c98ed1bcf4") stage1CodeDetected="Windows FAT32 NTLDR"
                                    pbrBytesToGrab=512 ;;
                    "8d36e301e8fc") stage1CodeDetected="FAT32 DUET"
                                    pbrBytesToGrab=512 ;;
                    "fa31c08ed0bc")
                    if [ "${bytesRead:142:6}" == "454649" ]; then
                        stage1CodeDetected="Apple EFI"
                    else
                        stage1CodeDetected="FAT32 Non System disk"
                    fi
                    ;;
                esac
            elif [ "${bytesRead:0:4}" == "eb76" ] && [ "${bytesRead:6:16}" == "4558464154202020" ]; then #exFAT
                if [ "${bytesRead:1024:32}" == "00000000000000000000000000000000" ] ; then
                    #stage1CodeDetected="exFAT Blank"
                    stage1CodeDetected="None"
                fi
                if [ "${bytesRead:1028:28}" == "42004f004f0054004d0047005200" ] ; then
                    stage1CodeDetected="Windows exFAT NTLDR"
                fi
            elif [ "${bytesRead:0:4}" == "b800" ] && [ "${bytesRead:180:12}" == "5033c08ec0bf" ]; then
                stage1CodeDetected="GPT DUET"
            elif [ "${bytesRead:0:4}" == "eb3c" ]; then
                if [ "${bytesRead:180:12}" == "1333c08ac6fe" ]; then
                    stage1CodeDetected="FAT16 DUET"
                    pbrBytesToGrab=512
                elif [ "${bytesRead:180:12}" == "0ecd10ebf530" ]; then
                    stage1CodeDetected="FAT16 Non System"
                fi
            elif [ "${bytesRead:0:16}" == "eb52904e54465320" ]; then
                stage1CodeDetected="Windows NTFS NTLDR"
                pbrBytesToGrab=512
            fi
            # Check of existence of the string GRUB as it can
            # appear at a different offsets depending on version.
            if [[ "${bytesRead}" == *475255422000* ]]; then
                stage1CodeDetected="GRUB"
                # TO DO - How to detect grub version?
                pbrBytesToGrab=512
            fi
            # If code is not yet identified then mark as Unknown.
            if [ "$stage1CodeDetected" == "" ]; then
                stage1CodeDetected="Unknown (If you know, please report)."
            fi
        fi
        echo "${stage1CodeDetected}:$byteFiveTen" # This line acts as a return to the caller.
        if [ "$pbrBytesToGrab" == "1024" ]; then # need to pass this back to caller, exporting does not work
        	return 0
        else
        	return 1
        fi
    }

    # ---------------------------------------------------------------------------------------
    SearchStringArraysdu()
    {
        local arrayToSearch="$1"
        local itemToFind="$2"
        local loopCount=0
        local itemfound=0

        if [ "$arrayToSearch" == "duIdentifier" ]; then
            while [ "$itemfound" -eq 0 ] && [ $loopCount -le "${#duIdentifier[@]}" ]; do
                if [ "${duIdentifier[$loopCount]}" == "$itemToFind" ]; then
                    itemfound=1
                fi
                (( loopCount++ ))
            done
            if [ $itemfound -eq 1 ]; then
                (( loopCount-- ))
                echo $loopCount # This line acts as a return to the caller.
            fi
        fi
    }

    # ---------------------------------------------------------------------------------------
    BuildBootLoadersTextFile()
    {
        local passedTextLine="$1"

        if [ ! "$passedTextLine" == "" ]; then
            gBootloadersTextBuildFile="$gBootloadersTextBuildFile"$(printf "$passedTextLine\n")
            gBootloadersTextBuildFile="$gBootloadersTextBuildFile \n"
        fi
    }

    # ---------------------------------------------------------------------------------------
    BuildPartitionTableInfoTextFile()
    {
        local passedDevice="/dev/$1"
        local outFile="${gDumpFolderDiskPartitionInfo}/${1}-gpt-fdisk.txt"
        local passedName="$2"
        local passedSize="$3"

        if [ ! "$passedDevice" == "" ]; then
            echo "$passedDevice - $passedName - $passedSize" >> "$outFile"
            echo "" >> "$outFile"
            if [ $gRootPriv -eq 1 ]; then
                echo "============================================================================" >> "$outFile"
                echo "gpt -r show" >> "$outFile"
                echo "============================================================================" >> "$outFile"
                gpt -r show "$passedDevice" >> "$outFile"
                echo "" >> "$outFile"
                echo "" >> "$outFile"
                echo "============================================================================" >> "$outFile"
                echo "fdisk" >> "$outFile"
                echo "============================================================================" >> "$outFile"
                "$fdisk440" "$passedDevice" >> "$outFile"
                "$bdisk" "$gDumpFolderDisks" "$1" "html"
            else
                echo "** Root privileges required to read further info." >> "$outFile"
            fi
        fi
    }

    # ---------------------------------------------------------------------------------------
    GetDiskMediaName()
    {
        local passedDevice="$1"
        local diskname=$(diskutil info "$passedDevice" | grep "Media Name")

        diskname="${diskname##*:      }"
        diskname="${diskname% Media}"
        echo "$diskname" # This line acts as a return to the caller.
    }

    #------------------------------------------------
    # Procedure to read the disk physical block size from ioreg (thanks JrCs).
    GetDiskBlockSize()
    {
        local passedName="$1"
        local diskPhysicalBlockSize=""

        OIFS=$IFS; IFS=','
        devCharacteristic=$( ioreg -lw0 | grep "$passedName" | grep "Device Characteristics" | sed 's/|* //g' )

        local productName=""; local blockSize=""
        for x in $devCharacteristic
        do
            item=$( echo "$x" | tr "," "\n" )
            if [[ "$item" == *ProductName* ]]; then
              productName=$( echo "$item" | tr -d "\"" )
            fi
            if [[ "$item" == *PhysicalBlockSize* ]]; then
              blockSize=$( echo "$item" | tr -d "\"" )
            fi
            if [ ! -z "${productName}" ] && [ ! -z "${blockSize}" ]; then
                diskPhysicalBlockSize="${blockSize##*=}"
                productName=""; blockSize=""
            fi
        done
        IFS=$OIFS

        if [ "$diskPhysicalBlockSize" == "" ]; then
            # Default to 512
            diskPhysicalBlockSize="512"
        fi

        echo "(${diskPhysicalBlockSize} byte physical block size)" # This line acts as a return to the caller.
    }

    # ---------------------------------------------------------------------------------------
    #echo "${gLogIndent}Preparing to read disks...
    #      Note: There may be a delay if any disks are sleeping" >> "$logFile"
    WriteToLog "${gLogIndent}Preparing to read disks..."
    WriteToLog "Note: There may be a delay if any disks are sleeping"

    if [ $gRunDiskutilAndLoaders -eq 1 ]; then
        mkdir -p "$gDumpFolderDiskBootSectors"
    fi

    if [ $gRunDisks -eq 1 ]; then
        mkdir -p "$gDumpFolderDiskPartitionInfo"
    fi

    #if [ $gRunDiskutilAndLoaders -eq 1 ]; then
        diskutil list > "$gDumpFolderDisks"/diskutil_list.txt
        diskutil cs list > "$gDumpFolderDisks"/diskutil_cs_list.txt
        diskutil ap list > "$gDumpFolderDisks"/diskutil_ap_list.txt
    #fi

    BuildDiskUtilStringArrays

    # print feedback to command line.
    echo "Scanning each disk..."

    # Loop through each disk
    for (( d=0; d<${#duWholeDisks[@]}; d++ ))
    do
        diskPositionInArray=$(SearchStringArraysdu "duIdentifier" "${duWholeDisks[$d]}")
        diskMediaName=$(GetDiskMediaName "/dev/${duWholeDisks[$d]}")
        diskPhysicalSectorSize=$(GetDiskBlockSize "$diskMediaName")
        echo "Scanning disk: ${duWholeDisks[$d]}" # To stdout
        #echo "${gLogIndent}Scanning disk: ${duWholeDisks[$d]}" >> "$logFile" # To logfile
        WriteToLog "${gLogIndent}Scanning disk: ${duWholeDisks[$d]}"
        if [ $gRootPriv -eq 1 ]; then
            activeSliceNumber=$( fdisk -d "/dev/r${duWholeDisks[$d]}" | grep -n "*" | awk -F: '{print $1}' )
        fi
        mbrBootCode=$(FindMbrBootCode "${duWholeDisks[$d]}")
        BuildBootLoadersTextFile "WD:${duWholeDisks[$d]}"
        BuildBootLoadersTextFile "DN:${diskMediaName} ${diskPhysicalSectorSize}"
        BuildBootLoadersTextFile "DS:${duSize[$diskPositionInArray]}"
        BuildBootLoadersTextFile "DT:${duContent[$diskPositionInArray]}"
        BuildBootLoadersTextFile "S0:$mbrBootCode"
        if [ $gRunDisks -eq 1 ]; then
            #echo "${gLogIndent}Reading partition info for: ${duWholeDisks[$d]}" >> "$logFile"
            WriteToLog "${gLogIndent}Reading partition info for: ${duWholeDisks[$d]}"
            BuildPartitionTableInfoTextFile "${duWholeDisks[$d]}" "$diskMediaName" "${duSize[$diskPositionInArray]}"
        fi
        if [ $gRunDiskutilAndLoaders -eq 1 ]; then
            # Prepare file dump for disk sectors
            diskSectorDumpFile="$gDumpFolderDiskBootSectors/${duWholeDisks[$d]}-${diskMediaName}-${duSize[$diskPositionInArray]}.txt"
            echo "${duWholeDisks[$d]} - $diskMediaName - ${duSize[$diskPositionInArray]} ${diskPhysicalSectorSize}" >> "$diskSectorDumpFile"
            echo "MBR: First 512 bytes    Code Detected: $mbrBootCode" >> "$diskSectorDumpFile"

            # Dump MBR to file
            if [ $gRootPriv -eq 1 ]; then
                xxd -l512 "/dev/${duWholeDisks[$d]}" >> "$diskSectorDumpFile"
            else
                echo "** Root privileges required to read further info." >> "$diskSectorDumpFile"
            fi
        fi

        gpt=0

        # Loop through each volume for current disk, writing details each time
        for (( v=0; v<${#duIdentifier[@]}; v++ ))
        do
            if [[ ${duIdentifier[$v]} == ${duWholeDisks[$d]} ]] && [ "${duContent[$v]}" == "GUID_partition_scheme" ]; then
                gpt=1
            fi
            if [[ ${duIdentifier[$v]} == ${duWholeDisks[$d]}* ]] && [[ ! ${duIdentifier[$v]} == ${duWholeDisks[$d]} ]] ; then

                echo "               ${duIdentifier[$v]}" # To stdout

                # If this slice is active then add asterisk
                partitionActive=" "
                if [ "${duIdentifier[$v]##*s}" == "$activeSliceNumber" ]; then
                    partitionActive="*"
                fi

                # Is the VolumeName empty or contains only whitespace?
                if [ "${duVolumeName[$v]}" == "" ] || [[ "${duVolumeName[$v]}" =~ ^\ +$ ]] ;then
                    diskUtilInfoDump=$(diskutil info "${duIdentifier[$v]}")
                    fileSystemPersonality=$(echo "${diskUtilInfoDump}" | grep -F "File System Personality")
                    fileSystemPersonality=${fileSystemPersonality#*:  }
                    mediaName=$(echo "${diskUtilInfoDump}" | grep "Media Name")
                    mediaName=${mediaName#*:      }
                    volumeName=$(echo "${diskUtilInfoDump}" | grep "Volume Name")
                    volumeName=${volumeName#*:              }
                    if [ ! "$fileSystemPersonality" == "" ]; then
                        if [ "$fileSystemPersonality" == "NTFS" ]; then
                            partitionname=$mediaName
                        else
                            partitionname=$volumeName
                        fi
                    else
                        if [ "$volumeName" == "Apple_HFS" ]; then
                            partitionname=$volumeName
                        else
                            partitionname=$mediaName
                        fi
                    fi
                else
                    partitionname="${duVolumeName[$v]}"
                fi

                if [ $gRunDiskutilAndLoaders -eq 1 ]; then
                    returnValue=$(FindPbrBootCode "${duIdentifier[$v]}")
                    #Note: FindPbrBootCode returns $pbrBootCode":"$byteFiveTen"
                    pbrBootCode="${returnValue%:*}"
                    byteFiveTen="${returnValue##*:}"
                    if [ $? -eq 0 ];then
                        pbrBytesToGrab=1024
	    		    else
        	    		pbrBytesToGrab=512
	        		fi

		        	# Dump PBR to file
                    echo "" >> "$diskSectorDumpFile"
                    echo "${duIdentifier[$v]} - $partitionname - ${duSize[$v]}"  >> "$diskSectorDumpFile"
                    if [ "${pbrBootCode}" != "" ] || [ "$byteFiveTen" == "55" ]; then
                    	echo "PBR: First $pbrBytesToGrab bytes    Code Detected: ${pbrBootCode}" >> "$diskSectorDumpFile"
                    	if [ $gRootPriv -eq 1 ]; then
	                	    dd 2>/dev/null if="/dev/r"${duIdentifier[$v]} bs=$pbrBytesToGrab count=1 | xxd -l$pbrBytesToGrab >> "$diskSectorDumpFile"
	                	else
	                	    echo "** Root privileges required to read further info." >> "$diskSectorDumpFile"
	                	fi
	                	if [ "${pbrBootCode}" == "None" ]; then
	                	    pbrBootCode=""
	                	fi
                    else
	                	echo "PBR: No Stage1 Loader Detected" >> "$diskSectorDumpFile"
                    fi
                    echo >> "$diskSectorDumpFile"
                    BuildBootLoadersTextFile "VA:$partitionActive"
                    BuildBootLoadersTextFile "VD:${duIdentifier[$v]}"
                    BuildBootLoadersTextFile "VT:${duContent[$v]}"
                    BuildBootLoadersTextFile "VN:${duVolumeName[$v]}"
                    BuildBootLoadersTextFile "VS:${duSize[$v]}"
                    BuildBootLoadersTextFile "S1:$pbrBootCode"
                fi

                # -------------------------------
                # Check for stage 2 loader files.
                # -------------------------------

                # Check if the current volume is mounted as some will be hidden
                # For example, an unmounted ESP or Lion Recovery HD.
                # If not mounted then there's no need to check for stage2 files.
                checkMounted=""
                checkMounted=$( mount | grep "/dev/${duIdentifier[$v]}" )
                checkMounted="${checkMounted% on *}"
                checkMounted="${checkMounted##*/}"
                mountedAs=""
                if [ "$checkMounted" == "${duIdentifier[$v]}" ]; then
                    if [ ! "$checkMounted" == "" ]; then
                        mountedAs="${duVolumeName[$v]}"
                        # Check for Windows partitions
                        if [ "${duVolumeName[$v]}" == " " ] && [ "${duContent[$v]}" == "Microsoft Basic Data" ]; then
                            mountedAs=$( mount | grep /dev/${duIdentifier[$v]} | awk {'print $3'})
                            mountedAs="${mounted##*/}"
                        fi
                    fi
                else # volume is not mounted.

                    # Are we reading a GPT disk?
                    if [ $gpt -eq 1 ]; then
                       # is the slice of type "EFI"?
                        if [ "${duContent[$v]}" == "EFI" ]; then
                            diskutil mount readOnly "/dev/${duIdentifier[$v]}" && mountedEFI=1
                        fi
                    fi

                    mountedAs="${duVolumeName[$v]}"
                fi

                if [ ! "${mountedAs}" == "" ] && [ ! "${mountedAs}" == " " ]; then
                    if [ $gRunDiskutilAndLoaders -eq 1 ]; then
	                    CheckForBootFiles "${mountedAs}" "${duIdentifier[$v]}"
	                    CheckForEfildrFiles "${mountedAs}" "${duIdentifier[$v]}"
	                    CheckForUEFIfiles "${mountedAs}" "${duIdentifier[$v]}"
	                fi
	                if [ $gRunBootloaderConfigFiles -eq 1 ]; then
	                    FindAndCopyUserPlistFiles "${mountedAs}" "${duIdentifier[$v]}"
	                fi
                fi

                if [ $gRunDisks -eq 1 ]; then # This now happens without a separate option.
                    # We still want to find the UID's of a Recovery HD, even if it's not mounted,
                    if [ "${duVolumeName[$v]}" == "Recovery HD" ]; then
                        mountedAs="Recovery HD"
                    fi
                    GrabXUIDs "${duIdentifier[$v]}" "${mountedAs}"
                fi

                # If we mounted an EFI system partition earlier then we should un-mount it.
                if [ $mountedEFI -eq 1 ]; then
                    diskutil umount "/dev/${duIdentifier[$v]}"
                    mountedEFI=0
                fi
            fi
        done
        BuildBootLoadersTextFile "================================="
    done
    # ----------------------------------------------
    # Write the Bootloaders file to disk.
    # Also write the UID file to disk.
    # Doing it here allows columns to be aligned.
    # ----------------------------------------------
    if [ $gRunDiskutilAndLoaders -eq 1 ]; then
        printf "${gBootloadersTextBuildFile}" | column -t -s@ >> "${diskUtilLoaderInfoFile}"
    fi
    if [ $gRunDisks -eq 1 ]; then
        printf "${gXuidBuildFile}" | column -t -s@ >> "${xuidFile}"
    fi
}

# =======================================================================================
# MAIN
# =======================================================================================
#
Initialise "$1" "$2" "$3" "$4"
if [ $gRunBootloaderConfigFiles -eq 1 ] || [ $gRunDiskutilAndLoaders -eq 1 ] || [ $gRunDisks -eq 1 ]; then
    CheckRoot
    DumpDiskUtilAndLoader
fi

# Send notification to the UI
if [ $gRunBootloaderConfigFiles -eq 1 ]; then
    SendToUI "@DF@F:diskLoaderConfigs@"
fi
if [ $gRunDisks -eq 1 ]; then
    SendToUI "@DF@F:diskPartitionInfo@"
fi
