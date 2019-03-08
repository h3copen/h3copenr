#!/bin/sh
#TODO: add build script

set -x
ln -s /home/travis/gopath/src/github.com/h3copenr/comwaresdk /home/travis/gopath/src/github.com/h3copen/comwaresdk
ln -s /home/travis/gopath/src/github.com/h3copenr/h3cfibservice /home/travis/gopath/src/github.com/h3copen/h3cfibservice
cd /home/travis/gopath/src/github.com/h3copen
cd /home/travis/gopath/src/github.com/h3copen/h3cfibservice/fibhandler
go build
ls
