#!/usr/bin/env bash
mkdir -p Payload
cp -r $1 Payload/
zip -r9q tmp.zip Payload
rm -r Payload
mv tmp.zip $2