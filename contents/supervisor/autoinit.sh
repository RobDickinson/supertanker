#!/bin/sh

# create data directories
mkdir -p /data/graylog/journal
mkdir -p /data/graylog/libnative
mkdir -p /data/mongodb
mkdir -p /data/opensearch

# NOTE: this can't be done as part of the dockerfile because /data will be remapped to a persistent volume