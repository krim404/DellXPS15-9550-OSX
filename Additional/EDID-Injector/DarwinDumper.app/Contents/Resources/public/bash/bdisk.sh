#!/bin/sh

# A script to read an interpret a disk's partition structure.
# Copyright (C) 2013-2016 Blackosx <darwindumper@yahoo.com>
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
# This script reads a disk's Master Boot Record to discover the
# partition entries, and also checks for any loader code. The 
# partition entries are then interpreted and the results are
# printed. 
#
# If a type EE (GPT) is found then the GPT is walked and the
# contents are also interpreted and printed to stdout. In the
# case of a Hybrid GPT, the MBR partition entries are matched
# against the GPT and printed beside the GTP partitions.
#
# The script can write a list-type file for parsing later
# for building an HTML file to show the disk layout.
# 
# The script can also write what it reads and interprets from
# the disk to file.
#
# Note: This script only works with MBR and GPT partition maps
# and not other types, for example APM (Apple Partition Map).
# ================================================================
# Notes: 1 block = Unix terminology for 1 sector.
# Notes: 1 LBA = 1 block.
# Notes: 1 block size, generally (pre 2010) = 512bytes
# Notes: 1 block size, Advanced sector drives;(2010->) = 4096bytes (but emulate 512 byte sectors)
# ================================================================
#
# v0.50
#
# Thanks to the following people for testing, advice and help.
# Testers: !Xabbu, kyndder, JrCs, STLVNUB, dmazar.
#
#
# Usage: ./bdisk.sh <Save Dir> <diskX> [Optional <html>]
# Where diskX is the disk number of disk you want to scan and interpret.
# Where html is optional and instructs the script to write files to disk then create and html report file.
#
#
# Switches
#
# The fastest way to get info from this script is to disable all switches.
# Without any switches enabled, the script just prints an overview of the disk to stdout.

createHtml=1   # This is now set by passing the 'html' argument when calling script. This automatically sets writeFiles to 1 also.
               # Set to 1 to produce HTML table. 
               # If writeFiles 0 (disabled), then the html partiton table will be created but will NOT contain the hex & detail info.
               # If writeFiles 1 (enabled), then the html report will be complete and contain the table AND hex & detail info.
               
writeFiles=1   # This is now set by passing argument when calling script. This is automatically set when passing 'html' argument to script.
               # Set to 1 to write the hex bytes and decoded info to files.
               # These files are required for the HTML file to include hex and details dumps.
               
dumpOverview=0 # Set to 1 to print the final overview to stdout.
               
verboseMode=0  # Set to 1 to print the decoded hex bytes info to stdout.

verboseHex=0   # Set to 1 to print the actual hex bytes to stdout. (Requires VerboseMode enabled)

# get the absolute path of the executable
SELF_PATH=$(cd -P -- "$(dirname -- "$0")" && pwd -P) && SELF_PATH=$SELF_PATH/$(basename -- "$0")
source "${SELF_PATH%/*}"/shared.sh
    
# Save Location
if [ "$1" == "" ]; then
    dumpFolderPath="$SELF_PATH"
else
    dumpFolderPath="$1"
fi 
#gOutputFolder="$dumpFolderPath"/"Disk"

# Disk to read
diskToRead="$2"
if [ "$diskToRead" == "" ]; then
    echo "No disk passed to read"
    echo "Please use: ./bdisk.sh <SAVE DIR> diskX"
    exit 1
fi

# Is an HTML file wanted?
if [ ! "$3" == "" ]; then
    if [ "$3" == "html" ]; then
        writeFiles=1
        createHtml=1
    fi
fi

# If running as standalone script, set logfile and path vars
if [ -z "$logFile" ] || [ ! -f "$logFile" ]; then
    logFile="/dev/null"
    gDumpFolderDiskPartitionInfo="${dumpFolderPath}/Partition Info"
fi

if [ "$gDumpFolderDiskPartitionInfo" == "" ]; then
  gDumpFolderDiskPartitionInfo="${dumpFolderPath}/Partition Info"
fi

#------------------------------------------------
Initialise()
{
    # Initialise some global vars
    declare -a gPartitionEntriesToProcess
    declare -a gGPTPartitionEntries
    declare -a hybridLbaStart
    declare -a hybridActive
    declare -a hybridType  
    declare -a hybridSize
    declare -a cssInitBlocks
    declare -a gEeStartingLBA
    
    gProtectiveMBRFlag=0
    gFoundExtendedPartition=0
    gFirstExtendedPartitionSector=0
    gNextExtendedPartitionSector=0
    gLbaCounter=0
    gProtectedPartitionEnd=""
    #gEeStartingLBA=0
    gFinalDumpTable=""
    gGatheredInfo=""
    gGraphTableData=""
    gGraphHeaderData=""
    
    # Get Disk info
    diskInfo=$(diskutil info "/dev/$diskToRead")
    gDiskName=$( echo "$diskInfo" | grep "Media Name" )
    gDiskName="${gDiskName#*:      }"
    gDiskSize=$( echo "$diskInfo" | grep "Total Size" )
    gDiskSize="${gDiskSize#*:               }"
    gDiskSizeBlocks="${gDiskSize##*exactly }"
    gDiskSizeBlocks="${gDiskSizeBlocks%% *}"
    gDiskSize="${gDiskSize%% (*}"
    gDiskSizeNumber="${gDiskSize%%.*}"

    # Set dump folder
    #gDumpSubFolderName="Partition Info"
    gDumpFolderName="Partition bdisk Scan"
    gThisDiskDumpFolderName="${diskToRead}"
    gDumpFolder="${gDumpFolderDiskPartitionInfo}/${gDumpFolderName}/${gThisDiskDumpFolderName}"
    gDumpFolderHex="${gDumpFolderDiskPartitionInfo}/${gDumpFolderName}/${gThisDiskDumpFolderName}/hex"
    gDumpFolderDecoded="${gDumpFolderDiskPartitionInfo}/${gDumpFolderName}/${gThisDiskDumpFolderName}/decoded"
        
    # Set temporary HTML build string.
    gTmpHtmlString=""
    
    # Set temporary HTML build file to parse later.
    gTmpHtmlParseFile=""
}

#------------------------------------------------
# Procedure to read the disk block size
GetDiskBlockSize()
{
    # The disk's physical block size can be read from ioreg (thanks JrCs).
    deviceName=$( diskutil info /dev/$diskToRead | grep "Device / Media Name:" )
    deviceName="${deviceName##*:      }"
    deviceName="${deviceName% Media}"

    OIFS=$IFS; IFS=','
    devCharacteristic=$( ioreg -lw0 | grep "$deviceName" | grep "Device Characteristics" | sed 's/|* //g' )

    productName=""; blockSize=""
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
            #productName="${productName##*=}"
            gDiskPhysicalBlockSize="${blockSize##*=}"
            productName=""; blockSize=""
        fi
    done
    IFS=$OIFS

    if [ "$gDiskPhysicalBlockSize" == "" ]; then
        gDiskPhysicalBlockSize="Unknown"
    fi

    # However, the drive controller will emulate 512 byte sectors so we
    # will continue to use 512 bytes.
    gDiskBlockSize=512
 
    if [ "$gDiskBlockSize" == "" ]; then
        echo "Can't determine sector size of disk"
        echo "Please check to make sure /dev/$diskToRead exists"
        echo "Exiting"
        exit 1
    fi
    
    if [ $verboseMode -eq 1 ]; then
        echo "/dev/$diskToRead:   Physical Blocks: $gDiskPhysicalBlockSize, using Block Size: $gDiskBlockSize"
    fi
}

#------------------------------------------------
# Function to convert hex in little endian to Decimal
# Works for both 8 and 16 byte values
convertLittleEndianHexToDec()
{
    local passedHex="$1"
    local len="${#passedHex}"
    local converted=0 
    if [ $len -eq 8 ]; then
        (( converted = 16#$(echo $passedHex | sed 's,\(..\)\(..\)\(..\)\(..\),\4\3\2\1,g') ))
    elif [ $len -eq 16 ]; then
        (( converted = 16#$(echo $passedHex | sed 's,\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\),\8\7\6\5\4\3\2\1,g') ))
    fi
    echo $converted
}

#------------------------------------------------
# Function to convert from little endian
# Works for both 4 and 8 byte values
convertLittleEndianHex()
{
    local passedHex="$1"
    local len="${#passedHex}"
    local converted=0 
    if [ $len -eq 8 ]; then
        converted=$(echo $passedHex | sed 's,\(..\)\(..\)\(..\)\(..\),\4\3\2\1,g')
    elif [ $len -eq 4 ]; then
        converted=$(echo $passedHex | sed 's,\(..\)\(..\),\2\1,g')
    fi
    echo $converted
}

#------------------------------------------------
# Function to convert a hex digit to binary
HexDigitToBinary()
{
    local passedByte="$1"
    
    # Convert to uppercase
    passedByte=$(echo $passedByte | tr [[:lower:]] [[:upper:]])
            
    # Convert to bits
    passedByte=$( echo "obase=2;$passedByte" | bc )

    #Pad as a string length of 4. For example: 0006
    passedByte=$( printf %04d $passedByte )

    echo $passedByte
}

#------------------------------------------------
# Function to convert bytes to human readble unit
ConvertUnit()
{
    local passedNumber="$1"
    local numberLength=$( echo "${#passedNumber}")
    local convertedNumber
    
    if [ $numberLength -le 15 ] && [ $numberLength -ge 13 ]; then # TB
        convertedNumber=$(bc <<< 'scale=2; '$passedNumber'/1000000000000')"TB"
    elif [ $numberLength -le 12 ] && [ $numberLength -ge 10 ]; then # GB
        convertedNumber=$(bc <<< 'scale=2; '$passedNumber'/1000000000')"GB"
    elif [ $numberLength -le 9 ] && [ $numberLength -ge 7 ]; then # MB
        convertedNumber=$(bc <<< 'scale=2; '$passedNumber'/1000000')"MB"
    elif [ $numberLength -le 6 ] && [ $numberLength -ge 4 ]; then # KB
        convertedNumber=$(bc <<< 'scale=2; '$passedNumber'/100')"KB"  
    fi
    echo "$convertedNumber"
}

#------------------------------------------------
# Function to convert a CHS (Cylinder/Head/Sector)
# from 3 bytes.
ConvertCHS()
{
    local passedBytes="$1"
    local chsHead=""
    local chsSector=""
    local chsCylinder=""

    # Split Starting CHS hex bytes
    chsHeadBitsH=$(HexDigitToBinary ${passedBytes:0:1})
    chsHeadBitsL=$(HexDigitToBinary ${passedBytes:1:1})
    chsSectorBitsH=$(HexDigitToBinary ${passedBytes:2:1})
    chsSectorBitsL=$(HexDigitToBinary ${passedBytes:3:1})
    chsCylinderBitsH=$(HexDigitToBinary ${passedBytes:4:1})
    chsCylinderBitsL=$(HexDigitToBinary ${passedBytes:5:1})

    # Head is made from Head bits 0-8 (8 bits in total)
    chsHead=$chsHeadBitsH$chsHeadBitsL

    # Sector is made from Sector bits 0-5 (6 bits in total)
    chsSector=$chsSectorBitsH$chsSectorBitsL
    chsSector=$( echo ${chsSector:${#chsSector} - 6} )

    # Cylinder is made from Sector (original) bits 6-7 and Cylinder bits 0-7 (10 bits in total)
    chsCylinder=${chsSectorBitsH:0:2}$chsCylinderBitsH$chsCylinderBitsL
    
    # Convert binary to decimal
    chsHead=$( echo 'ibase=2;'$chsHead''|bc )
    chsSector=$( echo 'ibase=2;'$chsSector''|bc )
    chsCylinder=$( echo 'ibase=2;'$chsCylinder''|bc )    

    echo "$chsCylinder:$chsHead:$chsSector"
}

#------------------------------------------------
# Function to convert and hex string to ascii
# Is there a better way to do this??
ConvertHexToAscii()
{
    local passedHex="$1" 
    
    # Remove double zeros
    passedHex=$(echo "${passedHex//00/}")
    
    # Get length and halve it
    local len="${#passedHex}"
    len=$(( ${len}/2 ))
    
    # Loop through the hex string, taking each hex
    # digit pair, converting to ascii and build new string.
    nameString=""
    for (( s=0; s<$len; s++ ))
    do
       tmp=$(echo ${passedHex:0:2})
       nameString=${nameString}$(echo 0x$tmp | awk '{printf "%c\n", $1}')
       passedHex=$(echo "$passedHex" | sed 's/^.\{2\}//g')
    done
    
    echo "$nameString"
}

#------------------------------------------------
# Function to format a hex string GUID
# First three dash-delimited fields are little endian.
ComposeGUID()
{
    local passedHex="$1"   
    local partOne="${passedHex:0:8}"
    local partTwo="${passedHex:8:4}"
    local partThree="${passedHex:12:4}"
    local partFour="${passedHex:16:4}"
    local partFive="${passedHex:20:12}"
    
    partOne=$(convertLittleEndianHex ${partOne}) 
    partTwo=$(convertLittleEndianHex ${partTwo}) 
    partThree=$(convertLittleEndianHex ${partThree}) 
    
    local guid=$partOne"-"$partTwo"-"$partThree"-"$partFour"-"$partFive
    echo $guid
 }  

#------------------------------------------------
# Function to match single hex byte against list of known types
# I've only added the common ones added for now.
# See a complete list at http://www.win.tue.nl/~aeb/partitions/partition_types-1.html
matchPartitionType()
{
    local passedType="$1"  
    
    case "$passedType" in
        "00")     type="Empty" ;;
        "01")     type="FAT12" ;;
        "04")     type="FAT16" ;;
        "05")     type="Extended DOS" ;;
        "06")     type="FAT16" ;;
        "07")     type="NTFS" ;;
        "0b")     type="FAT32" ;;
        "0c")     type="FAT32(LBA)" ;;
        "0e")     type="FAT16(LBA)" ;;
        "0f")     type="Extended Partition(LBA)" ;;
        "27")     type="Windows Recovery Environment" ;;
        "82")     type="Linux Swap" ;;
        "83")     type="Linux" ;;
        "af")     type="HFS+" ;;
        "ab")     type="OSX Boot" ;;
        "ac")     type="Apple RAID" ;;
        "a5")     type="FreeBSD" ;;
        "a6")     type="OpenBSD" ;;
        "a9")     type="NetBSD" ;;
        "af")     type="HFS+" ;;
        "ee")     type="EFI Protective" ;;
           *)     type="$passedType" ;;
    esac
    echo $type
}

