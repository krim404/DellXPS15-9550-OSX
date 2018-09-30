#!/usr/bin/env bash
#
# Script to read ACPI tables directly from memory.
# Requires memory map & pmem.kext
#
# Copyright (C) 2010 org.darwinx86.app <darwindumper@yahoo.com>
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
# blackosx - Aug 2014
#
# Testers: kynnder, Maniac10, joe75, .::Fabio::., Andy Vandijck.
#

VERS="0.46"

AUTO=1
DBG=0

#------------------------------------------------
# Function to convert a hex string to ascii
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
# Function to convert hex to Decimal
# Works for both 2, 8 and 16 byte values
convertHexToDec()
{
    local passedHex="$1"
    local len="${#passedHex}"
    local converted=0 
    if [ $len -eq 2 ]; then
        (( converted = 16#$(echo $passedHex | sed 's,\(..\),\1,g') ))
    elif [ $len -eq 8 ]; then
        (( converted = 16#$(echo $passedHex | sed 's,\(..\)\(..\)\(..\)\(..\),\1\2\3\4,g') ))
    elif [ $len -eq 16 ]; then
        (( converted = 16#$(echo $passedHex | sed 's,\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\),\1\2\3\4\5\6\7\8,g') ))
    fi
    echo $converted
}

#------------------------------------------------
ReadRSDPStructureOne()
{
    local passedBytes="$1"
    # Read data structure
    # Checksum          [1]
    # OEMID             [6]
    # Revision          [1]
    # RSDT Address      [4]
    rsdpChecksum="${passedBytes:0:2}" # Not checking this
    rsdpOemId="${passedBytes:2:12}"
    rsdpRevision="${passedBytes:14:2}"
    rsdtAddress="${passedBytes:16:8}"
}

#------------------------------------------------
ReadRSDPStructureTwo()
{
    local passedBytes="$1"
    # If revision 2 or newer then read extended data structre
    # Length            [4]
    # XSDT Address      [8]
    # Extended checksum [1]
    # Reserved          [3]
    rsdtLength="${passedBytes:24:8}"
    xsdtAddress="${passedBytes:32:16}"
    rsdtExtendedChecksum="${passedBytes:48:2}" # Not checking this
    rsdtReserved="${passedBytes:50:6}"
}

#------------------------------------------------
ResolvePointer()
{
    local passedBytes="$1"
    local passedBytesDec=$(convertHexToDec "$passedBytes")
    local skipBytes=$(( $passedBytesDec / $blockSize ))
    local bytesRead=$( sudo dd 2>/dev/null if=/dev/pmem bs=$blockSize count=64 skip=$skipBytes | perl -ne '@a=split"";for(@a){printf"%02x",ord}' )
    [ $DBG -eq 1 ] && printf "$passedBytes | $skipBytes | $bytesRead \n" >> "$DEBUGDIR/debug_resolve_rsdp_pointers.txt"
    if [ "${bytesRead:0:8}" == "52534454" ]; then #RSDT
        echo "RSDT"
    elif [ "${bytesRead:0:8}" == "58534454" ]; then #XSDT
        echo "XSDT"
    else
        echo ""
    fi
}

#------------------------------------------------
ReverseBytes()
{
    local passedBytes="$1"
    local reversedBytes=""
    for (( v=${#passedBytes}; v>=0; v-=2 ))
    do
        reversedBytes="${reversedBytes}${passedBytes:$v:2}"
    done
    echo "$reversedBytes"
}

#------------------------------------------------
# Function to total up sum of hex bytes
# and return lowest byte
ValidateRsdpChecksum()
{
    local passedBytes="$1"
    local allBytesLen="${#passedBytes}"
    # Add all bytes together
    local byteValueDec=0
    local sumOfBytes=0
    for (( c=0; c<$allBytesLen; c+=2 ))
    do
        byteValueDec=$(convertHexToDec "${passedBytes:$c:2}")
        sumOfBytes=$(( $sumOfBytes + $byteValueDec ))
        #printf "$c | $byteValueDec | $sumOfBytes\n" >> ~/Desktop/checksum.txt
    done
    #printf "$passedBytes | $allBytesLen | $sumOfBytes | " >> ~/Desktop/checksum.txt
    sumOfBytesHex=$( echo "obase=16; $sumOfBytes" | bc )
    #printf "$sumOfBytesHex | ${sumOfBytesHex: -2}\n" >> ~/Desktop/checksum.txt
    echo "${sumOfBytesHex: -2}"
}

#------------------------------------------------
dumpTable()
{
    local tableAddrHex="$1"
    local blockSize=8
    tableId=""
    
    # Convert to Decimal
    local tableAddrDec=$(convertHexToDec ${tableAddrHex})
 
    # Find table signature (includes length)
    # read first block of memory at address $tableAddrDec
    local skipValue=$(( $tableAddrDec / $blockSize ))
    local readBytes=$( sudo dd 2>/dev/null if=/dev/pmem bs=$blockSize count=1 skip=$skipValue | perl -ne '@a=split"";for(@a){printf"%02x",ord}' )

    if [ $DBG -eq 1 ]; then
        if [ ! -d "$DEBUGDIR/debug_table_signatures" ]; then
            mkdir "$DEBUGDIR/debug_table_signatures"
        fi
        sudo dd 2>/dev/null if=/dev/pmem bs=$blockSize count=1 skip=$skipValue > "$DEBUGDIR/debug_table_signatures"/$tableAddrHex
        echo "$readBytes" > "$DEBUGDIR/debug_table_signatures"/$tableAddrHex.txt
    fi

    #if [ ! "${readBytes:0:8}" == "00000000" ]; then
    # Check for invalid table signature by existence of byte 00.
    local zeroCheck=$( echo "${readBytes:0:8}" | grep 00 )
    if [ "$zeroCheck" == "" ]; then

        tableSignature=$(ConvertHexToAscii ${readBytes:0:8})  
        local tableLength=$(convertLittleEndianHexToDec ${readBytes:8:8})

         # Check length and don't process if larger than 1MB. ** Could make this smaller.
        if [ $tableLength -le 1048576 ]; then

            # Read table
            # How many blocks do we need to read?
            local nBlocks=$(( $tableLength / $blockSize ))
            # Include extra block to ensure we get more than we need
            nBlocks=$(( $nBlocks + 1 ))
            # Calculate entry point
            skipValue=$(( $tableAddrDec / $blockSize ))
            # Read memory block
            data=$( sudo dd 2>/dev/null if=/dev/pmem bs=$blockSize count=$nBlocks skip=$skipValue | perl -ne '@a=split"";for(@a){printf"%02x",ord}' )
            # Trim only the number of bytes (x2 as each byte is two characters) that we need
            acpiTableData="${data:0:$(( $tableLength * 2 ))}"

            # Find table ID
            tableId=$(ConvertHexToAscii ${acpiTableData:32:16})
    
            # Prepare filename for writing.
            if [ ! "$tableId" == "" ]; then
                if [ "$tableSignature" == "RSDT" ] || [ "$tableSignature" == "XSDT" ]; then
                    LogToFile "${gLogIndent}Found Table: $tableSignature at $tableAddrHex | Length: $tableLength | Table ID: $tableId"
                else
                    LogToFile "${gLogIndent}    Found Table: $tableSignature at $tableAddrHex | Length: $tableLength | Table ID: $tableId"
                fi
                local fileName="${tableSignature}-${tableId}"
            else
                LogToFile "${gLogIndent}    Found Table: $tableSignature at $tableAddrHex | Length: $tableLength"
                local fileName="${tableSignature}"
            fi
        
            # Write table to file
            echo "$acpiTableData" | xxd -r -p > "$outDir"/"$fileName".aml
        else
            LogToFile "${gLogIndent}    Table data at 0x$tableAddrHex exceeds 1MB! Presuming invalid. Skipping"
        fi
    else
        LogToFile "${gLogIndent}    $tableAddrHex points to an invalid table signature data"
    fi
}

#------------------------------------------------
ProcessTables()
{
    local passedPointer="$1"

    # Create save directory
    outDir="${SAVECONTAINERDIR}/$passedPointer"
    if [ ! -d "$outDir" ]; then
        #LogToScreenAndFile ""
        #LogToScreenAndFile "Creating save directory $outDir"
        mkdir "$outDir"
    fi
    
    # Let's dump the table
    dumpTable "$passedPointer"

    if [ "$tableSignature" == "RSDT" ] || [ "$tableSignature" == "XSDT" ]; then
        # We can now extract further tables by reading contents
        #
        # ACPI Table headers are all 36 bytes in length
        # So for the XSDT, if we strip the first 36 bytes, then each
        # subsequent 16 bytes will be addresses to ACPI tables
        remainingTableAddresses="${acpiTableData:72}"
     
        # Get length of remaining data
        dataLen="${#remainingTableAddresses}"
        
        if [ "$tableSignature" == "RSDT" ]; then
            bytes=8
        else
            bytes=16
        fi

        numTables=$(( $dataLen / $bytes ))
        LogToFile "${gLogIndent}    Number of tables in $tableSignature = $numTables"
        local facsAddress=""
        local dsdtAddress=""
        for (( t=0; t<$numTables; t++ ))
        do
            tableAddr="${remainingTableAddresses:$(( $t * $bytes )):$bytes}"
            tableAddr=$(ReverseBytes $tableAddr)
            if [ ! "$tableAddr" == "0000000000000000" ] && [ ! "$tableAddr" == "00000000" ]; then
                dumpTable "$tableAddr"
            
                if [ "$tableSignature" == "FACP" ]; then
                    # The FACP table provides the address of the FACS and DSDT tables
                    if [ $bytes -eq 8 ]; then # ACPI v1.0 - RSDT
                        facsAddress="${data:72}"
                        dsdtAddress="${facsAddress:8}"
                        # Get just first 4 bytes
                        facsAddress="${facsAddress:0:8}"
                        dsdtAddress="${dsdtAddress:0:8}"
                    elif [ $bytes -eq 16 ]; then # ACPI v2.0 and newer - XSDT
                        facsAddress="${data:264}"
                        dsdtAddress="${facsAddress:16}"
                        # Get just first 8 bytes
                        facsAddress="${facsAddress:0:16}"
                        dsdtAddress="${dsdtAddress:0:16}"
                    fi
                    # Reconstruct address
                    facsAddress=$(ReverseBytes $facsAddress)
                    dsdtAddress=$(ReverseBytes $dsdtAddress)
                fi

                if [ "$tableSignature" = "SSDT" ]; then
                    if [ "$tableId" == "CpuPm" ] || [ "$tableId" == "CpuSsdt" ]; then
                        ssdtExtraTables="$data"
                    fi
                fi
            else
                LogToFile "${gLogIndent}    skipping table with address $tableAddr"
            fi
        done
        
        if [ "$facsAddress" ]; then
            # Is it just zeros? strip all zeros and see what's left.
            addressExist=$( echo "$facsAddress" | sed 's/0//g' )
            [ $addressExist ] && dumpTable "$facsAddress"
        fi
        if [ "$dsdtAddress" ]; then
            dumpTable "$dsdtAddress"
        fi
        if [ "$ssdtExtraTables" ]; then
            
            # Check data for hex bytes 5C000853534454 as these
            # seem common for original CpuPm tables and are not
            # in SSDT PM tables created by revogirls/Pikes script.
            count=$( echo "$ssdtExtraTables" | grep -o "5c000853534454" | wc -l )
            if [ $count -gt 0 ]; then
            
                # Scan data for bytes OOOC
                # If found, extract 16 bytes after
                # First 8 = address, 2nd 8 = length
                count=$( echo "$ssdtExtraTables" | grep -o "000c" | wc -l )
                if [ $count -gt 0 ]; then
                    LogToFile "${gLogIndent}    Found extra SSDT tables"
                    for (( t=1; t<=$count; t++ ))
                    do
                        # Find position of signature
                        sigPos=$( echo "$ssdtExtraTables" | awk '{print index($0,"000c")}' )
                        # After finding the first address, record the number of bytes to the next address.
                        # Should be 37. Calculated as 16 bytes (2 chars each) + bytes 000c (4 chars) + 1
                        [ $t -le 2 ] && byteStep=$sigPos
                        # Strip signature (and 000c) from memoryblock so we now look at first byte after
                        ssdtExtraTables="${ssdtExtraTables:$(( $sigPos + 3 ))}"
                        # Check num bytes to next address just in case byte 000c appear later in hex string.
                        if [ $sigPos -eq $byteStep ]; then
                            extraTableAddress=$(ReverseBytes "${ssdtExtraTables:0:8}")
                            dumpTable "$extraTableAddress"
                        fi           
                    done
                fi
            else
                LogToFile "${gLogIndent}    SSDT CpuPM table does not appear original. Skipping"
                if [ $DBG -eq 1 ]; then
                    echo "$ssdtExtraTables" > "$DEBUGDIR/debug_table_signatures"/ssdt_cpupm_ExtraTables.txt
                fi
            fi
        fi
        
        # Delete any invalid dump directories
        if [ -d "$outDir" ]; then
            # Check if save directory contains three or less files.
            # A single file would occur if current RSDT/XSDT pointed to invalid tables.
            # A valid system requires at least RSDT/XSDT, DSDT and FACP
            local fileCount=$( ls "$outDir" | wc -l )
            if [ $fileCount -le 3 ]; then
                LogToFile "${gLogIndent}    Deleting invalid save directory"
                rm -r "$outDir"
            else
                # Check for DSDT file
                findDSDTAml=$(find "$outDir" -type f -name DSDT*.aml)
                if [ ! "$findDSDTAml" == "" ]; then
                     # Disassemble DSDT to see if it's valid or not.
                     LogToFile "${gLogIndent}    Disassembling DSDT to check size"
                    "$iasl" -d "$findDSDTAml" &> /dev/null
                    findDSDTDsl=$(find "$outDir" -type f -name DSDT*dsl)
                    if [ ! "$findDSDTDsl" == "" ]; then
                        # Check the file size of the disassambled file
                        # If it's invalid then delete the dump directory.
                        local fileSizeBytes=$(wc -c "$findDSDTDsl" | awk '{print $1}')
                        if [ $fileSizeBytes -lt 1024 ]; then
                            LogToFile "${gLogIndent}    Disassembled DSDT is invalid at $fileSizeBytes bytes. Deleting directory"
                            rm -r "$outDir"
                        else
                            LogToFile "${gLogIndent}    Disassembled DSDT is $fileSizeBytes bytes. Table is valid"
                            rm "$findDSDTDsl"
                        fi
                    fi
                fi
            fi
        fi
    fi
}

#------------------------------------------------
LogToScreenAndFile()
{
    echo "$1"
    echo "$1" >> "$gLogFile"
}

#------------------------------------------------
LogToFile()
{
    echo "$1" >> "$gLogFile"
}

# ======================================================================== 
# ======================================================================== 
# MAIN


if [ "$1" == "" ]; then
    exit 1
fi 

SAVECONTAINERDIR="$1"
#AMLDIR="$SAVECONTAINERDIR"
DEBUGDIR="$SAVECONTAINERDIR/Debug"
memoryMapFile="$gDumpFolderMemory/FirmwareMemoryMap.txt"
separatorLine="---------------------------------------------------------------"

declare -a memoryMap
declare -a acpiAddressRegionsStart
declare -a acpiAddressRegionsFinish
declare -a rxsdtPointers
driverLoaded=0
blockSize=8

#echo $separatorLine
#echo "dumpACPIfromMem v$VERS"

if [ ! -d "$DEBUGDIR" ]; then
    mkdir -p "$SAVECONTAINERDIR"
fi
    
if [ $DBG -eq 1 ]; then
    LogToScreenAndFile "Debug is on."
    if [ ! -d "$DEBUGDIR" ]; then
        mkdir -p "$DEBUGDIR"
    fi
fi
#if [ $AUTO -eq 1 ]; then
#    LogToScreenAndFile "Auto mode is on."
#fi
#echo $separatorLine

# ======================================================================== 
# Check for existing log file and ask to overwrite it
#if [ -f "$gLogFile" ]; then
#    echo "dumpACPIfromMem_log.txt exists"
#    echo "[o]verwrite it or e[x]it?"
#    read UserInput
#    while [ "$UserInput" != "o" ] && [ "$UserInput" != "x" ]
#	do
#	    echo "[o]verwrite it or e[x]it?"
#	    read UserInput
#	done
#    if [ "$UserInput" == "x" ]; then
#        LogToScreenAndFile "User Exit."
#        exit 0
#    else
#        > "$gLogFile"
#    fi
#fi

#LogToFile $separatorLine
#LogToFile "dumpACPIfromMem v$VERS"
#LogToFile $separatorLine

# ======================================================================== 
# Find RSDP pointer.
if [ -f "$memoryMapFile" ]; then

    # ========================================================================
    # Read memory map for begin and ending address ranges of ACPI_NVS regions.
    AppendAddrAndResetVars()
    {
        acpiAddressRegionsStart+=( "$tmpStart" )
        acpiAddressRegionsFinish+=( "$tmpEnd" )
        tmpStart=""
        tmpEnd=""
        nvs=0
        [ $DBG -eq 1 ] && LogToFile "Appended addresses and reset vars."
    }
    
    OIFS="$IFS"; IFS=$'\n'
    memoryMap=( $( cat "$memoryMapFile" ))
    
    #LogToFile $separatorLine
    #LogToFile "Memory Map"
    #LogToFile $separatorLine
    
    regionsBegin=0
    tmpStart=""
    tmpEnd=""
    nvs=0
        
    # Check for sequential ACPI_NVS - available - ACPI_recl regions.
    # Or even sequential ACPI_recl - ACPI_NVS regions.
    for ((a=0; a<"${#memoryMap[@]}"; a++))
    do
        if [ $regionsBegin -eq 1 ]; then
            #LogToFile "${memoryMap[$a]}"
            # Have we already found an ACPI_NVS region?
            if [ ! "$tmpStart" == "" ]; then
                [ $DBG -eq 1 ] && LogToFile "a=$a : Now checking ${memoryMap[$a]:0:11} at ${memoryMap[$a]:11:16}"
                
                # Only if not currently reading an 'available' region - process if, then, else
                [ ! "${memoryMap[$a]:0:11}" == "available  " ] && \
                
                    # Check for reclaimable or ACPI_NVS region and adjust end address to match the end of this region.
                    if [ "${memoryMap[$a]:0:11}" == "ACPI_recl  " ] || [ "${memoryMap[$a]:0:11}" == "ACPI_NVS   " ]; then
                        [ $DBG -eq 1 ] && LogToFile "a=$a : ${memoryMap[$a]:0:11} != available, but record end ${memoryMap[$a]:30:16} "
                        
                        # Did we previously read an ACPI_NVS address?
                        if [ $nvs -eq 1 ] && [  "${memoryMap[$a]:0:11}" == "ACPI_NVS   " ]; then
                            [ $DBG -eq 1 ] && LogToFile "Found another ACPI_NVS - retaining original end ${tmpEnd}"
                            AppendAddrAndResetVars
                            ((a--))
                        else
                            tmpEnd="${memoryMap[$a]:30:16}"                
                            # If we find a reclaimable or ACPI_NVS region then stop looking for more.
                            [ "${memoryMap[$a]:0:11}" == "ACPI_recl  " ] || [ "${memoryMap[$a]:0:11}" == "ACPI_NVS   " ] && AppendAddrAndResetVars
                        fi
                    else
                        [ $DBG -eq 1 ] && LogToFile "a=$a : ${memoryMap[$a]:0:11} != available, but also not reading recl or NVS  "
                        AppendAddrAndResetVars
                    fi
                    [ $DBG -eq 1 ] && LogToFile "out"
                
                # Region read is 'available' so flag last region read was not ACPI_NVS
                nvs=0
            else
                # Have we found an ACPI_NVS or ACPI_recl region? If yes, temporarily record the start and end addresses.
                if [ "${memoryMap[$a]:0:11}" == "ACPI_NVS   " ] || [ "${memoryMap[$a]:0:11}" == "ACPI_recl  " ]; then
                    
                    # Remember we currently have ACPI_NVS
                    [ "${memoryMap[$a]:0:11}" == "ACPI_NVS   " ] && nvs=1
                    
                    [ $DBG -eq 1 ] && LogToFile "a=$a : Found NVS/recl - at ${memoryMap[$a]:11:16}"
                    tmpStart="${memoryMap[$a]:11:16}"
                    tmpEnd="${memoryMap[$a]:30:16}"
                fi
            fi
        fi
        
        # Does this current line begin with 'Type'?
        # If yes, indicate that we can begin reading details.
        [[ "${memoryMap[$a]}" == Type* ]] && regionsBegin=1
    done
    IFS="$OIFS"
    #LogToScreenAndFile $separatorLine
    
    # Print ranges determined for scanning.
    LogToFile "${gLogIndent}Memory: Selected memory ranges for RSDP pointer scan:"
    for ((a=0; a<"${#acpiAddressRegionsStart[@]}"; a++))
    do
        LogToFile "${gLogIndent}${acpiAddressRegionsStart[$a]} | ${acpiAddressRegionsFinish[$a]}"
    done
    #LogToScreenAndFile $separatorLine

    # ======================================================================== 
    # Iterate through identified address regions to find RSDP pointer.
    if [ "${#acpiAddressRegionsStart[@]}" -gt 0 ]; then

        LogToFile "${gLogIndent}Memory: Scanning for RSDP pointers."
        for ((a=0; a<"${#acpiAddressRegionsStart[@]}"; a++))
        do
            # Calculate length of region.
            startAddr="${acpiAddressRegionsStart[$a]}"
            finishAddr="${acpiAddressRegionsFinish[$a]}"
            ACPI_NVSstart=$(convertHexToDec ${startAddr})
            ACPI_NVSfinish=$(convertHexToDec ${finishAddr})
            ACPI_NVSlength=$(( $ACPI_NVSfinish - $ACPI_NVSstart ))
            ((ACPI_NVSlength++))

            # Calculate necessary values for reading area of memory.
            skipBytes=$(( $ACPI_NVSstart / $blockSize ))
            numBlocks=$(( $ACPI_NVSlength / $blockSize ))
            
            #LogToScreenAndFile ""
            #LogToScreenAndFile "Checking $(( $blockSize * $numBlocks )) bytes (${startAddr} to ${finishAddr})"
            memBlock=$( sudo dd 2>/dev/null if=/dev/pmem bs=$blockSize count=$numBlocks skip=$skipBytes | perl -ne '@a=split"";for(@a){printf"%02x",ord}' )
            
            # Search for signature:
            # 52534420 = 'RSD ' [4]
            # 50545220 = 'PTR ' [4]
            rsdpSignature="5253442050545220"
   
            # Check for more than one occurrence of the RSDP signature
            sigCount=$( echo "$memBlock" | grep -o "$rsdpSignature" | wc -l )

            if [ $sigCount -ge 1 ]; then

                #LogToFile "Number of RSDP signatures found: $sigCount"
                pointer=""
                for (( l=1; l<=$sigCount; l++ ))
                do
                    # Find position of signature
                    sigPos=$( echo "$memBlock" | awk '{print index($0,"5253442050545220")}' )
                    # Add length of signature to position of signature, less 1 
                    sigPos=$(( $sigPos + ${#rsdpSignature} - 1 ))
                    # Strip signature from memoryblock so we now look at first byte after
                    memBlock="${memBlock:$sigPos}"
                    
                    # Read ACPI v1.0 structure
                    ReadRSDPStructureOne "$memBlock"
                    
                    # Validate checksum
                    rsdpBytes="5253442050545220"${rsdpChecksum}${rsdpOemId}${rsdpRevision}${rsdtAddress}
                    rsdpOneChecksum=$(ValidateRsdpChecksum ${rsdpBytes})
                    if [ ! $rsdpOneChecksum == "00" ]; then
                        LogToFile "${gLogIndent}ACPI v1.0 Checksum $rsdpOneChecksum in invalid. Skipping this pointer."
                        break
                    #else
                        #LogToFile "ACPI v1.0 Checksum $rsdpOneChecksum is valid."
                    fi

                    # Reconstruct address
                    rsdtAddress=$(ReverseBytes $rsdtAddress)
                    xsdtAddress=""
                    pointer="$rsdtAddress"
                    
                    if [ "$rsdpRevision" == "02" ] || [ "$rsdpRevision" == "03" ]; then
                        # Read ACPI v2.0 structure
                        ReadRSDPStructureTwo "$memBlock"
                        
                        # Validate checksum
                        rsdpBytes="5253442050545220"${rsdpChecksum}${rsdpOemId}${rsdpRevision}${rsdtAddress}${rsdtLength}${xsdtAddress}${rsdtExtendedChecksum}${rsdtReserved}
                        rsdpTwoChecksum=$(ValidateRsdpChecksum ${rsdpBytes})
                        if [ ! $checkSum == "00" ]; then
                            LogToFile "${gLogIndent}ACPI v2.0 Checksum $rsdpTwoChecksum in invalid. Skipping this pointer."
                            break
                        #else
                            #LogToFile "ACPI v2.0 Checksum $rsdpTwoChecksum is valid."
                        fi

                        # Convert length
                        xsdtLength=$(convertLittleEndianHexToDec ${rsdtLength})
                        
                        # Reconstruct address
                        xsdtAddress=$(ReverseBytes $xsdtAddress)
                        pointer="$xsdtAddress"
                    fi
                
                    # Resolve this RSDP pointer to see if it's valid?
                    checkPointer=$(ResolvePointer ${pointer})
                    if [ "$checkPointer" == "RSDT" ] || [ "$checkPointer" == "XSDT" ]; then
                        #LogToFile "Pointer is valid and correctly resolves to an $checkPointer table."
                        # append to array
                        rxsdtPointers+=(${pointer})
                        # break
                        isPointerValid="Valid"
                    else
                        #LogToFile "Pointer is not valid."
                        pointer=""
                        isPointerValid="InValid"
                    fi
                    
                    #if [ ! "$xsdtAddress" == "" ]; then
                        #LogToScreenAndFile "${gLogIndent}Rev:$rsdpRevision | RSDT:$rsdtAddress | Checksum:$rsdpOneChecksum | XSDT:$xsdtAddress | Checksum:$rsdpTwoChecksum | $isPointerValid"
                    #else
                        #LogToScreenAndFile "${gLogIndent}Rev:$rsdpRevision | RSDT:$rsdtAddress | Checksum:$rsdpOneChecksum | $isPointerValid"
                    #fi
                    
                done
                
                #if [ ! "$pointer" == "" ]; then
                #    break
                #fi


            fi
        done
    else
        LogToScreenAndFile "${gLogIndent}Failed to find ACPI_NVS regions in memory map"
    fi
fi
#LogToScreenAndFile $separatorLine

# ======================================================================== 
# Show all valid pointers found
LogToFile "${gLogIndent}Valid pointers found:"
for ((a=0; a<"${#rxsdtPointers[@]}"; a++))
do
    LogToFile "${gLogIndent}$a | ${rxsdtPointers[$a]}"
done
#LogToScreenAndFile $separatorLine

# ======================================================================== 
# Allow user to choose which they use
if [ $AUTO -eq 0 ]; then
    echo "Which pointer do you wish to use?"
    echo "Select a number from the range, followed by ENTER"
    echo "Or press A/a for dump all."
    read UserInput
    while [[ ! $UserInput =~ ^[0-$((${#rxsdtPointers[@]}-1))] ]] && [ "$UserInput" != "a" ]
    do
        echo "Select number followed by ENTER"
        read UserInput 
    done
    LogToFile "User selected $UserInput"
else
    UserInput="a"
fi

if [ ! "$UserInput" == "a" ] && [ ! "$UserInput" == "A" ]; then
    pointer="${rxsdtPointers[$UserInput]}"
    ProcessTables "$pointer"
else
    for ((a=0; a<"${#rxsdtPointers[@]}"; a++))
    do
        ProcessTables "${rxsdtPointers[$a]}"
    done
fi

#LogToScreenAndFile $separatorLine

# ======================================================================== 
# Unload pmem.kext driver if we loaded it
if [ $driverLoaded -eq 1 ]; then
    sudo kextunload -v /tmp/"$pmemKext"
fi

exit 1