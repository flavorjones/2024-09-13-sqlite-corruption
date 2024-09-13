#!/usr/bin/env bash

result=$(sqlite3 storage/development.sqlite3 "pragma integrity_check;")

if [[ "$result" = "ok" ]] ; then
  echo OK
else
  echo "$result"
  exit 1
fi
