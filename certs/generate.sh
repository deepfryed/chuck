#!/bin/bash

subject="/C=AU/ST=VIC/L=Melbourne/O=ChuckProxy/OU=ChuckProxy Security/CN=chuckproxy.com"

openssl genrsa -out server.key 2048
openssl req -subj "$subject" -new -key server.key -out server.csr
openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
