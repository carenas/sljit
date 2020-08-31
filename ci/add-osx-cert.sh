#!/bin/sh
#
# Uses the following variables to be provided by the CI environment
# CERTIFICATE_OSX_P12: a base64 encoded p12 with the certificate
# CERTIFICATE_PASSWORD: the password for the certificate
# CERTIFICATE_ID: the ID that identifies the certificate
#

KEY_CHAIN=build.keychain
CERTIFICATE_P12=certificate.p12

# Recreate the certificate from the secure environment variable
echo "$CERTIFICATE_OSX_P12" | base64 --decode > $CERTIFICATE_P12

#create a unique keychain
security delete-keychain $KEY_CHAIN 2>/dev/null || true
security create-keychain -p github $KEY_CHAIN

# Make the keychain the default so identities are found
security default-keychain -s $KEY_CHAIN

# Unlock the keychain
security unlock-keychain -p github $KEY_CHAIN

security -q import $CERTIFICATE_P12 -k $KEY_CHAIN -P $CERTIFICATE_PASSWORD -T /usr/bin/codesign 2>/dev/null
if [ $(uname -r) != "15.6.0" ]; then
	security set-key-partition-list -S apple-tool:,apple: -s -k github $KEY_CHAIN >/dev/null
fi

# remove certs
rm -rf *.p12

ID=$(security find-identity -vp codesigning | perl -ne 'print $1 if /\(([0-9A-Z]+)\)/;')
[ "$ID" = "$CERTIFICATE_ID" ]
