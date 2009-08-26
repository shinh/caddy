#!/bin/sh

mkdir -p executors
rm -rf sag.tgz sag executors/*
wget http://golf.shinh.org/sag.tgz
tar -xvzf sag.tgz
mv sag/s/* executors
perl -i -p -e 's@/golf/local\S*/@@g' executors/*
perl -i -p -e 's@\.\./local\S*/@@g' executors/*
perl -i -p -e 's@export.*@# $&@' executors/*
perl -i -p -e 's@dmd.*-g@dmd -g@' executors/_d
perl -i -p -e 's@dmd.*-c@dmd -c@' executors/di
perl -i -p -e 's@bf@beef@' executors/bf
perl -i -p -e 's@/usr/local/bin/@@' executors/grb
