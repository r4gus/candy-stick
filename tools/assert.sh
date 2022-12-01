#!/bin/sh

if [[ $# -lt 1 ]]; then
    echo "usage: $0 <hidraw-id>"
    exit 1
fi

echo assertion challenge | openssl sha256 -binary | base64 > assert_param
echo relying party >> assert_param
head -1 cred >> assert_param
tail -n +2 cred > pubkey

fido2-assert -G -i assert_param /dev/hidraw$1 | fido2-assert -V pubkey es256
