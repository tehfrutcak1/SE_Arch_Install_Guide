#!/bin/bash

# Remove Old FSTAB (if there is one)
rm -f /etc/fstab
# Copy new FSTAB
cp ../fstab /etc/fstab

# The FSTAB in this repository contains PART1 and PART2 as the UUIDs of the 1st and 2nd partitions on the external drive
# This script replaces PART1 and PART2 with the actual UUIDs of the 1st and 2nd partition of the external drive
# It does so by looking at the "tokens" using `blkid` then removing PARTUUID as to avoid outputing both PARTUUID and UUID when filtering the UUID.

## If you think you can come up with a better solution please fork the repository and make a pull request, from there I'll discuss it and decide wheter or not to merge the change.

# PART1
sed -i "s/PART1/$(blkid -t PARTLABEL="EFI system partition" | sed 's/PARTUUID/ /' | sed 's/.*UUID=\"\([^\"]*\)\".*/\1/')/" /etc/fstab

# PART2
sed -i "s/PART2/$(blkid -t PARTLABEL="Linux LUKS" | sed 's/PARTUUID/ /' | sed 's/.*UUID=\"\([^\"]*\)\".*/\1/')/" /etc/fstab
