#!/bin/bash

apt-get update
apt-get -y install netcat

go install github.com/go-delve/delve/cmd/dlv@latest

function test_conn() {
	nc -z -v  $1 9042;
	while [ $? -ne 0 ];
		do echo "CQL port not ready on $1";
		sleep 10;
		nc -z -v  $1 9042;
	done
}

export GO111MODULE=on \
    CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=amd64

# Move to working directory /build
mkdir /build
cd /build

cp /source/go.mod .
cp /source/go.sum .
cp -r /source/proxy ./proxy
cp -r /source/antlr ./antlr
ls .

# Build the application
go build -gcflags="all=-N -l" -o main ./proxy

# Copy binary from /build to /dist
cp /build/main /main

# Wait for clusters to be ready
test_conn 192.168.100.101
test_conn 192.168.100.102

export PROXY_QUERY_ADDRESS="0.0.0.0"
export PROXY_METRICS_ADDRESS="0.0.0.0"
export ORIGIN_CASSANDRA_USERNAME="foo"
export ORIGIN_CASSANDRA_PASSWORD="foo"
export TARGET_CASSANDRA_USERNAME="foo"
export TARGET_CASSANDRA_PASSWORD="foo"
export ORIGIN_CASSANDRA_CONTACT_POINTS="192.168.100.101"
export ORIGIN_CASSANDRA_PORT="9042"
export TARGET_CASSANDRA_CONTACT_POINTS="192.168.100.102"
export TARGET_CASSANDRA_PORT="9042"
export PROXY_QUERY_PORT="9042"

# Command to run
dlv --listen=:2345 --headless=true --api-version=2 exec /main