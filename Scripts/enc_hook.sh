#!/bin/bash
# This script provides the needed UUIDs for the custom encrypt hook

# PART2
# PART2 = Second partition of the external drive

sed -i "s/PART2/$(blkid -t PARTLABEL="Linux LUKS" | sed 's/PARTUUID/ /' | sed 's/.*UUID=\"\([^\"]*\)\".*/\1/')/g" ../enc_hooks/2/encrypt_hook

# ISD
# ISD = Internal Storage Drive

sed -i "s/ISD/$(blkid -t PARTLABEL="Linux x86 root (/)" | sed 's/.*UUID=\"\([^\"]*\)\".*/\1/')/" ../enc_hooks/2/encrypt_hook

