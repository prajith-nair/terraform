#!/bin/bash

echo "Hello Terraformers!, Welcome to V2.0" > index.html
nohup busybox httpd -f -p ${server_port} &