#------------------------------------------------
# Function to match GPT partition GUID types against list of known types
# See a complete list at http://en.wikipedia.org/wiki/GUID_Partition_Table
matchGPTPartitionTypeGuid()
{
    local passedGuid="$1"  
    
    case "$passedGuid" in
        "0657fd6d-a4ab-43c4-84e5-0933c84b4f4f")     type="Linux Swap" ;;
        "0fc63daf-8483-4772-8e79-3d69d8477de4")     type="Linux" ;;
        "426f6f74-0000-11aa-aa11-00306543ecac")     type="OSX Boot" ;;
        "48465300-0000-11aa-aa11-00306543ecac")     type="HFS+" ;;
        "7c3457ef-0000-11aa-aa11-00306543ecac")     type="APFS" ;;
        "52414944-0000-11aa-aa11-00306543ecac")     type="Apple RAID" ;;
        "52414944-5f4f-11aa-aa11-00306543ecac")     type="Offline RAID" ;;
        "53746f72-6167-11aa-aa11-00306543ecac")     type="Core Storage" ;;
        "55465300-0000-11aa-aa11-00306543ecac")     type="UFS" ;;
        "c12a7328-f81f-11d2-ba4b-00a0c93ec93b")     type="EFI System Partition" ;;
        "de94bba4-06d1-4d40-a16a-bfd50179d6ac")     type="Windows Recovery Environment" ;;
        "e3c9e316-0b5c-4db8-817d-f92df00215ae")     type="Microsoft Reserved Partition" ;;
        "ebd0a0a2-b9e5-4433-87c0-68b6b72699c7")     type="Windows Basic Data" ;;
        "6a898cc3-1dd2-11b2-99a6-080020736631")     type="ZFS" ;;
                                             *)     type="$passedGuid" ;;
    esac
    echo $type
}

#------------------------------------------------
# Function to read a Boot Record (could be master or extended).
# Each partition entry is inserted at the 1st element of an array in reverse order.
# This way the last entry added will always be first to be processed.
# Extended partition entries will then also be inserted at the 1st element.
BootRecordRead()
{
    local passedSector=$1
    local hexDump=""
    
    if [ $passedSector -eq 0 ];then
        gBootSectorType="MBR"
    else
        gBootSectorType="EBR"
    fi
    
    # Read record
    local bytesRead=$(sudo dd 2>/dev/null if="/dev/${diskToRead}" bs=$gDiskBlockSize count=1 skip=$passedSector | perl -ne '@a=split"";for(@a){printf"%02x",ord}' )
    
    if [ ! $bytesRead == "" ]; then

        # ----------------------------------------------------------------
        # Gather data
        winNTDiskSignature="${bytesRead:880:8}"                 # Bytes 440-443: the Windows NT disk signature (can also be used by linux)
        gPartitionEntriesToProcess=("${bytesRead:988:32}" "${gPartitionEntriesToProcess[@]}")    # Bytes 494-510: the fourth partition entry
        gPartitionEntriesToProcess=("${bytesRead:956:32}" "${gPartitionEntriesToProcess[@]}")    # Bytes 478-493: the third partition entry
        gPartitionEntriesToProcess=("${bytesRead:924:32}" "${gPartitionEntriesToProcess[@]}")    # Bytes 462-477: the second partition entry
        gPartitionEntriesToProcess=("${bytesRead:892:32}" "${gPartitionEntriesToProcess[@]}")    # Bytes 446-461: the first partition entry
        signature="${bytesRead:1020:4}"                         # Bytes 511-514: the signature 

        # ----------------------------------------------------------------
        # Convert any data
        signature=$(convertLittleEndianHex ${signature})

        BootRecordPrint $passedSector

        if [ $verboseMode -eq 1 ] && [ $verboseHex -eq 1 ]; then
            echo "---------------------------------------------"
            echo "Hex Dump: $gBootSectorType Boot Record"
            echo "---------------------------------------------"
            hexDump=$( sudo dd 2>/dev/null if="/dev/${diskToRead}" bs=$gDiskBlockSize count=1 skip=$passedSector | xxd -l$gDiskBlockSize )
            echo "$hexDump"
        fi
        
        if [ $writeFiles -eq 1 ]; then
            if [ "$hexDump" == "" ]; then
                hexDump=$( sudo dd 2>/dev/null if="/dev/${diskToRead}" bs=$gDiskBlockSize count=1 skip=$passedSector | xxd -l$gDiskBlockSize )
            fi
            #echo "$hexDump" > "${gDumpFolderHex}/${gBootSectorType}_Hex.txt" 
            echo "$hexDump" > "${gDumpFolderHex}/LBA${passedSector}_Hex.txt" 
        fi
        
        # Check for valid boot signature
        if [ $passedSector -eq 0 ]; then
        
            if [ $signature == "aa55" ]; then
            
                # Check for any known bootloader code
                FindMbrBootCode $bytesRead $signature
                
                return 0 # report success
                
            else
                echo "Master boot record does not contain a valid boot signature."
            
                # Check for Apple Partition Scheme.
                if [ $signature == "0000" ] && [ $passedSector -eq 0 ]; then
                    local checkApm=$(sudo dd 2>/dev/null if="/dev/${diskToRead}" bs=$gDiskBlockSize count=1 skip=1 | perl -ne '@a=split"";for(@a){printf"%02x",ord}' )
                    local apmSignature="${checkApm:0:4}"
                    if [ $apmSignature == "504d" ]; then
                        CollectInfoForOutput "Partition Map: Apple Partition Map"
                        echo "/dev/${diskToRead} looks to be using an Apple Partition Map."
                        echo "I don't know how to read that. Exiting"
                        
                        echo "          Found Apple Partition Map at ${diskToRead}. Skipping." >> "${logFile}"
                        
                        return 2 # report Apple Partition Scheme
                    fi
                fi
            fi
        else # not LBA 0 so will be an extended boot record
            return 0 # report success
        fi
    else
        return 1 # report error
    fi
}

#------------------------------------------------
BootRecordPrint()
{
    local passedSector="$1"
    
    if [ $verboseMode -eq 1 ]; then
    
        echo "---------------------------------------------"
        echo "$gBootSectorType Boot Record: Block $passedSector"
        echo "---------------------------------------------"

        # ----------------------------------------------------------------
        # Print data
        echo "$gBootSectorType Windows NT Signature: $winNTDiskSignature"
        echo "$gBootSectorType Partition Entry 1: ${gPartitionEntriesToProcess[0]}"
        echo "$gBootSectorType Partition Entry 2: ${gPartitionEntriesToProcess[1]}"
        echo "$gBootSectorType Partition Entry 3: ${gPartitionEntriesToProcess[2]}"
        echo "$gBootSectorType Partition Entry 4: ${gPartitionEntriesToProcess[3]}"
        echo "$gBootSectorType Signature: $signature"
        
    fi
    
    if [ $writeFiles -eq 1 ]; then
    
        #local dumpFile="${gDumpFolderDecoded}/${gBootSectorType}_Details.txt"
        local dumpFile="${gDumpFolderDecoded}/LBA${passedSector}_Details.txt"
        echo "$gBootSectorType Windows NT Signature: $winNTDiskSignature" >> "$dumpFile"
        echo "$gBootSectorType Partition Entry 1: ${gPartitionEntriesToProcess[0]}" >> "$dumpFile"
        echo "$gBootSectorType Partition Entry 2: ${gPartitionEntriesToProcess[1]}" >> "$dumpFile"
        echo "$gBootSectorType Partition Entry 3: ${gPartitionEntriesToProcess[2]}" >> "$dumpFile"
        echo "$gBootSectorType Partition Entry 4: ${gPartitionEntriesToProcess[3]}" >> "$dumpFile"
        echo "$gBootSectorType Signature: $signature" >> "$dumpFile"
        
    fi
    
    # Include this info in the overview file.
    CollectInfoForOutput " "
    CollectInfoForOutput "$gBootSectorType Partition Entry 1: ${gPartitionEntriesToProcess[0]}"
    CollectInfoForOutput "$gBootSectorType Partition Entry 2: ${gPartitionEntriesToProcess[1]}"
    CollectInfoForOutput "$gBootSectorType Partition Entry 3: ${gPartitionEntriesToProcess[2]}"
    CollectInfoForOutput "$gBootSectorType Partition Entry 4: ${gPartitionEntriesToProcess[3]}"
    CollectInfoForOutput " "
}

