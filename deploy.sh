#!/usr/bin/env bash

echo "start deploy"

../../../bin/hugo
cd public
rm robots.txt
cd ..
scp -pr public/. listen@139.196.57.128:/home/listen/secret

rm -rf public/

echo "deploy complete"
