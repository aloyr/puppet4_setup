#!/bin/bash

if [ $(id -u) -ne 0 ]; then
  echo "You must use sudo to run this command."
  echo "Use 'sudo $(echo $0)'"
  exit 1
fi

if [ $(hash puppet 2> /dev/null; echo $?) -eq 0 ]; then
  echo "puppet already installed."
  echo "Use 'sudo $(echo $0) update' to force update."
  exit 1
fi

## INSTALLATION ##
# handle OSX clients
if [ $(uname -s) == 'Darwin' ]; then
  echo "OSX Detected"
  OS_VERSION=$(sw_vers -productVersion | sed 's/\.[0-9]$//g')
  LIST_URL="https://downloads.puppetlabs.com/mac/${OS_VERSION}/PC1/x86_64/"
  PACKAGE_NAME=$(curl -s ${LIST_URL} | grep dmg | tail -n 1 | sed 's/.*>\(puppet[-a-z0-9\.A-Z]*\).*/\1/g')
  PACKAGE_URL="${LIST_URL}${PACKAGE_NAME}"
  PACKAGE_DMG="${HOME}/Downloads/${PACKAGE_NAME}"
  echo "Downloading puppet-agent"
  curl -s ${PACKAGE_URL} -o ${PACKAGE_DMG}
  echo "Mounting volume"
  VOLUME=$(hdiutil mount ${PACKAGE_DMG} | awk '$0 ~ /Volumes/ {print $3}')
  PACKAGE_PKG=$(ls ${VOLUME}/*pkg)
  echo "Installing package"
  /usr/sbin/installer -target / -pkg ${PACKAGE_PKG}
  echo "Unmounting volume"
  hdiutil unmount ${VOLUME}
fi

## MAKE SYMLINKS ##
SRC="/opt/puppetlabs/bin"
DST="/usr/local/bin"
echo "Creating Symlinks"
ls ${SRC} | while read file; do
  ln -s ${SRC}/${file} ${DST}
done