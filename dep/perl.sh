#!/usr/bin/bash

# specify version to install
VERSION='5.32.0'

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

print_yellow "* installing 'perl v${VERSION}' ···"

# don't edit those variables
BRANCH=$(echo ${VERSION} | awk -F '.' '{ print $1 ".0" }')
DOWNLOAD_URL="https://www.cpan.org/src/${BRANCH}/perl-${VERSION}.tar.gz"
DOWNLOAD_FILE="/tmp/perl-${VERSION}.tar.gz"
SOURCE_DIR="/usr/local/src/perl-${VERSION}"

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

	# you can custom arguments whatever you want (except -Dprefix)
	./Configure -des -Dusethreads -Dprefix=/usr/local

	# build and install then back to previous directory
	make && make install && cd ${LAUNCH_DIR}

	# delete source directory
	rm -rf ${SOURCE_DIR}

else
	print_red "* failed to extract files from '${DOWNLOAD_FILE}'"
	exit 1
fi

# check and disable old version
if [ -f "/usr/bin/perl" ] || [ -L "/usr/bin/perl" ]; then
	mv -f /usr/bin/perl /usr/bin/perl.old
	ln -s /usr/local/bin/perl /usr/bin/perl
fi

# refresh system dynamic libraries cache
echo "/usr/local/lib" > /etc/ld.so.conf.d/usr-local-lib.conf
echo "/usr/local/lib64" > /etc/ld.so.conf.d/usr-local-lib64.conf
ldconfig

print_green "* installation completed"

# done #