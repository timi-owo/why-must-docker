#!/usr/bin/bash

# specify version to install
VERSION='1.1.1k'

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

print_yellow "* installing 'openssl v${VERSION}' ···"

# don't edit those variables
DOWNLOAD_URL="https://www.openssl.org/source/openssl-${VERSION}.tar.gz"
DOWNLOAD_FILE="/tmp/openssl-${VERSION}.tar.gz"
SOURCE_DIR="/usr/local/src/openssl-${VERSION}"

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
	./config --prefix=/usr/local

	# build and install then back to previous directory
	make && make install && cd ${LAUNCH_DIR}

	# delete source directory
	rm -rf ${SOURCE_DIR}

else
	print_red "* failed to extract files from '${DOWNLOAD_FILE}'"
	exit 1
fi

# check and disable old version
if [ -f "/usr/bin/openssl" ] || [ -L "/usr/bin/openssl" ]; then
	mv -f /usr/bin/openssl /usr/bin/openssl.old
	ln -s /usr/local/bin/openssl /usr/bin/openssl
fi

# fix other party couldn't find openssl libraries
LIB_FILES=(

	libssl.a
	libssl.so

	libcrypto.a
	libcrypto.so

	pkgconfig/libssl.pc
	pkgconfig/libcrypto.pc
	pkgconfig/openssl.pc
)

for each in ${LIB_FILES[@]}
do
	if [ ! -f "/usr/local/lib/${each}" ]; then
		ln -s /usr/local/lib64/${each} /usr/local/lib/${each}
	fi
done

# refresh system dynamic libraries cache
echo "/usr/local/lib" > /etc/ld.so.conf.d/usr-local-lib.conf
echo "/usr/local/lib64" > /etc/ld.so.conf.d/usr-local-lib64.conf
ldconfig

print_green "* installation completed"

# done #