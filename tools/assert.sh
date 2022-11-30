#!/bin/sh

echo assertion challenge | openssl sha256 -binary | base64 > assert_param
echo relying party >> assert_param
head -1 cred >> assert_param
tail -n +2 cred > pubkey

fido2-assert -G -i assert_param /dev/hidraw6 | fido2-assert -V pubkey es256
