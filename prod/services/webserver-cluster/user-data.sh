#!/bin/bash

cat > index.html <<EOF
<h1>Hello Terraform Programmers, Welcome to Production Environment! </h1>
<p>DB Address: ${db_address} </p>
<p>DB Port: ${db_port} </p>
EOF
nohup busybox httpd -f -p ${server_port} &
