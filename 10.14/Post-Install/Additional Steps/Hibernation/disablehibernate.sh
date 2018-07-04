#!/bin/bash

sudo pmset -a autopoweroff 0
sudo pmset -a standby 0
sudo pmset -a hibernatemode 0

echo
echo "Hibernatemode, standby, and autopoweroff set to 0..."

sudo rm /private/var/vm/sleepimage

echo
echo "Sleepimage deleted..."

sudo touch /private/var/vm/sleepimage
sudo chflags uchg /private/var/vm/sleepimage

echo
echo "Zero-byte sleepimage created and locked from further writes."
echo
echo "Done!"
