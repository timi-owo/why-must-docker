#!/usr/bin/bash

# specify name to install
BINARY_NAME='cloudreve'
DAEMON_NAME='Cloudreve Service Daemon'

# specify version to install
VERSION='3.2.1'

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

# don't change this path if not necessary
INSTALL_DIR="/usr/local/${BINARY_NAME}"

print_yellow "* installing '${BINARY_NAME} v${VERSION}' to '${INSTALL_DIR}' ···"

if [ -d "${INSTALL_DIR}" ]; then
	print_red "* install directory '${INSTALL_DIR}' already exists"
	exit 1
fi

if [ -f "/usr/bin/${BINARY_NAME}" ] || [ -f "/usr/local/bin/${BINARY_NAME}" ]; then
	print_red "* binary file '${BINARY_NAME}' already exists"
	exit 1
fi

if [ -L "/usr/bin/${BINARY_NAME}" ] || [ -L "/usr/local/bin/${BINARY_NAME}" ]; then
	print_red "* symbol link '${BINARY_NAME}' already exists"
	exit 1
fi

if [ -f "/usr/lib/systemd/system/${BINARY_NAME}.service" ]; then
	print_red "* daemon file '${BINARY_NAME}.service' already exists"
	exit 1
fi

# don't edit those variables
DOWNLOAD_URL="https://github.com/cloudreve/Cloudreve/releases/download/${VERSION}/cloudreve_${VERSION}_linux_amd64.tar.gz"
DOWNLOAD_FILE="/tmp/${BINARY_NAME}-${VERSION}.tar.gz"

wget -q ${DOWNLOAD_URL} -O ${DOWNLOAD_FILE}

if [ ! -f "${DOWNLOAD_FILE}" ]; then
	print_red "* failed to downloading from '${DOWNLOAD_URL}'"
	exit 1
fi

mkdir ${INSTALL_DIR}
tar -xzf ${DOWNLOAD_FILE} -C ${INSTALL_DIR}
rm -f ${DOWNLOAD_FILE}

chmod +x ${INSTALL_DIR}/cloudreve
ln -s ${INSTALL_DIR}/cloudreve /usr/local/bin/${BINARY_NAME}

# create an empty config to remind user overwrite as same file name
touch ${INSTALL_DIR}/cloudreve.ini

echo -e "[Unit]
Description=${DAEMON_NAME}
After=network.target nss-lookup.target

[Service]
Type=simple
Restart=on-failure

ExecStart=/usr/local/bin/${BINARY_NAME} -c ${INSTALL_DIR}/cloudreve.ini

[Install]
WantedBy=multi-user.target\n" > /usr/lib/systemd/system/${BINARY_NAME}.service

systemctl daemon-reload
echo "$(systemctl status ${BINARY_NAME} | grep -A 2 '● ')"

print_green "* installation completed"

# done #