#------------------------------------------------
# Function to read the MBR/EBR Partition Entries
BootRecordPartitionEntriesRead()
{
    local passedLBA="$1"
    
    while [ ${#gPartitionEntriesToProcess[@]} -gt 0 ] && [ ${gPartitionEntriesToProcess[0]} != "" ] && [ $gFoundExtendedPartition -eq 0 ]
    do
        # Strip all zeros from partition entry string. If empty then we know not to process.
        zeroCheck=$( echo ${gPartitionEntriesToProcess[0]} | sed 's/[0]*//g' )
        
        # In the case of an empty (zero'd) partition entry, but it's active flag has been
        # set then stripping the zeros would still result in just 8. So let's also check
        # the length of resulting string to make sure it's longer than... 2
        if [ ! $zeroCheck == "" ] && [ ${#zeroCheck} -gt 2 ]; then

            # ----------------------------------------------------------------
            # Gather data
            brPeStatus="${gPartitionEntriesToProcess[0]:0:2}"                 # Byte  0      : the status - 80 = Active / 0 = Inactive / Anything else = Invalid
            brPeCHSAddrFirst="${gPartitionEntriesToProcess[0]:2:6}"           # Bytes 1-3    : the address of first CHS
            brPePartitionType="${gPartitionEntriesToProcess[0]:8:2}"          # Byte  4      : the partition type
            brPeCHSAddrLast="${gPartitionEntriesToProcess[0]:10:6}"           # Bytes 5-7    : the address of last CHS 
            brPeLbaFirst="${gPartitionEntriesToProcess[0]:16:8}"              # Bytes 8-11   : the LBA of the absolute first sector in partition
            brPeNumSectors="${gPartitionEntriesToProcess[0]:24:8}"            # Bytes 12-15  : the number of sectors in the partition

            # ----------------------------------------------------------------
            # Convert any data
            brPeStatusDec=$( printf "%d" 0x$brPeStatus )
            brPePartitionTypeMatched=$(matchPartitionType ${brPePartitionType})
            brPeLbaFirst=$(convertLittleEndianHexToDec ${brPeLbaFirst})
            brPeNumSectors=$(convertLittleEndianHexToDec ${brPeNumSectors})
            brStartingCHS=$(ConvertCHS $brPeCHSAddrFirst)
            brEndingCHS=$(ConvertCHS $brPeCHSAddrLast)
            
            # Calculate partition size
            brPartitionSize=$(( ${brPeNumSectors}*$gDiskBlockSize ))
            brPartitionSize=$(ConvertUnit $brPartitionSize)

            # Check if starting LBA is as expected, otherwise
            # we need to indicate a gap in partition structure.
            if [ ! $brPeLbaFirst == $gLbaCounter ] && [ ! $gBootSectorType == "EBR" ]; then
                gTmpBuildOutStringSize=$(( ${brPeLbaFirst}-$gLbaCounter ))
                BuildOutText "$gLbaCounter" " " "Space" " " " " " " "$gTmpBuildOutStringSize"
            fi

            # If reading an extended partition then we need to add the sector
            # address pointer to the original address found in the MBR record.
            if [ $gBootSectorType == "EBR" ] ; then
                if [ $brPePartitionType == "05" ]; then
                    brPeLbaFirst=$(( ${brPeLbaFirst}+$gFirstExtendedPartitionSector ))
                else
                    brPeLbaFirst=$(( ${brPeLbaFirst}+$gNextExtendedPartitionSector ))
                fi
            fi
            
            PrintPartitionEntry "$passedLBA"

            if [ ! $brPePartitionType == "ee" ]; then
            
                # Check for any known bootloader code for non GPT
                FindPbrBootCode $brPeLbaFirst
            else
                if [ $gBootSectorType == "MBR" ]; then

                    # Found partition type of EE which is a GPT
                    # Instead of processing now, we process after all the MBR partition entries.
                    
                    # Save LBA of GPT (normally 1) so we know where to read when we process the GPT.
                    #gEeStartingLBA=$brPeLbaFirst
                    # Deal with more than one EE partition.
                    gEeStartingLBA+=(${brPeLbaFirst})
                    
                    # Remember ending LBA of EE partition
                    gProtectedPartitionEnd=$brPeNumSectors

                fi
            fi
            
            # Don't output if GPT, Extended DOS or Extended partition (LBA)
            if [ ! $brPePartitionType = "ee" ] && [ ! $brPePartitionType = "05" ] && [ ! $brPePartitionType = "0f" ] ; then
                #BuildOutText "$brPeLbaFirst" "$brPeStatus" "$brPePartitionTypeMatched" " " " " "$stage1CodeDetected" "$brPeNumSectors"
                BuildOutText "$brPeLbaFirst" "$brPeStatus" "$brPePartitionType" " " " " "$stage1CodeDetected" "$brPeNumSectors"
                local tmp=$( echo "$brPePartitionTypeMatched" | tr -d ' ' )

                gLbaCounter=$((${brPeLbaFirst}+${brPeNumSectors}))
            fi
            
            # Was the record we just processed an extended partition type?
            # 05 indicates extended partition with CHS addressing
            # 0f indicates extended partition with LBA addressing
            # 85 indicates Linux extended partition
            # We only check extended partitions if the MBR of not a Hybrid MBR (more info http://www.rodsbooks.com/gdisk/hybrid.html)
            if [ $brPePartitionType == "05" ] || [ $brPePartitionType == "0f" ] || [ $brPePartitionType == "85" ] && [ ! "$mbrType" == "GPT Hybrid MBR" ]; then
                
                # Mark that the disk contains an extended partition.
                # This signals the script to recursively run the process of
                # calling BootRecordRead() and also this BootRecordPartitionEntriesRead()
                gFoundExtendedPartition=1
                
                # Remember the first sector LBA for initial extended partition    
                if [ $gFirstExtendedPartitionSector -eq 0 ]; then
                    gFirstExtendedPartitionSector=$brPeLbaFirst
                fi
                
                # Remember the first sector LBA for this extended partition
                gNextExtendedPartitionSector=$brPeLbaFirst
                
            else
                # No longer require the recursive call for extended partition. 
                gFoundExtendedPartition=0  
            fi
            
            # Remember 1st partition entry type for checking if GPT
            if [ $gBootSectorType == "MBR" ] && [ $gProtectiveMBRFlag -eq 0 ]; then
                brPePartitionTypeFirst=$brPePartitionType
                gProtectiveMBRFlag=1
            fi
        fi   
                    
        # Remove first element from the array (the one we've just read).
        # So the first element will be the next one to process.
        gPartitionEntriesToProcess=("${gPartitionEntriesToProcess[@]:1}")
            
    done
}

#------------------------------------------------
# Function to print the MBR/EBR Partition Entries
PrintPartitionEntry()
{
    local passedLBA="$1" # Used to indicate the LBA file to append data to.
    
    if [ $verboseMode -eq 1 ] || [ $writeFiles -eq 1 ]; then

        # Convert Active byte to human readable
        if [ $brPeStatusDec -eq 0 ]; then
            brPeActiveFlag="$brPeStatus (Inactive) " # Inactive
        elif [ $brPeStatusDec -gt 0 ] && [ $brPeStatusDec -lt 128 ]; then
            brPeActiveFlag="$brPeStatus (Invalid)" # Invalid
        elif [ $brPeStatusDec -eq 128 ]; then
            brPeActiveFlag="$brPeStatus (Active)" # Active
        fi
    
    fi
    
    if [ $verboseMode -eq 1 ]; then
    
        echo "---------------------------------------------"
        echo "$gBootSectorType Partition Entry: ${gPartitionEntriesToProcess[0]}"
        echo "---------------------------------------------"

        # ----------------------------------------------------------------
        # Print data
        echo "$gBootSectorType Partition Entry Status: $brPeActiveFlag"
        echo "$gBootSectorType Partition Entry Starting CHS: $brStartingCHS"   
        echo "$gBootSectorType Partition Entry Ending CHS: $brEndingCHS"   
        echo "$gBootSectorType Partition Entry Partition Type: $brPePartitionType (${brPePartitionTypeMatched})"
        echo "$gBootSectorType Partition Entry LBA of First Sector: $brPeLbaFirst"
        echo "$gBootSectorType Partition Entry No. Sectors in Partition: $brPeNumSectors"
        echo "$gBootSectorType Partition Size: $brPartitionSize"
    
        if [ ! "${stage1CodeDetected}" == "" ] && [ ! "${stage1CodeDetected}" == " " ]; then
            echo "Partition Loader: ${stage1CodeDetected}"
        fi
        
    fi
    
    if [ $writeFiles -eq 1 ]; then

        #local dumpFile="${gDumpFolderDecoded}/$gBootSectorType Partition Entry - ${gPartitionEntriesToProcess[0]}.txt" 
        local dumpFile="${gDumpFolderDecoded}/LBA${passedLBA}_Details.txt"
        echo "" >> "$dumpFile"
        echo "$gBootSectorType Partition Entry: ${gPartitionEntriesToProcess[0]}" >> "$dumpFile"
        echo "=====================================================" >> "$dumpFile"
        echo "$gBootSectorType Partition Entry Status: $brPeActiveFlag" >> "$dumpFile"
        echo "$gBootSectorType Partition Entry Starting CHS: $brStartingCHS" >> "$dumpFile"
        echo "$gBootSectorType Partition Entry Ending CHS: $brEndingCHS" >> "$dumpFile"
        echo "$gBootSectorType Partition Entry Partition Type: $brPePartitionType (${brPePartitionTypeMatched})" >> "$dumpFile"
        echo "$gBootSectorType Partition Entry LBA of First Sector: $brPeLbaFirst" >> "$dumpFile"
        echo "$gBootSectorType Partition Entry No. Sectors in Partition: $brPeNumSectors" >> "$dumpFile"
        echo "$gBootSectorType Partition Size: $brPartitionSize" >> "$dumpFile"
    
        if [ ! "${stage1CodeDetected}" == "" ] && [ ! "${stage1CodeDetected}" == " " ]; then
            echo "Partition Loader: ${stage1CodeDetected}" >> "$dumpFile"
        fi
        
    fi
}

#------------------------------------------------
# Procedure to read the GUID Partition Table Header
GPTHeaderRead()
{
    passedLba=$1
    
    local hexDump=""
    local bytesRead=$(sudo dd 2>/dev/null if="/dev/${diskToRead}" bs=$gDiskBlockSize count=1 skip=$passedLba | perl -ne '@a=split"";for(@a){printf"%02x",ord}' )
    
    if [ $verboseMode -eq 1 ] && [ $verboseHex -eq 1 ]; then
        echo "---------------------------------------------"
        echo "Hex Dump: $gGPTKind GPT Partition Table Header"
        echo "---------------------------------------------"
        hexDump=$( sudo dd 2>/dev/null if="/dev/${diskToRead}" bs=$gDiskBlockSize count=1 skip=$passedLba | xxd -l$gDiskBlockSize )
        echo "$hexDump"
    fi
    
    if [ $writeFiles -eq 1 ]; then
        if [ "$hexDump" == "" ]; then
            hexDump=$( sudo dd 2>/dev/null if="/dev/${diskToRead}" bs=$gDiskBlockSize count=1 skip=$passedLba | xxd -l$gDiskBlockSize )
        fi
        #echo "$hexDump" > "${gDumpFolderHex}/$gGPTKind GPT Header_Hex.txt" 
        echo "$hexDump" > "${gDumpFolderHex}/LBA${passedLba}_Hex.txt" 
    fi
    
    # ----------------------------------------------------------------
    # Gather data
    headerSignature="${bytesRead:0:16}"                     # Bytes 0-7    : the table header signature- string "EFI PART" (5452415020494645)
    headerRevisionNum="${bytesRead:16:8}"                   # Bytes 8-11   : the revision number
    headerSize="${bytesRead:24:8}"                          # Bytes 12-15  : the size in bytes of the GUID Partiton Table Header
    headerChecksum="${bytesRead:32:8}"                      # Bytes 16-19  : the CRC32 checksum of the GUID Partiton Table Header
    headerReservedOne="${bytesRead:40:8}"                   # Bytes 20-23  : must be zero
    headerCurrentLba="${bytesRead:48:16}"                   # Bytes 24-31  : the LBA that this structure is in
    headerBackupLba="${bytesRead:64:16}"                    # Bytes 32-39  : the LBA address of alternate table header
    headerLogicalBlockFirst="${bytesRead:80:16}"            # Bytes 40-47  : the first usable logical block
    headerLogicalBlockLast="${bytesRead:96:16}"             # Bytes 48-55  : the last usable logical block
    headerDiskGuid="${bytesRead:112:32}"                    # Bytes 56-71  : the disk GUID
    headerPartitionArrayStartingLba="${bytesRead:144:16}"   # Bytes 72-79  : the starting LBA of the partition array
    headerPartitionArrayEntries="${bytesRead:160:8}"        # Bytes 80-83  : the number of entries in the partition array
    headerPartitionArrayStructureSize="${bytesRead:168:8}"  # Bytes 84-87  : the size of the partition array structures
    headergPartitionEntryArrayChecksum="${bytesRead:176:8}" # Bytes 88-91  : the CRC32 of the partition entry array
    headerReservedTwo="${bytesRead:184:842}"                # Bytes 92-512 : reserved. Must be zero.

    # ----------------------------------------------------------------
    # Convert any little endian data
    headerSize=$(convertLittleEndianHexToDec ${headerSize})
    headerCurrentLba=$(convertLittleEndianHexToDec ${headerCurrentLba})
    headerBackupLba=$(convertLittleEndianHexToDec ${headerBackupLba})
    headerLogicalBlockFirst=$(convertLittleEndianHexToDec ${headerLogicalBlockFirst})
    headerLogicalBlockLast=$(convertLittleEndianHexToDec ${headerLogicalBlockLast})
    headerPartitionArrayStartingLba=$(convertLittleEndianHexToDec ${headerPartitionArrayStartingLba})
    headerPartitionArrayEntries=$(convertLittleEndianHexToDec ${headerPartitionArrayEntries})
    headerPartitionArrayStructureSize=$(convertLittleEndianHexToDec ${headerPartitionArrayStructureSize})
    headerDiskGuid=$(ComposeGUID ${headerDiskGuid})
    
    if [ "$gGPTKind" == "Primary" ]; then
        CollectInfoForOutput "Disk GUID:$headerDiskGuid"
        BuildHtmlString "Title2@Disk GUID:$headerDiskGuid"
    fi
}

#------------------------------------------------
# Procedure to print the GUID Partition Table Header
GPTHeaderPrint()
{
    local passedLBA="$1"
    
    if [ $verboseMode -eq 1 ]; then
        
        echo "---------------------------------------------"
        echo "$gGPTKind GPT Partition Table Header"
        echo "---------------------------------------------"
    
        # ----------------------------------------------------------------
        # Print data
        echo "Partition Table Revision: $headerRevisionNum"
        echo "Header Size: $headerSize"
        echo "Header Checksum: $headerChecksum"
    
        zeroCheck=$( echo $headerReservedOne | sed 's/[0]*//g' )
        if [ $zeroCheck="" ]; then
            echo "Middle Reserved Section (Should be zero): Yes"
        else
            echo "Middle Reserved Section: (NOT ZERO!): $headerReservedOne"
        fi
    
        echo "Header LBA: $headerCurrentLba"
        echo "Backup LBA: $headerBackupLba"
        echo "First Logical Block: $headerLogicalBlockFirst"
        echo "Last Logical Block: $headerLogicalBlockLast"
        echo "Disk GUID: $headerDiskGuid"  
        echo "Partition Array Starting LBA: $headerPartitionArrayStartingLba" 
        echo "Partition Array Entries: $headerPartitionArrayEntries"
        echo "Partition Array Structure Size: $headerPartitionArrayStructureSize"
        echo "Partition Entry Array Checksum: $headergPartitionEntryArrayChecksum" 

        zeroCheck=$( echo $headerReservedTwo | sed 's/[0]*//g' )
        if [ $zeroCheck="" ]; then
            echo "Ending Reserved Section (Should be zero): Yes"
        else
            echo "Ending Reserved Section: (NOT ZERO!): $headerReservedTwo"
        fi
        
    fi
    
    if [ $writeFiles -eq 1 ]; then
        
        #local dumpFile="${gDumpFolderDecoded}/$gGPTKind GPT Header Details.txt"
        local dumpFile="${gDumpFolderDecoded}/LBA${passedLBA}_Details.txt"
        echo "Partition Table Revision: $headerRevisionNum" >> "$dumpFile"
        echo "Header Size: $headerSize" >> "$dumpFile"
        echo "Header Checksum: $headerChecksum" >> "$dumpFile"
    
        zeroCheck=$( echo $headerReservedOne | sed 's/[0]*//g' )
        if [ $zeroCheck="" ]; then
            echo "Middle Reserved Section (Should be zero): Yes" >> "$dumpFile"
        else
            echo "Middle Reserved Section: (NOT ZERO!): $headerReservedOne" >> "$dumpFile"
        fi
    
        echo "Header LBA: $headerCurrentLba" >> "$dumpFile"
        echo "Backup LBA: $headerBackupLba" >> "$dumpFile"
        echo "First Logical Block: $headerLogicalBlockFirst" >> "$dumpFile"
        echo "Last Logical Block: $headerLogicalBlockLast" >> "$dumpFile"
        echo "Disk GUID: $headerDiskGuid"   >> "$dumpFile"
        echo "Partition Array Starting LBA: $headerPartitionArrayStartingLba" >> "$dumpFile"
        echo "Partition Array Entries: $headerPartitionArrayEntries" >> "$dumpFile"
        echo "Partition Array Structure Size: $headerPartitionArrayStructureSize" >> "$dumpFile"
        echo "Partition Entry Array Checksum: $headergPartitionEntryArrayChecksum" >> "$dumpFile"

        zeroCheck=$( echo $headerReservedTwo | sed 's/[0]*//g' )
        if [ $zeroCheck="" ]; then
            echo "Ending Reserved Section (Should be zero): Yes" >> "$dumpFile"
        else
            echo "Ending Reserved Section: (NOT ZERO!): $headerReservedTwo" >> "$dumpFile"
        fi
        
    fi
    
    # Note first logical block for later
    expectedStartingLba=$headerLogicalBlockFirst
}
 
#------------------------------------------------
# Procedure to read a GUID Partition Entry
GPTPartitionEntryRead()
{
    local passedBlock="$1"

    # ----------------------------------------------------------------
    # Gather data
    partitionTypeGuid="${passedBlock:0:32}"                     # Bytes 0-15   : the partition type GUID
    partitionUniqueGuid="${passedBlock:32:32}"                  # Bytes 16-31  : the unique partition GUID
    partitionStartingLba="${passedBlock:64:16}"                 # Bytes 32-39  : the starting LBA
    partitionEndingLba="${passedBlock:80:16}"                   # Bytes 40-47  : the ending LBA
    partitionAttr="${passedBlock:96:16}"                        # Bytes 48-55  : the UEFI reserved attribute bits
    partitionUnicodeStr="${passedBlock:112:144}"                # Bytes 56-127 : the partition name
    partitionEndReserve="${passedBlock:256:1}"                  # Byte  128    : reserved. Must be zero.

    # ----------------------------------------------------------------
    # Convert any data
    partitionTypeGuid=$(ComposeGUID ${partitionTypeGuid})
    partitionTypeGuid=$(matchGPTPartitionTypeGuid ${partitionTypeGuid})
    partitionUniqueGuid=$(ComposeGUID ${partitionUniqueGuid})
    partitionStartingLba=$(convertLittleEndianHexToDec ${partitionStartingLba})
    partitionEndingLba=$(convertLittleEndianHexToDec ${partitionEndingLba})
    partitionEndReserve=$(convertLittleEndianHexToDec ${partitionEndReserve})
    partitionUnicodeStr=$(ConvertHexToAscii ${partitionUnicodeStr})

    # Calculate partition size
    partitionSize=$(( ((${partitionEndingLba}+1)-$partitionStartingLba)*$gDiskBlockSize ))
    partitionSize=$(ConvertUnit $partitionSize)
       
    # Check for any known bootloader code
    FindPbrBootCode $partitionStartingLba
    
    if [ "$gGPTKind" == "Primary" ]; then
        CollectInfoForOutput "Partition GUID: $partitionUniqueGuid | Name: $partitionUnicodeStr"
    fi
}

#------------------------------------------------
# Procedure to read a GUID Partition Entry
GPTPartitionEntryPrint()
{
    local passedLBA="$1" # Used to indicate the LBA file to append data to.
    
    if [ $verboseMode -eq 1 ]; then
    
        echo "---------------------------------------------" 
        echo "$gGPTKind GPT Partition Entry"
        echo "---------------------------------------------"   
    
        # ----------------------------------------------------------------
        # Print data     
        echo "Partition Type GUID: $partitionTypeGuid"
        echo "Partition Unique GUID: $partitionUniqueGuid"
        echo "Partition Starting LBA: $partitionStartingLba"
        echo "Partition Ending LBA: $partitionEndingLba"
        echo "Partition UEFI Reserved Attributes: $partitionAttr"
        echo "Partition Name: $partitionUnicodeStr"
    
        zeroCheck=$( echo $partitionEndReserve | sed 's/[0]*//g' )
        if [ $zeroCheck="" ]; then
            echo "Partition Reserved Byte: OK"
        else
            echo "Partition Reserved Byte (NOT ZERO!): $partitionEndReserve"
        fi

        echo "Partition Size: $partitionSize"   
        if [ ! "${stage1CodeDetected}" == "" ] && [ ! "${stage1CodeDetected}" == " " ]; then
            echo "Partition Loader: ${stage1CodeDetected}"
        fi

    fi
    
    if [ $writeFiles -eq 1 ]; then

        #local dumpFile="${gDumpFolderDecoded}/$gGPTKind GPT Partition LBA ${partitionStartingLba}_Details.txt"
        local dumpFile="${gDumpFolderDecoded}/LBA${passedLBA}_Details.txt"
        echo "" >> "$dumpFile"
        echo "=====================================================" >> "$dumpFile"
        echo "" >> "$dumpFile"
        echo "Partition Type GUID: $partitionTypeGuid" >> "$dumpFile"
        echo "Partition Unique GUID: $partitionUniqueGuid" >> "$dumpFile"
        echo "Partition Starting LBA: $partitionStartingLba" >> "$dumpFile"
        echo "Partition Ending LBA: $partitionEndingLba" >> "$dumpFile"
        echo "Partition UEFI Reserved Attributes: $partitionAttr" >> "$dumpFile"
        echo "Partition Name: $partitionUnicodeStr" >> "$dumpFile"
    
        zeroCheck=$( echo $partitionEndReserve | sed 's/[0]*//g' )
        if [ $zeroCheck="" ]; then
            echo "Partition Reserved Byte: OK" >> "$dumpFile"
        else
            echo "Partition Reserved Byte (NOT ZERO!): $partitionEndReserve" >> "$dumpFile"
        fi

        echo "Partition Size: $partitionSize" >> "$dumpFile"
        if [ ! "${stage1CodeDetected}" == "" ] && [ ! "${stage1CodeDetected}" == " " ]; then
            echo "Partition Loader: ${stage1CodeDetected}" >> "$dumpFile"
        fi

    fi
}

#------------------------------------------------
# Procedure to read a GPT structure
ReadGPT()
{
    local passedLBA="$1"
    local hexDump=""

    # Set LbaCounter to start of GPT
    # This is needed with Hybrid MBR as the LbaCounter will have already been /
    # incremented when looping through the MBR partition entries. 
    gLbaCounter="$passedLBA"

    # GPT table header starts at LBA 1
    local bytesRead=$(sudo dd 2>/dev/null if="/dev/${diskToRead}" bs=$gDiskBlockSize count=1 skip=$passedLBA | perl -ne '@a=split"";for(@a){printf"%02x",ord}' )

    # Does the first 16 bytes have a GPT signature?
    signature="${bytesRead:0:16}"
    if [ "$signature" == "4546492050415254" ]; then

        # ----------
        # PRIMARY GPT
        # ----------

        # Set description for which end of the disk this is.
        gGPTKind="Primary"

        # Read the GPT header. Should be at LBA 1 but we
        # should use the value read from the MBR partition entry.   
        GPTHeaderRead $passedLBA

        gTmpBuildOutStringSize=$(( (${headerPartitionArrayStartingLba}-$passedLBA) ))
        BuildOutText "$passedLBA" " " " " "$gGPTKind GPT Header" " " " " "$gTmpBuildOutStringSize"
        GPTHeaderPrint "$passedLBA"

        # Make sure the header states that partition array entries exist.
        if [ $headerPartitionArrayEntries -gt 0 ]; then

            # Add one sector to LBA counter because we read the partition table entry array next.
            ((gLbaCounter++))

            # Find the size of the partition entry array.
            # Multiply the number of entries by the structure size ( Will be a minimum 16384 bytes ).
            gPartitionEntryArrayLen=$(( ${headerPartitionArrayEntries}*${headerPartitionArrayStructureSize} ))

            # Find how many blocks make up the partition entry array.
            # Divide the array length by the block size.
            gPartitionEntryArrayBlockCount=$(( ${gPartitionEntryArrayLen}/${gDiskBlockSize} ))

            gTmpBuildOutStringSize="$gPartitionEntryArrayBlockCount"
            BuildOutText "$headerPartitionArrayStartingLba" " " " " "$gGPTKind GPT Table" " " " " "$gTmpBuildOutStringSize"

            if [ $verboseMode -eq 1 ]; then
                echo "---------------------------------------------"
                echo "$gGPTKind GPT Partition Table Array Details"
                echo "---------------------------------------------"
                echo "Array Length:$gPartitionEntryArrayLen"
                echo "Array Block Count (${gDiskBlockSize} bytes):$gPartitionEntryArrayBlockCount"     
            fi
            
            if [ $writeFiles -eq 1 ]; then
                #local dumpFile="${gDumpFolderDecoded}/$gGPTKind GPT Table_Details.txt"
                local dumpFile="${gDumpFolderDecoded}/LBA${headerPartitionArrayStartingLba}_Details.txt"
                echo "Array Length:$gPartitionEntryArrayLen bytes" >> "${dumpFile}"
                echo "Array Block Count (${gDiskBlockSize} bytes):$gPartitionEntryArrayBlockCount" >> "${dumpFile}"
            fi

            # Read the complete primary partition entry array
            gPartitionEntryArray=$(sudo dd 2>/dev/null if="/dev/${diskToRead}" bs=$gDiskBlockSize skip=$headerPartitionArrayStartingLba count=$gPartitionEntryArrayBlockCount | perl -ne '@a=split"";for(@a){printf"%02x",ord}' )

            if [ $verboseMode -eq 1 ] && [ $verboseHex -eq 1 ]; then
                echo "---------------------------------------------"
                echo "Hex Dump: $gGPTKind GPT Partition Table Array"
                echo "---------------------------------------------"
                hexDump=$( sudo dd 2>/dev/null if="/dev/${diskToRead}" bs=$gDiskBlockSize skip=$headerPartitionArrayStartingLba count=$gPartitionEntryArrayBlockCount | xxd -l$gPartitionEntryArrayLen )
                echo "$hexDump"
            fi
            
            if [ $writeFiles -eq 1 ]; then
                if [ "$hexDump" == "" ]; then
                    hexDump=$( sudo dd 2>/dev/null if="/dev/${diskToRead}" bs=$gDiskBlockSize skip=$headerPartitionArrayStartingLba count=$gPartitionEntryArrayBlockCount | xxd -l$gPartitionEntryArrayLen )
                fi
                #echo "$hexDump" > "${gDumpFolderHex}/$gGPTKind GPT Table_Hex.txt"
                echo "$hexDump" > "${gDumpFolderHex}/LBA${headerPartitionArrayStartingLba}_Hex.txt" 
            fi
            
            # Add the length of the partition entry array of the LBA counter.
            gLbaCounter=$(( ${gLbaCounter}+$gPartitionEntryArrayBlockCount ))

            # Loop through the partition entry array to find each entry.
            numChars=$(( ${headerPartitionArrayStructureSize}*2 ))
            for (( x=0; x<=$gPartitionEntryArrayBlockCount; x++ ))
            do
                dataSteps=$(( ${numChars}*$x ))
                if [ ! "${gPartitionEntryArray:${dataSteps}:16}" == "0000000000000000" ]; then

                    # Read partiton entry, extract starting LBA, convert it to decimal and append to end with preceding colon.
                    local tmpA=${gPartitionEntryArray:${dataSteps}:$numChars}
                    local tmpB=$(convertLittleEndianHexToDec ${tmpA:64:16})
                    tmpA=${tmpA}:${tmpB}
                    local tmpC="$tmpC"$(printf "$tmpA\n")
                    tmpC="$tmpC \n" 
                fi
            done
                       
            # Sort (by number) on the end, colon delimited field.
            local tmpD=$( echo "$tmpC" | sort -n -k2 -t: )       

            # Remove appended colon and decimal number from partition entry, and build partition entry array.
            for string in $tmpD; do
                string=${string%:*}
                gGPTPartitionEntries+=(${string})
            done
            
            # Process each entry
            for (( x=0; x<${#gGPTPartitionEntries[@]}; x++ ))
            do
                gPartitionEntry=${gGPTPartitionEntries[$x]}
                GPTPartitionEntryRead $gPartitionEntry
                
                # Output to data file for creating output partition table
                # Check if starting LBA is as expected, otherwise
                # we need to indicate a gap in partition structure.

                if [ ! $partitionStartingLba == $gLbaCounter ]; then
                    gTmpBuildOutStringSize=$(( ${partitionStartingLba}-$gLbaCounter ))
                    BuildOutText "$gLbaCounter" " " " " "Space" " " " " "$gTmpBuildOutStringSize"
                fi

                gTmpBuildOutStringSize=$(( (${partitionEndingLba}-$partitionStartingLba)+1 ))
                BuildOutText "$partitionStartingLba" " " " " "$partitionTypeGuid" "$partitionUnicodeStr" "$stage1CodeDetected" "$gTmpBuildOutStringSize"
                local tmp=$( echo "$partitionTypeGuid" | tr -d ' ' )
   
                gLbaCounter=$((${partitionEndingLba}+1))
                
                GPTPartitionEntryPrint "$headerPartitionArrayStartingLba"

            done
        fi
        
                
        # ----------
        # BACKUP GPT
        # ----------
        
        # Set description for which end of the disk this is.
        gGPTKind="Backup"

        # Note the backup GPT Header LBA, before re-assigning the variable.
        gBackupGPTHeaderLba=$headerBackupLba
                
        # Read the backup GPT header.   
        GPTHeaderRead $headerBackupLba 

        # Make sure the header states the partition array entries exist.
        if [ $headerPartitionArrayEntries -gt 0 ]; then

            # Find the size of the partition entry array.
            # Multiply the number of entries by the structure size ( Will be a minimum 16384 bytes ).
            gBackupPartitionEntryArrayLen=$(( ${headerPartitionArrayEntries}*${headerPartitionArrayStructureSize} ))

            # Find how many blocks make up the partition entry array.
            # Divide the array length by the block size.
            gBackupPartitionEntryArrayBlockCount=$(( ${gBackupPartitionEntryArrayLen}/${gDiskBlockSize} ))

            # Calculate LBA for backup GPT partition array
            gBackupGPTPartitionTableArrayLba=$(( $gBackupGPTHeaderLba-$gBackupPartitionEntryArrayBlockCount ))
            
            if [ $verboseMode -eq 1 ]; then
                echo "---------------------------------------------"
                echo "$gGPTKind GPT Partition Table Array Details"
                echo "---------------------------------------------"
                echo "Array Length:$gBackupPartitionEntryArrayLen"
                echo "Array Block Count (${gDiskBlockSize} bytes):$gBackupPartitionEntryArrayBlockCount"     
            fi
            
            if [ $writeFiles -eq 1 ]; then
                #local dumpFile="${gDumpFolderDecoded}/$gGPTKind GPT Table_Details.txt"
                local dumpFile="${gDumpFolderDecoded}/LBA${gBackupGPTPartitionTableArrayLba}_Details.txt"
                echo "Array Length:$gBackupPartitionEntryArrayLen bytes" >> "${dumpFile}"
                echo "Array Block Count (${gDiskBlockSize} bytes):$gBackupPartitionEntryArrayBlockCount" >> "${dumpFile}"
            fi

            # Read the complete backup GPT partition entry array
            gBackupPartitionEntryArray=$(sudo dd 2>/dev/null if="/dev/${diskToRead}" bs=$gDiskBlockSize skip=$gBackupGPTPartitionTableArrayLba count=$gBackupPartitionEntryArrayBlockCount | perl -ne '@a=split"";for(@a){printf"%02x",ord}' )

            if [ $verboseMode -eq 1 ] && [ $verboseHex -eq 1 ]; then
                echo "---------------------------------------------"
                echo "Hex Dump: $gGPTKind GPT Partition Entry Array"
                echo "---------------------------------------------"
                hexDump=$( sudo dd 2>/dev/null if="/dev/${diskToRead}" bs=$gDiskBlockSize skip=$gBackupGPTPartitionTableArrayLba count=$gBackupPartitionEntryArrayBlockCount | xxd -l$gBackupPartitionEntryArrayLen )
                echo "$hexDump"
            fi

            if [ $writeFiles -eq 1 ]; then
                if [ "$hexDump" == "" ]; then
                    hexDump=$( sudo dd 2>/dev/null if="/dev/${diskToRead}" bs=$gDiskBlockSize skip=$gBackupGPTPartitionTableArrayLba count=$gBackupPartitionEntryArrayBlockCount | xxd -l$gBackupPartitionEntryArrayLen )
                fi
                #echo "$hexDump" > "${gDumpFolderHex}/$gGPTKind Partition Array_Hex.txt" 
                echo "$hexDump" > "${gDumpFolderHex}/LBA${gBackupGPTPartitionTableArrayLba}_Hex.txt" 
            fi

            # Output to data file for creating visual file            
            # Check if starting LBA is as expected, otherwise
            # we need to indicate a gap in partition structure
            if [ ! "$gBackupGPTPartitionTableArrayLba" == "$expectedStartingLba" ]; then
                gTmpBuildOutStringSize=$(( ${gBackupGPTPartitionTableArrayLba}-$gLbaCounter ))
                BuildOutText "$gLbaCounter" " " " " "Space" " " " " "$gTmpBuildOutStringSize"
            fi  
             
            # Before outputting the backup GPT header, we should output the backup GPT table array
            
            # Output the backup GPT table array.
            BuildOutText "$gBackupGPTPartitionTableArrayLba" " " " " "$gGPTKind GPT Table" " " " " "$gBackupPartitionEntryArrayBlockCount"

            # Output the backup GPT header.
            gTmpBuildOutStringSize=$(( ${headerPartitionArrayStartingLba}-$headerLogicalBlockLast ))
            BuildOutText "$gBackupGPTHeaderLba" " " " " "$gGPTKind GPT Header" " " " " "$gTmpBuildOutStringSize"

            # Loop through the backup GPT partition entry array to find each entry.
            numChars=$(( ${headerPartitionArrayStructureSize}*2 ))
            for (( x=0; x<=$gBackupPartitionEntryArrayBlockCount; x++ ))
            do
                dataSteps=$(( ${numChars}*$x ))
                if [ ! "${gBackupPartitionEntryArray:${dataSteps}:16}" == "0000000000000000" ]; then 
                    gPartitionEntry="${gBackupPartitionEntryArray:${dataSteps}:$numChars}"
                    GPTPartitionEntryRead $gPartitionEntry

                    GPTPartitionEntryPrint "$gBackupGPTPartitionTableArrayLba"
                fi
            done

            # Don't print the header until after all the backup partition entries
            GPTHeaderPrint "$gBackupGPTHeaderLba"

        fi
    #else
    #    echo "Error. The GPT table header signature at LBA:$gLbaCounter is incorrect: $signature"
    #    echo "$bytesRead"
    fi
}

#------------------------------------------------
FindMbrBootCode()
{
    local passedBytes="$1"
    local passedSignature="$2"
    stage0CodeDetected=""

    if [ "$passedSignature" == "aa55" ]; then

        # Check the first 16-bytes are not empty
        if [ "${passedBytes:0:32}" == "00000000000000000000000000000000" ] ; then 
           stage0CodeDetected=" "
        else
        
            case "${passedBytes:210:6}" in
                "0a803c") stage0CodeDetected="boot0" ;;
                "0b807c") stage0CodeDetected="boot0hfs" ;;
                "742b80") stage0CodeDetected="boot0md" ;;
                "ee7505") stage0CodeDetected="boot0md (dv1)" ;; #was dmazar v1
                "742b80") stage0CodeDetected="boot0md (dbw2)" ;; # was dmazar boot0workV2
                "a300e4") stage0CodeDetected="boot0 (dt)" ;; # was dmazar timing
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

            # If code is not yet identified then check for known structures
            if [ "$stage0CodeDetected" == "" ]; then
                if [ "${passedBytes:164:16}" == "4641543332202020" ] ; then #FAT32
                    if [ "${passedBytes:6:16}" == "4d53444f53352e30" ]; then
                        stage0CodeDetected="FAT32 MSDOS 5.0 Boot"
                    fi
                    if [ "${passedBytes:262:20}" == "4e6f6e2d73797374656d" ]; then
                        stage0CodeDetected="FAT32 Non-System"
                    fi
                fi
                if [ "${passedBytes:108:16}" == "4641543136202020" ]; then #FAT16
                    if [ "${passedBytes:6:16}" == "4d53444f53352e30" ]; then
                        stage0CodeDetected="FAT16 MSDOS 5.0 Boot"
                    fi
                    if [ "${passedBytes:206:20}" == "4e6f6e2d73797374656d" ]; then
                        stage0CodeDetected="FAT16 Non-System"
                    fi
               fi
            fi
        
            # Check of existence of the string GRUB as it can
            # appear at a different offsets depending on version.
            if [ "$stage0CodeDetected" == "" ]; then
                if [[ "${passedBytes}" == *475255422000* ]]; then
                   stage0CodeDetected="GRUB"
                   # TO DO - How to detect grub version?
                fi
            fi

            # If code is not yet identified then mark as Unknown.
            if [ "$stage0CodeDetected" == "" ]; then
               stage0CodeDetected="Unknown"
            fi

        fi
    fi

    if [ $verboseMode -eq 1 ]; then
        echo "Bootloader Code: $stage0CodeDetected" 
    fi
    
    if [ $writeFiles -eq 1 ]; then
        echo "Bootloader Code: $stage0CodeDetected" >> "${gDumpFolderDecoded}/${gBootSectorType}_Details.txt"
    fi
}

#------------------------------------------------
FindPbrBootCode()
{
    local passedLba="$1"
    stage1CodeDetected=""
    local pbrBytesToGrab=1024

    local bytesRead=$(sudo dd 2>/dev/null if="/dev/${diskToRead}" bs=$gDiskBlockSize count=1 skip=$passedLba | perl -ne '@a=split"";for(@a){printf"%02x",ord}' )
    
    if [ $verboseMode -eq 1 ] && [ $verboseHex -eq 1 ]; then
        echo "---------------------------------------------"
        echo "Hex Dump: Partition at LBA${passedLba}"
        echo "---------------------------------------------"
        local pbrHexDump=$( sudo dd 2>/dev/null if="/dev/${diskToRead}" bs=$gDiskBlockSize count=1 skip=$passedLba | xxd -l$gDiskBlockSize )
        echo "$pbrHexDump"
    fi
    
    if [ $writeFiles -eq 1 ]; then
        if [ "$pbrHexDump" == "" ]; then
            local pbrHexDump=$( sudo dd 2>/dev/null if="/dev/${diskToRead}" bs=$gDiskBlockSize count=1 skip=$passedLba | xxd -l$gDiskBlockSize )
        fi
        #echo "$pbrHexDump" > "${gDumpFolderHex}/Partition BootSector LBA ${passedLba}_Hex.txt" 
        echo "$pbrHexDump" > "${gDumpFolderHex}/LBA${passedLba}_Hex.txt" 
    fi
    
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
                                    stage1CodeDetected="FAT32 Non System"
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
            stage1CodeDetected="Unknown"
        fi
    else
        #stage1CodeDetected="None"
        stage1CodeDetected=" "
    fi
}

#------------------------------------------------
# Procedure to check MBR partition entry types and
# determine if type is MBR, GPT Protected MBR or GPT Hybrid MBR
FindBRType()
{
    mbrType=""
    declare -a partType
    if [ ${gBootSectorType} == "MBR" ]; then
        
        # Build a list of partition types as described in the partition entries.
        for (( t=0; t<${#gPartitionEntriesToProcess[@]}; t++ ))
        do
            zeroCheck=$( echo ${gPartitionEntriesToProcess[$t]} | sed 's/[0]*//g' )
            if [ ! $zeroCheck == "" ]; then
                partType+=(${gPartitionEntriesToProcess[$t]:8:2})
            fi
        done

        # Is there just a single populated entry?
        if [ ${#partType[@]} -eq 1 ]; then
            if [ ${partType[0]} == "ee" ]; then
                mbrType="GPT Protective MBR"
            fi
  
        # Is there more than 1 populated entry? 
        elif [ ${#partType[@]} -gt 1 ]; then
            # Loop through and see if the type is ee
            local typeEEexists=0
            for (( t=0; t<${#partType[@]}; t++ ))
            do
                if [ ${partType[$t]} == "ee" ]; then
                    typeEEexists=1
                fi
            done
            if [ $typeEEexists -eq 1 ]; then
                mbrType="GPT Hybrid MBR"
            fi
        fi
        if [ "$mbrType" == "" ]; then
            mbrType="MBR"
        fi
    elif [ ${gBootSectorType} == "EBR" ]; then
        mbrType="EBR"
    fi
}
 
#------------------------------------------------
BuildOutTextHeader()
{
     # Set Outfile Header Line Text
    if [ "$mbrType" == "MBR" ]; then
        gFinalDumpTable="$gFinalDumpTable"$(printf "==========@=@=========@==========@=========\n")
        gFinalDumpTable="$gFinalDumpTable \n" 
        gFinalDumpTable="$gFinalDumpTable"$(printf "LBA Start@A@Type@LoaderCode@Size LBA\n")
        gFinalDumpTable="$gFinalDumpTable \n" 
        gFinalDumpTable="$gFinalDumpTable"$(printf "==========@=@=========@==========@=========\n")
        gFinalDumpTable="$gFinalDumpTable \n" 
    elif [ "$mbrType" == "GPT Protective MBR" ]; then
        gFinalDumpTable="$gFinalDumpTable"$(printf "=========@=========@========@==========@=========\n")
        gFinalDumpTable="$gFinalDumpTable \n" 
        gFinalDumpTable="$gFinalDumpTable"$(printf "LBA Start@Type@GPT Name@LoaderCode@Size LBA\n")
        gFinalDumpTable="$gFinalDumpTable \n" 
        gFinalDumpTable="$gFinalDumpTable"$(printf "=========@=========@========@==========@=========\n")
        gFinalDumpTable="$gFinalDumpTable \n" 
    elif [ "$mbrType" == "GPT Hybrid MBR" ]; then
        gFinalDumpTable="$gFinalDumpTable"$(printf "=========@=@=============@========@========@==========@=========\n")
        gFinalDumpTable="$gFinalDumpTable \n"
        gFinalDumpTable="$gFinalDumpTable"$(printf "LBA Start@A@MBR Type@GPT Type@GPT Name@LoaderCode@Size LBA\n")
        gFinalDumpTable="$gFinalDumpTable \n" 
        gFinalDumpTable="$gFinalDumpTable"$(printf "=========@=@=============@========@========@==========@=========\n")
        gFinalDumpTable="$gFinalDumpTable \n" 
    fi
} 

# Compose the collected data in to a presentable output.
#------------------------------------------------
BuildOutText()
{
    local passedLbaStart="$1"
    local passedActive="$2"
    local passedMbrType="$3"
    local passedGptType="$4"
    local passedGptName="$5"
    local passedLoader="$6"
    local passedSize="$7"
    local composedLine=""

    # Convert Active
    if [ "$passedActive" == "80" ]; then
        local tmpActive="*"
    else
        local tmpActive=" "
    fi

    # Only convert MbrType field if length of 2 (hex byte) and not
    # anything else like Space or GPT Hybrid MBR for example.
    if [ ${#passedMbrType} -eq 2 ]; then
        local matchedMbrType=$(matchPartitionType ${passedMbrType})
    else
        local matchedMbrType=${passedMbrType}
    fi

    #------------- GPT Protective MBR ------------

    if [ "$mbrType" == "GPT Protective MBR" ]; then
    
        # The MBR will be passed in the matchedMbrType var
        if [ ! "$matchedMbrType" == "" ] && [ ! "$matchedMbrType" == " " ]; then
            if [ "$passedLbaStart" == "0" ]; then
                local tmp="MBR"
            else
                local tmp="$matchedMbrType"
            fi
        else
            local tmp="$passedGptType"
        fi
        composedLine="${passedLbaStart}@${tmp}@${passedGptName}@${passedLoader}@${passedSize}"

        if [ $createHtml -eq 1 ]; then
            if [ "$passedLbaStart" == "0" ]; then
                BuildHtmlParseFileNew "${passedLbaStart}" " " "MBR" "${tmp}" "${passedGptName}" "${passedLoader}" "${passedSize}"
            else
                # Assume here that there's a single MBR partition table entry of EE and it spans the length for every partition.
                BuildHtmlParseFileNew "${passedLbaStart}" " " "ee" "${tmp}" "${passedGptName}" "${passedLoader}" "${passedSize}"
            fi
        fi

    #------------- MBR / EBR ------------

    elif [ "$mbrType" == "MBR" ] || [ "$mbrType" == "EBR" ]; then
    
        if [ ! "$matchedMbrType" == "Space" ] && [ ! "$matchedMbrType" == "MBR" ] && [ ! "$matchedMbrType" == "EBR" ]; then
            composedLine="${passedLbaStart}@${tmpActive}@${matchedMbrType} (${passedMbrType})@${passedLoader}@${passedSize}"
        else
            composedLine="${passedLbaStart}@${tmpActive}@${matchedMbrType}@${passedLoader}@${passedSize}"
        fi
        
        if [ $createHtml -eq 1 ]; then
            BuildHtmlParseFileNew "${passedLbaStart}" "${tmpActive}" "${passedMbrType}" " " "${matchedMbrType} (${passedMbrType})" "${passedLoader}" "${passedSize}"
        fi

    #------------- GPT Hybrid MBR ------------

    elif [ "$mbrType" == "GPT Hybrid MBR" ]; then

        # Is there content in the MBR field
        if [ ! "$matchedMbrType" == "" ] && [ ! "$matchedMbrType" == " " ]; then
        
            # If current MBR starting LBA = 0 then print MBR type and loader code.
            if [ "$passedLbaStart" == "0" ]; then
                composedLine="${passedLbaStart}@${tmpActive}@MBR@${passedGptType}@${passedGptName}@${passedLoader}@${passedSize}"
                
                if [ $createHtml -eq 1 ]; then
                    BuildHtmlParseFileNew "${passedLbaStart}" "${tmpActive}" "MBR" "${passedGptType}" "${passedGptName}" "${passedLoader}" "${passedSize}"
                fi
            
            else  # Current MBR starting LBA is not 0. 
                
                # Only accept actual partition entries and not Spaces.
                if [ ! "${passedMbrType}" == "Space" ]; then
 
                    # We want to save content now and not print until reading GPT later.
                    hybridLbaStart+=("${passedLbaStart}")
                    hybridActive+=("${tmpActive}")
                    hybridType+=("${passedMbrType}")
                    hybridSize+=("${passedSize}")
                fi
            fi

        else # No content found in the MBR field. We must be reading GPT content.

            # Check to see if the current GPT starting LBA=1 as this will be the GPT so we can enter MBR Part Type as GPT
            if [ "$passedLbaStart" == "1" ]; then
                composedLine="${passedLbaStart}@${tmpActive}@EFI Protective (ee)@${passedGptType}@${passedGptName}@${passedLoader}@${passedSize}"

                if [ $createHtml -eq 1 ]; then
                    BuildHtmlParseFileNew "${passedLbaStart}" "${tmpActive}" "ee" "${passedGptType}" "${passedGptName}" "${passedLoader}" "${passedSize}"
                fi

            else  # Current GPT starting LBA is not 1. 

                # Before printing GPT contents, check for correctly synced hybrid MBR partition entries.
                # Check to see if the current starting LBA & size for GPT matches a saved starting LBA & size from MBR.
                local mbrGptMatch=1000
                for (( m=0; m<${#hybridLbaStart[@]}; m++ ))
                do
                    if [ "$passedLbaStart" == ${hybridLbaStart[$m]} ] && [ "$passedSize" == ${hybridSize[$m]} ]; then
                        mbrGptMatch=$m
                        break
                    fi
                done

                # did we find a matching MBR entry?
                if [ $mbrGptMatch -ne 1000 ]; then
                    local tmp=$(matchPartitionType ${hybridType[$mbrGptMatch]})
                    composedLine="${passedLbaStart}@${hybridActive[$mbrGptMatch]}@${tmp} (${hybridType[$mbrGptMatch]})@${passedGptType}@${passedGptName}@${passedLoader}@${passedSize}"
                    
                    if [ $createHtml -eq 1 ]; then
                        BuildHtmlParseFileNew "${passedLbaStart}" "${hybridActive[$mbrGptMatch]}" "${tmp} (${hybridType[$mbrGptMatch]})" "${passedGptType}" "${passedGptName}" "${passedLoader}" "${passedSize}"
                    fi
                        
                    # Remove the matched element from the arrays.
                    # Doing this allows a final check at the end of the script for un-matched, MBR->GPT partitions. 
                    # Technique from http://www.thegeekstuff.com/2010/06/bash-array-tutorial/
                    hybridLbaStart=("${hybridLbaStart[@]:0:$mbrGptMatch}" "${hybridLbaStart[@]:$(($mbrGptMatch + 1))}")
                    hybridActive=("${hybridActive[@]:0:$mbrGptMatch}" "${hybridActive[@]:$(($mbrGptMatch + 1))}")
                    hybridType=("${hybridType[@]:0:$mbrGptMatch}" "${hybridType[@]:$(($mbrGptMatch + 1))}")
                    hybridSize=("${hybridSize[@]:0:$mbrGptMatch}" "${hybridSize[@]:$(($mbrGptMatch + 1))}")
                    
                else # Did not find a matching Starting LBA and size from MBR to GPT.
                    composedLine="${passedLbaStart}@${tmpActive}@ @${passedGptType}@${passedGptName}@${passedLoader}@${passedSize}"
                    
                    if [ $createHtml -eq 1 ]; then
                        
                        # Check if the current LBA is before the End of the GPT protected partition.
                        # If yes, then set the ee colour to the MBR Partition Table column.
                        if [ $passedLbaStart -lt $gProtectedPartitionEnd ]; then
                            BuildHtmlParseFileNew "${passedLbaStart}" "${tmpActive}" "ee" "${passedGptType}" "${passedGptName}" "${passedLoader}" "${passedSize}"
                        else
                            BuildHtmlParseFileNew "${passedLbaStart}" "${tmpActive}" "xx" "${passedGptType}" "${passedGptName}" "${passedLoader}" "${passedSize}"
                        fi
                    fi
                fi
            fi
        fi
    fi

    #------------- Append to String ------------

    # Append content from this procedure to a string which we print at the end.
    if [ ! "$composedLine" == "" ]; then
        gFinalDumpTable="$gFinalDumpTable"$(printf "$composedLine\n")
        gFinalDumpTable="$gFinalDumpTable \n" 
    fi
}

# Add the data to the temporary html parsing file.
#
# blackosx - Note to self.. Maybe re-do this section?
# This is a right headf**k to follow as I'm passing this data
# originally intended for stdout and re-using it for creating
# the html file too... Seemed a good idea originally, but now
# it's a bit convoluted!
#------------------------------------------------
BuildHtmlParseFileNew()
{
    local passedLbaStart="$1"     # The Starting LBA.             Example: 0
    local passedActive="$2"       # Is partition active           Example: *
    local passedMbrType="$3"      # The Partition Map type        Example: if LBA=0 then Currently Forced to MBR (used to be GPT Protective MBR, GPT Hybrid MBR or MBR)
                                  #                                        if LBA>0 then hex code for MBR partition type: 07, ee, af, ac, ab etc. 
                                  #                                        or xx for an unprotected (non ee) MBR entry (for hybrid GPT/MBR only)
    local passedGptType="$4"      # Human readable of GUID code   Example: Primary GPT Header / EFI System Partition / HFS+ / Space
    local passedGptName="$5"      # Unicode Str for current LBA   Example: BootVolume / MountainLion / Recovery HD 
    local passedLoader="$6"       # Name of any detected code     Example: boot0 (dt) / Boot1h / Apple EFI
    local passedSize="$7"         # LBA Length                    Example: 409600
    
    local tmpTableType=""
    local tmpTablePeVal=""
    local strippedTableType=""
    local tmpSize=""
    
    #echo "passedLbaStart: $passedLbaStart"
    #echo "passedActive:   $passedActive"
    #echo "passedMbrType:  $passedMbrType"
    #echo "passedGptType:  $passedGptType"
    #echo "passedGptName:  $passedGptName"
    #echo "passedLoader:   $passedLoader"
    #echo "passedSize:     $passedSize"
    #echo "-----"

    # *** TO DO - Re-Work this section as it's messy!!! ***

    # Convert Height to a pixel height - Using the calculated square root.
    local tableHeight=$( echo "${passedSize}" | awk '{printf "%.0f\n",sqrt($1)}' )
    local tableHeight=$(( ${tableHeight}/150 )) 
    if [ "$passedGptType" == "Space" ]; then
        # Set the minimum height of a 'space' cell in the HTML table.
        tableHeight=$(( ${tableHeight}+5 ))
    else
         # Sets the minimum height of a 'populated' cell in the HTML table.
        tableHeight=$(( ${tableHeight}+10 ))
    fi
    
    # Check for the MBR Type
    if [ $passedLbaStart == "0" ]; then
        tmpTableType="$passedMbrType"
        passedGptName="$passedMbrType"
    elif [ "$passedMbrType" == "EBR" ]; then
        tmpTableType="$passedMbrType"
        passedGptName="$passedMbrType"
    else       
        # passedMbrType could be for example: Space (Space) or FAT16(LBA) (0e)
        # Check for partition type hex byte. 
        if [[ "${passedMbrType}" == *\(* ]]; then
            # Take the last item after a space, discarding the parenthesis, leaving the hex byte.
            local tmp=$( echo "${passedMbrType##* }" | tr -d '()' )
        else
            tmp="$passedMbrType"
        fi

        # Does the field have a length of 2?
        if [ ${#tmp} -eq 2 ]; then
            tmpTablePeVal="$passedMbrType"

            # Check for a GPT name. If none, then check MBR disk so can use partition type name
            if [ "$passedGptName" == "" ] || [ "$passedGptName" == " " ]; then
                if [ "$passedMbrType" == "MBR" ] || [ "$passedMbrType" == "EBR" ]; then
                    passedGptName=$(matchPartitionType ${passedMbrType})
                fi
            fi
        fi

        # Convert MBR hex type ID to Human readble name
        passedMbrType=$(matchPartitionType ${passedMbrType})

        if [ "$passedGptType" == "" ] || [ "$passedGptType" == " " ]; then
            tmpTableType="$passedMbrType"
        else
            tmpTableType="$passedGptType"

            # CHEAT - CAN I ADD THIS PROPERLY?
            if [ "$passedGptType" == "Primary GPT Header" ]; then
                tmpTablePeVal="ee"
            fi
        fi 
    fi

    if [ "$passedGptName" == "" ] || [ "$passedGptName" == " " ]; then
        #if [ ! "$passedGptType" == "Space" ]; then
            passedGptName="$passedGptType"
        #fi
    fi

    # Remove all non-alphanumeric chars (for example HFS+ to HFS)
    strippedTableType=$( echo "$tmpTableType" | sed 's/[^a-zA-Z0-9]//g' )

    # Check size and only print on table if large than 8MB (16384 * 512)
    if [ "$passedSize" -gt 16384 ]; then
        # Calculate Size as Human readble
        tmpSize=$((${passedSize}*${gDiskBlockSize}))
        tmpSize=$(ConvertUnit $tmpSize)
        tmpSize="(${tmpSize})"
    else
        tmpSize=""
    fi

    # Check for any large space on MBR
    # Print on table any space larger than 1GB (1048576 * 512) ** Maybe make this number larger?
    if [ "$passedMbrType" == "Space" ] && [ "$passedSize" -gt 1048576 ] ; then
        passedGptName="Unused"
    fi

    # Check for any large space on GPT
    # Print on table any space larger than 1GB (1048576 * 512) ** Maybe make this number larger?
    if [ "$passedGptType" == "Space" ] && [ "$passedSize" -gt 1048576 ] ; then
        passedGptName="Unused"
    fi
    
    # Have we an MBR hex code?
    if [ ! "$tmpTablePeVal" == "" ]; then
        tmpPeType="$strippedTableType"
    fi

    BuildHtmlString "TableHgt@${tableHeight}"
    BuildHtmlString "TableLba@${passedLbaStart}"
    BuildHtmlString "TableAct@${passedActive}"
    BuildHtmlString "TablePeTyp@${tmpPeType}"
    BuildHtmlString "TablePeVal@${tmpTablePeVal}"
    BuildHtmlString "TableTyp@${strippedTableType}"
    BuildHtmlString "TableNme@${passedGptName}"
    BuildHtmlString "TableSze@${tmpSize}"
    BuildHtmlString "TableLdr@${passedLoader}"    
}

# ---------------------------------------------------------------------------------------
BuildHtmlString()
{
    local passedString="$1"
    
    if [ $createHtml -eq 1 ]; then
        gTmpHtmlString="$gTmpHtmlString"$(printf "$passedString\n")
        gTmpHtmlString="$gTmpHtmlString \n" 
    fi
}

#------------------------------------------------
CollectInfoForOutput()
{
    local passedTextLine="$1"

    if [ ! "$passedTextLine" == "" ]; then
        gGatheredInfo="$gGatheredInfo"$(printf "$passedTextLine\n")
        gGatheredInfo="$gGatheredInfo \n" 
    fi
}

#------------------------------------------------
DumpInfo()
{
    local outFile="${diskToRead}-overview.txt"

    #------------------------------------------------
    # Print result
    if [ ! "$gGatheredInfo" == "" ] && [ ! "$gFinalDumpTable" == "" ]; then
    
        if [ $dumpOverview -eq 1 ]; then
            # to stdout
            echo "---------------------------------------------"
            printf "$gGatheredInfo"
            printf "$gFinalDumpTable" | column -t -s@
        fi
        
        # Write to file also.
        printf "$gGatheredInfo" >> "${gDumpFolderDiskPartitionInfo}/${outFile}"
        printf "\n" >> "${gDumpFolderDiskPartitionInfo}/${outFile}"
        printf "$gFinalDumpTable" | column -t -s@ >> "${gDumpFolderDiskPartitionInfo}/${outFile}"
        
    else
        echo "There was an error collecting data." >> "${gDumpFolderDiskPartitionInfo}/${outFile}"
    fi
}


#================================================
# Main
#================================================

Initialise
GetDiskBlockSize

echo "          Scanning & interpreting partition table for ${diskToRead}" >> "${logFile}"

if [ $writeFiles -eq 1 ]; then

    # Create dump folders
    if [ ! -d "$gDumpFolderHex" ]; then
        echo "Creating $gDumpFolderHex"
        mkdir -p "$gDumpFolderHex"
    fi
    if [ ! -d "$gDumpFolderDecoded" ]; then
        echo "Creating $gDumpFolderDecoded"
        mkdir -p "$gDumpFolderDecoded"
    fi
else
    if [ ! -d "$gDumpFolder" ]; then
        echo "Creating $gDumpFolderDiskPartitionInfo"
        mkdir -p "$gDumpFolderDiskPartitionInfo"
    fi
fi

# Set temporary HTML build file to parse later.
if [ $createHtml -eq 1 ]; then
    gTmpHtmlParseFile="$TEMPDIR"/html_build_file_${diskToRead}.txt
fi

# Collect and use some initial info.
CollectInfoForOutput "/dev/${diskToRead}"
CollectInfoForOutput "${gDiskName}"
CollectInfoForOutput "Physical Block (sector) size: ${gDiskPhysicalBlockSize} bytes"
CollectInfoForOutput "Using Block (sector) size: ${gDiskBlockSize} bytes"
CollectInfoForOutput "Total Number of Blocks: ${gDiskSizeBlocks}"
CollectInfoForOutput "Total Disk Size: ${gDiskSize}"
if [ "$gDiskPhysicalBlockSize" != "Unknown" ]; then
    BuildHtmlString "Title@${gDiskName} (${gDiskPhysicalBlockSize} byte physical sectors)"
else
    BuildHtmlString "Title@${gDiskName}"
fi
BuildHtmlString "Title@${gDiskSize} (${gDiskSizeBlocks} Blocks * ${gDiskBlockSize} byte sectors)"

# Read the disk master boot record - Beginning at LBA 0
BootRecordRead $gLbaCounter
returnValue=$?

if [ $returnValue -eq 0 ]; then # Success - MBR Exists

    # What type MBR is it?
    FindBRType

    # Now we know the Boot Record type, we can write the out text header.
    BuildOutTextHeader

    if [[ "$mbrType" == *GPT* ]]; then
        CollectInfoForOutput "Partition Map: GUID Partition Table"
        BuildHtmlString "Title2@GUID Partition Table"
    else
        CollectInfoForOutput "Partition Map: MBR Partition Table"
        BuildHtmlString "Title2@MBR Partition Table"
    fi

    # Report size of Boot Record as 1.. Can I calculate this?
    BuildOutText "0" " " "$mbrType" " " " " "$stage0CodeDetected" "1"
                
    # Set next LBA to look for data (used to find gaps/unused space).
    ((gLbaCounter++))

    # Dissect and print contents of the partition entries
    BootRecordPartitionEntriesRead "0"
    
    # If an extended partition is discovered then a scan needs
    # to be performed for each subsequent extended partition found.
    # Note: This script is set to not scan logical partitions if MBR is a Hybrid MBR.
    while [ $gFoundExtendedPartition -eq 1 ]
    do
        # We've now acted upon finding an extended partition so reset this flag.
        gFoundExtendedPartition=0
        
        # Read the extended partition boot record passing the absolute LBA of the first sector.
        BootRecordRead $brPeLbaFirst
        returnValue=$?
        
        if [ $returnValue -eq 0 ]; then # Success - EBR Exists
        
            # What type MBR is it?
            FindBRType

            BuildOutText "$brPeLbaFirst" " " "$mbrType" " " " " " " "1"
            
            # Correct LBA counter
            gLbaCounter=$(( ${brPeLbaFirst}+1 ))
    
            # Dissect and print contents of the partition entries
            BootRecordPartitionEntriesRead "$brPeLbaFirst"
            
        else
            echo "No EBR exists for $diskToRead at sector $brPeLbaFirst"
        fi
    done
    
    # is there a GPT to read?
    if [ "$mbrType" == "GPT Protective MBR" ] || [ "$mbrType" == "GPT Hybrid MBR" ]; then
    
        # Handle the fact there may be more than one MBR partition entry of type EE
        for (( e=0; e<${#gEeStartingLBA[@]}; e++ ))
        do
            ReadGPT ${gEeStartingLBA[$e]}
        done
    fi
    
    #Note: Disk scanning has now finished
    
    #Was there any unused space on the disk?
    if [ "$mbrType" == "MBR" ] || [ "$mbrType" == "EBR" ]; then
        gLastRepotedUsedBlock=$((${brPeLbaFirst}+${brPeNumSectors}))
        unusedSpace=$((${gDiskSizeBlocks}-${gLastRepotedUsedBlock}))
    else
        gLastRepotedUsedBlock=$((${gBackupGPTHeaderLba}+${gTmpBuildOutStringSize}))
        unusedSpace=$((${gDiskSizeBlocks}-${gLastRepotedUsedBlock}))
    fi
    
    if [ $unusedSpace -gt 0 ]; then
        #echo "Unused Space:$unusedSpace"
        unusedSpaceStart=$((${gLastRepotedUsedBlock}+1))
        #echo "Start of Free Space:$unusedSpaceStart"
        unusedSpaceLength=$((${gDiskSizeBlocks}-${unusedSpaceStart}))
        #echo "Length of Free Space:$unusedSpaceLength"
        unusedSpaceBytes=$((${unusedSpaceLength}*${gDiskBlockSize}))
        unusedSpaceSize=$(ConvertUnit $unusedSpaceBytes)
        #echo "Size of Free Space:$unusedSpaceSize"
        CollectInfoForOutput "Unused Size: ${unusedSpaceSize}"
        
        if [ "$mbrType" == "MBR" ] || [ "$mbrType" == "EBR" ]; then
            BuildOutText "$unusedSpaceStart" " " "Space" " " " " " " "$unusedSpaceLength"
        else
            BuildOutText "$unusedSpaceStart" " " " " "Space" " " " " "$unusedSpaceLength"
        fi
    fi

    # Check for any incorrectly synced MBR->GPT Hybrid Partitions
    if [ "$mbrType" == "GPT Hybrid MBR" ] && [ ${#hybridLbaStart[@]} -gt 0 ]; then

        # Remove any entries indicating gaps in the partition, named as Space.
        for (( m=0; m<${#hybridLbaStart[@]}; m++ ))
        do
            if [ "${hybridType[$m]}" == "Space" ]; then
                hybridLbaStart=("${hybridLbaStart[@]:0:$m}" "${hybridLbaStart[@]:$(($m + 1))}")
                hybridActive=("${hybridActive[@]:0:$m}" "${hybridActive[@]:$(($m + 1))}")
                hybridType=("${hybridType[@]:0:$m}" "${hybridType[@]:$(($m + 1))}")
                hybridSize=("${hybridSize[@]:0:$m}" "${hybridSize[@]:$(($m + 1))}")
            fi
        done
    
        if [ ${#hybridLbaStart[@]} -gt 0 ]; then
            # The hybridX arrays had an element removed after a match was found.
            # Any remaining elements that were not matched against a GPT partition are therefore out of sync.     
            
            #echo "*** Warning. The following MBR partition entries are not in sync with the GPT."
            gFinalDumpTable="$gFinalDumpTable"$(printf "*** Warning. The following MBR partition entries are not in sync with the GPT.\n")
            gFinalDumpTable="$gFinalDumpTable \n" 
            
            for (( m=0; m<${#hybridLbaStart[@]}; m++ ))
            do
                #echo "|${hybridLbaStart[$m]}|${hybridActive[$m]}|${hybridType[$m]}|${hybridSize[$m]}|" 
                gFinalDumpTable="$gFinalDumpTable"$(printf "${hybridLbaStart[$m]}@${hybridActive[$m]}@${hybridType[$m]}@ @ @ @${hybridSize[$m]}\n")
                gFinalDumpTable="$gFinalDumpTable \n" 
                
                BuildHtmlString "SyncErrorLba@${hybridLbaStart[$m]}"
                BuildHtmlString "SyncErrorAct@${hybridActive[$m]}"
                BuildHtmlString "SyncErrorTyp@${hybridType[$m]}"
                BuildHtmlString "SyncErrorSze@${hybridSize[$m]}"
            done
        fi
    fi
    
    # Create Output
    DumpInfo
    
    if [ $createHtml -eq 1 ]; then
        # Write the temporary build parsing file to disk
        if [ ! "$gTmpHtmlString" == "" ]; then
            echo "$gTmpHtmlString" > "$gTmpHtmlParseFile"
        fi
        # The build html script is now called from DarwinDumper.sh
    fi

elif [ $returnValue -eq 1 ]; then 
    echo "Failed to read $diskToRead at LBA$gLbaCounter"
fi