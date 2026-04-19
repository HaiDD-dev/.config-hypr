#!/usr/bin/env bash
inotifywait -qq -e close_write,modify /tmp/qs_netspeed 2>/dev/null