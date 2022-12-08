#!/bin/bash

if [[ $# -lt 1 ]]; then
    echo "usage: $0 <hidraw-id>"
    exit 1
fi

echo credential challenge | openssl sha256 -binary | base64 > cred_param
echo relying party >> cred_param
echo franzi >> cred_param
dd if=/dev/urandom bs=1 count=32 | base64 >> cred_param

fido2-cred -M -i cred_param /dev/hidraw$1 | fido2-cred -V -o cred

cat cred
