#!/usr/bin/bash

# specify version to install (useless, only for display)
VERSION='3.34.1'

# specify version number to download (on sqlite website)
VERSION_NUM='3340100'

# specify release year of installation version
RELEASE_YEAR='2021'

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

print_yellow "* installing 'sqlite v${VERSION}' ···"

# don't edit those variables
DOWNLOAD_URL="https://www.sqlite.org/${RELEASE_YEAR}/sqlite-autoconf-${VERSION_NUM}.tar.gz"
DOWNLOAD_FILE="/tmp/sqlite-autoconf-${VERSION_NUM}.tar.gz"
SOURCE_DIR="/usr/local/src/sqlite-autoconf-${VERSION_NUM}"

if [ -d "${SOURCE_DIR}" ]; then
	print_red "* source directory '${SOURCE_DIR}' already exists"
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

	# redirect to source directory
	cd ${SOURCE_DIR}

	# you can custom arguments whatever you want (except --prefix)
	./configure --prefix=/usr/local

	# build and install then back to previous directory
	make && make install && cd ${LAUNCH_DIR}

	# delete source directory
	rm -rf ${SOURCE_DIR}

else
	print_red "* failed to extract files from '${DOWNLOAD_FILE}'"
	exit 1
fi

# refresh system dynamic libraries cache
echo "/usr/local/lib" > /etc/ld.so.conf.d/usr-local-lib.conf
echo "/usr/local/lib64" > /etc/ld.so.conf.d/usr-local-lib64.conf
ldconfig

print_green "* installation completed"

# done #