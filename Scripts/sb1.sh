#!/bin/bash
# Add the temporary entry required by cryptboot to crypttab
echo "cryptboot /dev/disk/by-uuid/PART2 none luks" >>/etc/crypttab

# Replace PART2 with the UUID of the second partition of the external drive.
sed -i "s/PART2/$(blkid -t PARTLABEL="Linux LUKS" | sed 's/PARTUUID/ /' | sed 's/.*UUID=\"\([^\"]*\)\".*/\1/')/" /etc/crypttab
