#!/bin/sh

ChangeSymlink()
{
    if [ ! -d /usr/local/bin ]; then
        mkdir /usr/local/bin
    fi
    
    if [ "$symlinkTask" == "Create Symlink" ]; then
        ln -s "$scriptLocation" /usr/local/bin/darwindumper
        echo "Created symlink /usr/local/bin/darwindumper pointing to $scriptLocation"
    elif [ "$symlinkTask" == "Update Symlink" ]; then
        rm /usr/local/bin/darwindumper
        ln -s "$scriptLocation" /usr/local/bin/darwindumper
        echo "Update symlink /usr/local/bin/darwindumper to point to $scriptLocation"
    elif [ "$symlinkTask" == "Delete Symlink" ]; then
        rm /usr/local/bin/darwindumper
        echo "Deleted symlink /usr/local/bin/darwindumper"
    fi
}

ChangeDumpFolderOwnPerm()
{
    chown "${DD_BOSS}":"${DD_BOSSGROUP}" "$appContainingFolder"    
    chmod -R 755 "$appContainingFolder" 
}

CreateReportsFolderSetPerms()
{
    mkdir "$folderPath"
    chown "${DD_BOSS}":"${DD_BOSSGROUP}" "$folderPath"    
    chmod -R 755 "$folderPath" 
}

# Passing strings with spaces fails as that's used as a delimiter.
# Instead, I pass each argument delimited by character @

# Parse arguments
declare -a "arguments"
passedArguments="$@"

numFields=$( grep -o "@" <<< "$passedArguments" | wc -l )
(( numFields++ ))
for (( f=2; f<=$numFields; f++ ))
do
    arguments[$f]=$( echo "$passedArguments" | cut -d '@' -f$f )
    #[[ DEBUG -eq 1 ]] && WriteToLog "${debugIndentTwo}arguments[$f]=${arguments[$f]}"
done

whichFunction="${arguments[2]}"
echo ""

case "$whichFunction" in
    "Symlink" )              scriptLocation="${arguments[3]}"
                             symlinkTask="${arguments[4]}"
                             ChangeSymlink
                             ;;
    "OwnPerm" )              DD_BOSS="${arguments[3]}"
                             DD_BOSSGROUP="${arguments[4]}"
                             appContainingFolder="${arguments[5]}"
                             ChangeDumpFolderOwnPerm
                             ;;
    "CreateFolderSetPerms" ) DD_BOSS="${arguments[3]}"
                             DD_BOSSGROUP="${arguments[4]}"
                             folderPath="${arguments[5]}"
                             CreateReportsFolderSetPerms
                             ;;
esac


