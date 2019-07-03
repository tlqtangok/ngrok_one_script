#!/bin/bash
### copyright by Jidor Tang <tlqtangok@126.com>  ###
# wx public: jd_geek 
# date: 2019-07-03

# this script do following things:

	# - download ngrok 1.7.1 src code
	# - download go 1.7.6 binary for linux amd64
	# - build out key and secret for a host ip
	# - change one go source code "log4go"'s location
	# - build ngrokd, ngrok clients, include "linux, arms, windows"

# after build, you can see your binary file under bin/*

# how to run : 
	# bash ngrok_one_script.sh

###########################
### some assert of deps ###
###########################
CURL_WHICH=`which curl`
if [ "$CURL_WHICH" = "" ]; then
	echo "- error, please run sudo apt install curl "
	exit 1
fi
WGET_WHICH=`which wget`

if [ "$WGET_WHICH" = "" ]; then
	echo "- error, please run sudo apt install wget "
	exit 2 
fi

TAR_WHICH=`which tar`
if [ "$TAR_WHICH" = "" ]; then
	echo "- error, please run sudo apt install tar "
	exit 3 
fi

SSL_WHICH=`which openssl`
if [ "$SSL_WHICH" = "" ]; then
	echo "- error, please run sudo apt install  libssl-dev "
	exit 4 
fi

MAKE_WHICH=`which make`
if [ "$MAKE_WHICH" = "" ]; then
	echo "- error, please run sudo apt install make "
	exit 5 
fi


export PUBLIC_IP=`curl icanhazip.com`
if [ "$PUBLIC_IP" = "" ]; then
	echo "- error, unknown error, didnot got you public ip !!!"
	exit 5 
fi

#export PUBLIC_IP='algo.com'
export NGROK_DOMAIN=$PUBLIC_IP

#################################################
### create a folder and download some tarball ###
#################################################
mkdir -p src_ngrok_go
cd src_ngrok_go

wget -c https://github.com/inconshreveable/ngrok/archive/1.7.1.tar.gz
ls 1.7.1.tar.gz
tar xzf 1.7.1.tar.gz
cd ngrok-1.7.1


# log "code.google.com/p/log4go"  =>  log "github.com/alecthomas/log4go"
# this file has issue if not edit !!!
perl -i.bak -pe ' s|.*code.*google.com.*|	log "github.com/alecthomas/log4go"|  '   src/ngrok/log/logger.go


wget -c https://studygolang.com/dl/golang/go1.7.6.linux-amd64.tar.gz
ls  go1.7.6.linux-amd64.tar.gz
tar xzf go1.7.6.linux-amd64.tar.gz
 


##############################
### gen pem and secret key ###
##############################
openssl genrsa -out base.key 2048
openssl req -new -x509 -nodes -key base.key -days 10000 -subj "/CN=$NGROK_DOMAIN" -out base.pem
openssl genrsa -out server.key 2048
openssl req -new -key server.key -subj "/CN=$NGROK_DOMAIN" -out server.csr
openssl x509 -req -in server.csr -CA base.pem -CAkey base.key -CAcreateserial -days 10000 -out server.crt

cp assets/client/tls/ngrokroot.crt  assets/client/tls/ngrokroot.crt.old 
cp base.pem assets/client/tls/ngrokroot.crt



#############################
### to build using golang ### 
#############################
#cd go
export GOROOT=`pwd`/go

export PATH=$GOROOT/bin:$PATH

go version

rm -rf bin/* 

make clean  1>&2 >/dev/null

# build linux
export GOOS=linux; export GOARCH=amd64; export CGO_ENABLED=0
make release-server release-client

# build arm 
export GOARM=7
export GOARCH=arm 
export GOOS=linux
make release-client

# build win 
export GOOS=windows;export GOARCH=amd64;export CGO_ENABLED=0
make release-client

# build darwin
export CGO_ENABLED=0; export GOOS=darwin; export GOARCH=amd64
make release-client

