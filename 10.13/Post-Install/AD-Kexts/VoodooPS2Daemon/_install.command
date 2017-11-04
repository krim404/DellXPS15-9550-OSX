#!/bin/bash

path=${0%/*}
echo Installing VoodooPS2Daemon
sudo cp -a "$path/VoodooPS2Daemon" /usr/bin
sudo cp -a "$path/org.rehabman.voodoo.driver.Daemon.plist" /Library/LaunchDaemons

