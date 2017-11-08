# http&#95;data&#95;hash

This is a data&#95;hash function for use as a Hiera 5 backend.  
It connects to a http(s) backend and retrieves hiera in JSON
format.

## http(s) service

An example http service is a simple python script with node files in a hosts directory.
The script is provided in the examples directory.

## hiera configuration

A sample hiera.yaml is provided in the examples directory.

## Errors

Errors are logged at the debug level.
To change the level, edit `/etc/puppetlabs/puppetserver/logback.xml` and change the default `INFO` to `DEBUG`.

Errors will be located in `/var/log/puppetlabs/puppetserver/puppetserver.log` and be prefaced with `http_data_hash`
