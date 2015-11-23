#!/bin/bash
set -e
: ${H2O_PORT:='80 443'}
if [ -z "$H2O_PORT" ]; then
    echo >&2 "error: missing required H2O_PORT environment variable"
    exit 1
fi

ports=()
for v in  $H2O_PORT; do
    ports=(${ports[@]} "--port")
    ports=(${ports[@]} "$v")
done

cp /app/h2o.conf /h2o/h2o.conf

env \
    | cut -d = -f 1 \
    | xargs -n 1 -I % perl -i -lpe 's{__%__}{$ENV{%}}g' /h2o/h2o.conf

exec start_server ${ports[@]} -- h2o -c $@
