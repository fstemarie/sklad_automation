#! /usr/bin/fish
# This script will deploy the backup scripts.

set dst "/data/automation"
echo "-- Copying scripts to $dst"
rm -fr $dst
mkdir -p "$dst"
cp -R ./src/*.fish "$dst"
if test $status -ne 0
    echo "-- Error while copying scripts"
    exit 1
end

set dst "/data/automation/backup"
echo "-- Copying docker update scripts to $dst"
mkdir -p "$dst"
cp -R ./src/backup/* "$dst"
if test $status -ne 0
    echo "-- Error while copying backup scripts"
    exit 1
end

set dst "/data/automation/docker"
echo "-- Copying backup scripts to $dst"
mkdir -p "$dst"
cp -R ./src/docker/* "$dst"
if test $status -ne 0
    echo "-- Error while copying backup scripts"
    exit 1
end

set dst "/data/automation/tools"
echo "-- Copying tools to $dst"
mkdir -p "$dst"
cp -R ./src/tools/* "$dst"
if test $status -ne 0
    echo "-- Error while copying tool scripts"
    exit 1
end

set dst "/data/config/logrotate"
echo "-- Copying logrotate config to $dst"
mkdir -p "$dst"
cp -R ./src/logrotate/* "$dst"
if test $status -ne 0
    echo "-- Error while copying backup scripts"
    exit 1
end

echo "-- Scripts copied successfully"
