#!/usr/bin/bash

# specify name to install
BINARY_NAME='aria2'
DAEMON_NAME='Aria2 Service Daemon'

# specify version to install
VERSION='1.35.0'

# --------------------------------------------------

LAUNCH_DIR="$(cd $(dirname $0); pwd)"

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

# don't edit if you are not fully understand codes below (!!!)
# change this path to somewhere may cause data loss risk (!!!)
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
DOWNLOAD_URL="https://github.com/aria2/aria2/releases/download/release-${VERSION}/aria2-${VERSION}.tar.gz"
DOWNLOAD_FILE="/tmp/aria2-${VERSION}.tar.gz"
SOURCE_DIR="/usr/local/src/aria2-${VERSION}"

if [ -d "${SOURCE_DIR}" ]; then
	print_red "* source directory '${SOURCE_DIR}' already exists"
	exit 1
fi

# check dependencies (c-ares)
if [ ! -f "/usr/local/lib/pkgconfig/libcares.pc" ]; then
	print_red "* required dependency 'c-ares' not installed"
	exit 1
fi

# check dependencies (sqlite3)
if [ ! -f "/usr/local/lib/pkgconfig/sqlite3.pc" ]; then
	print_red "* required dependency 'sqlite3' not installed"
	exit 1
fi

wget -q ${DOWNLOAD_URL} -O ${DOWNLOAD_FILE}

if [ ! -f "${DOWNLOAD_FILE}" ]; then
	print_red "* failed to downloading from '${DOWNLOAD_URL}'"
	exit 1
fi

tar -xzf ${DOWNLOAD_FILE} -C /usr/local/src
rm -f ${DOWNLOAD_FILE}

if [ -d "${SOURCE_DIR}" ]; then

	# install pre-compile dependencies
	yum groupinstall -y "Development Tools"
	yum install -y gnutls-devel libxml2-devel libssh2-devel libgcrypt-devel

	# redirect to source directory
	cd ${SOURCE_DIR}

	# you can custom arguments whatever you want (except --prefix)
	./configure --prefix=${INSTALL_DIR} --disable-metalink --disable-bittorrent

	# build and install then back to previous directory
	make && make install && cd ${LAUNCH_DIR}

	# delete source directory
	rm -rf ${SOURCE_DIR}

else
	print_red "* failed to extract files from '${DOWNLOAD_FILE}'"
	exit 1
fi

mv -f ${INSTALL_DIR}/bin/aria2c ${INSTALL_DIR}/aria2c
rmdir ${INSTALL_DIR}/bin

cp -af ${INSTALL_DIR}/share/* /usr/local/share
rm -rf ${INSTALL_DIR}/share

chmod +x ${INSTALL_DIR}/aria2c
strip -s ${INSTALL_DIR}/aria2c
ln -s ${INSTALL_DIR}/aria2c /usr/local/bin/${BINARY_NAME}

# create an empty config to remind user overwrite as same file name
touch ${INSTALL_DIR}/aria2c.conf

echo -e "[Unit]
Description=${DAEMON_NAME}
After=network.target nss-lookup.target

[Service]
Type=forking
Restart=always
GuessMainPID=yes

ExecStart=/usr/local/bin/${BINARY_NAME} --daemon --conf-path=${INSTALL_DIR}/aria2c.conf

[Install]
WantedBy=multi-user.target\n" > /usr/lib/systemd/system/${BINARY_NAME}.service

systemctl daemon-reload
echo "$(systemctl status ${BINARY_NAME} | grep -A 2 '● ')"

print_green "* installation completed"

# done #