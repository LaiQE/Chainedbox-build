#!/bin/bash
rm -rf /etc/apt/sources.list.d/openmediavault.list
cat <<EOF >> /etc/apt/sources.list.d/openmediavault.list
deb http://packages.openmediavault.org/public shaitan main
# deb http://downloads.sourceforge.net/project/openmediavault/packages shaitan main
## Uncomment the following line to add software from the proposed repository.
# deb http://packages.openmediavault.org/public shaitan-proposed main
# deb http://downloads.sourceforge.net/project/openmediavault/packages shaitan-proposed main
## This software is not part of OpenMediaVault, but is offered by third-party
## developers as a service to OpenMediaVault users.
# deb http://packages.openmediavault.org/public shaitan partner
# deb http://downloads.sourceforge.net/project/openmediavault/packages shaitan partner
EOF

export LANG=C.UTF-8
export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none
apt-get install --yes gnupg
wget -O "/etc/apt/trusted.gpg.d/openmediavault-archive-keyring.asc" https://packages.openmediavault.org/public/archive.key
apt-key add "/etc/apt/trusted.gpg.d/openmediavault-archive-keyring.asc"
apt-get update
apt-get --yes --auto-remove --show-upgraded \
    --allow-downgrades --allow-change-held-packages \
    --no-install-recommends \
    --option DPkg::Options::="--force-confdef" \
    --option DPkg::Options::="--force-confold" \
    install openmediavault-keyring openmediavault

# Populate the database.
omv-confdbadm populate

# Display the login information.
cat /etc/issue
