#!/usr/bin/bash

DIR=$(dirname $(realpath -- "$0";))
for filename in $DIR/applications/*.desktop; do
    echo "installing $filename"
    sudo chown deck:deck $filename
    sudo cp -a $filename /home/deck/.local/share/applications/
done

if [ ! -e $DIR/scripts/fscrypt-user-get-passphrase ]; then
    echo "Installing default interactive passphrase prompt at $DIR/scripts/fscrypt-user-get-passphrase. Replace it if you want to get your passphrase some other way."
    sudo cp $DIR/fscrypt-user-get-passphrase.sample-interactive $DIR/scripts/fscrypt-user-get-passphrase
fi

for filename in $DIR/scripts/*; do
    echo "setting permissions on $filename"
    sudo chown deck:deck $filename
    sudo chmod ug+rwx $filename
done

