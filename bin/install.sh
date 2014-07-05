#!/bin/sh

echo "Installing the ActiveMigration tools"
mkdir -p /opt/adracus
cd /opt/adracus
rm -f -rf ActiveMigration
git clone https://github.com/Adracus/ActiveMigration.git
cd ActiveMigration
pub get
cd /usr/bin
rm -f amg
ln -s /opt/adracus/ActiveMigration/bin/amg.sh amg
