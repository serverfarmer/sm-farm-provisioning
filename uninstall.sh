#!/bin/sh

if [ -h /usr/local/bin/sf-authorize-key ]; then
	rm -f /usr/local/bin/sf-authorize-key
fi

if [ -h /usr/local/bin/sf-provision ]; then
	rm -f /usr/local/bin/sf-provision
fi
