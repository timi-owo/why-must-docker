#!/usr/bin/bash

# specify name to install
BINARY_NAME='nginx'
DAEMON_NAME='Nginx Service Daemon'

# specify version to install
VERSION='1.19.6'

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
DOWNLOAD_URL="https://nginx.org/download/nginx-${VERSION}.tar.gz"
DOWNLOAD_FILE="/tmp/nginx-${VERSION}.tar.gz"
SOURCE_DIR="/usr/local/src/nginx-${VERSION}"

if [ -d "${SOURCE_DIR}" ]; then
	print_red "* source directory '${SOURCE_DIR}' already exists"
	exit 1
fi

# check dependencies (perl)
if [ ! -f "/usr/bin/perl" ]; then
	print_red "* required dependency 'perl' not installed"
	exit 1
fi

# check dependencies (pcre)
if [ ! -f "/usr/local/lib/pkgconfig/libpcre.pc" ]; then
	print_red "* required dependency 'pcre' not installed"
	exit 1
fi

# check dependencies (zlib)
if [ ! -f "/usr/local/lib/pkgconfig/zlib.pc" ]; then
	print_red "* required dependency 'zlib' not installed"
	exit 1
fi

# check dependencies (openssl)
if [ ! -f "/usr/local/lib/pkgconfig/openssl.pc" ]; then
	print_red "* required dependency 'openssl' not installed"
	exit 1
fi

# add external module from github (ngx_brotli)
GIT_REPO='https://github.com/google/ngx_brotli.git'
GIT_PATH="/usr/local/src/$(echo ${GIT_REPO##*/} | cut -d '.' -f 1)"

if [ ! -d "${GIT_PATH}" ]; then
	yum install -y git && cd /usr/local/src && git clone ${GIT_REPO}
else
	print_red "* git repository '${GIT_PATH}' already exists"
	exit 1
fi

if [ -d "${GIT_PATH}" ]; then

	cd ${GIT_PATH}
	git submodule update --init
	cd ${LAUNCH_DIR}
else
	print_red "* failed clone git repository from '${GIT_REPO}'"
	cd ${LAUNCH_DIR} && exit 1
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

	# you can custom compile options whatever you want
	COMPILE_OPTIONS=(

		# don't edit this option
		--prefix=${INSTALL_DIR}

		# don't edit this option
		--pid-path=/run/nginx.pid
		--lock-path=/run/lock/nginx.lock

		--with-threads
		--with-file-aio
		--with-cc-opt='-O2'

		--with-http_v2_module
		--with-http_ssl_module
		--with-http_sub_module
		--with-http_realip_module
		--with-http_gzip_static_module
		--with-http_stub_status_module

		--with-stream
		--with-stream_ssl_module
		--with-stream_ssl_preread_module
		--with-stream_realip_module

		--with-pcre
		--with-pcre-jit

		--without-mail_pop3_module
		--without-mail_imap_module
		--without-mail_smtp_module

		--http-client-body-temp-path=${INSTALL_DIR}/temp/client_body_temp
		--http-proxy-temp-path=${INSTALL_DIR}/temp/proxy_temp
		--http-fastcgi-temp-path=${INSTALL_DIR}/temp/fastcgi_temp
		--http-uwsgi-temp-path=${INSTALL_DIR}/temp/uwsgi_temp
		--http-scgi-temp-path=${INSTALL_DIR}/temp/scgi_temp

		# make sure module 'ngx_brotli' is available first
		--add-module=${GIT_PATH}
	)

	./configure ${COMPILE_OPTIONS[@]}

	# build and install then back to previous directory
	make && make install && cd ${LAUNCH_DIR}

	# delete source directory
	rm -rf ${SOURCE_DIR} && rm -rf ${GIT_PATH}

else
	print_red "* failed to extract files from '${DOWNLOAD_FILE}'"
	exit 1
fi

mkdir ${INSTALL_DIR}/temp
chmod +x ${INSTALL_DIR}/sbin/nginx
ln -s ${INSTALL_DIR}/sbin/nginx /usr/local/bin/${BINARY_NAME}

echo -e "[Unit]
Description=${DAEMON_NAME}
After=network.target nss-lookup.target

[Service]
Type=forking
Restart=always
PIDFile=/run/nginx.pid

ExecStart=/usr/local/bin/${BINARY_NAME}
ExecReload=/usr/local/bin/${BINARY_NAME} -s reload
ExecStop=/usr/local/bin/${BINARY_NAME} -s stop

[Install]
WantedBy=multi-user.target\n" > /usr/lib/systemd/system/${BINARY_NAME}.service

systemctl daemon-reload
echo "$(systemctl status ${BINARY_NAME} | grep -A 2 '● ')"

print_green "* installation completed"

# done #