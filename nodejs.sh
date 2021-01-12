#!/usr/bin/bash

# specify version to install
VERSION='14.15.4'

# --------------------------------------------------

print_red()
{
	printf '\033[1;31;31m%b\033[0m' "$1\n"
}

print_green()
{
	printf '\033[1;31;32m%b\033[0m' "$1\n"
}

print_yellow()
{
	printf '\033[1;31;33m%b\033[0m' "$1\n"
}

print_yellow "* installing 'node.js v${VERSION}' ···"

if [ -f "/usr/bin/node" ] || [ -f "/usr/local/bin/node" ]; then
	print_red "* you have already installed node.js $(node -v)"
	exit 1
fi

# don't edit those variables
DOWNLOAD_URL="https://nodejs.org/dist/v${VERSION}/node-v${VERSION}-linux-x64.tar.xz"
DOWNLOAD_FILE="/tmp/nodejs-${VERSION}.tar.xz"

wget -q ${DOWNLOAD_URL} -O ${DOWNLOAD_FILE}

if [ ! -f "${DOWNLOAD_FILE}" ]; then
	print_red "* failed to downloading from '${DOWNLOAD_URL}'"
	exit 1
fi

tar -xf ${DOWNLOAD_FILE} -C /tmp
rm -f ${DOWNLOAD_FILE}

if [ ! -d "/tmp/node-v${VERSION}-linux-x64" ]; then
	print_red "* failed to extract files from '${DOWNLOAD_FILE}'"
	exit 1
fi

cp -af /tmp/node-v${VERSION}-linux-x64/bin/* /usr/local/bin
cp -af /tmp/node-v${VERSION}-linux-x64/include/* /usr/local/include
cp -af /tmp/node-v${VERSION}-linux-x64/lib/* /usr/local/lib
cp -af /tmp/node-v${VERSION}-linux-x64/share/* /usr/local/share
rm -rf /tmp/node-v${VERSION}-linux-x64

chmod +x /usr/local/bin/node
chmod +x /usr/local/bin/npm
chmod +x /usr/local/bin/npx

echo "* node $(node -v) / npm v$(npm -v)"
print_green "* installation completed"

# done #