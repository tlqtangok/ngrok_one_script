#!/bin/bash
### copyright by Jidor Tang <tlqtangok@126.com>  ###

# this script do following things:

	# - download ngrok 1.7.1 src code
	# - download go 1.7.6 binary for linux amd64
	# - build out key and secret for a host ip
	# - change one go source code "log4go"'s location
	# - build ngrokd, ngrok clients, include "linux, arms, windows"

# after build, you can see your binary file under bin/*

if [ "$1" = "" ]; then
	echo "- error, input arg0 ip "
	exit 1
fi

export PUBLIC_IP=$1

#export PUBLIC_IP='algo.com'
export NGROK_DOMAIN=$PUBLIC_IP


### gen pem and secret key ###
openssl genrsa -out base.key 2048
openssl req -new -x509 -nodes -key base.key -days 10000 -subj "/CN=$NGROK_DOMAIN" -out base.pem
openssl genrsa -out server.key 2048
openssl req -new -key server.key -subj "/CN=$NGROK_DOMAIN" -out server.csr
openssl x509 -req -in server.csr -CA base.pem -CAkey base.key -CAcreateserial -days 10000 -out server.crt

cp assets/client/tls/ngrokroot.crt  assets/client/tls/ngrokroot.crt.old 
cp base.pem assets/client/tls/ngrokroot.crt



### to build using golang ### 
export GOROOT=`pwd`/go

export PATH=$GOROOT/bin:$PATH

go version

rm -rf bin/* 

make clean 

# build linux
make release-server release-client

# build arm 
export GOARM=7
export GOARCH=arm 
export GOOS=linux
make release-client

# build win 
export GOOS=windows;export GOARCH=amd64;export CGO_ENABLED=0
make release-client
