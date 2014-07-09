#!/bin/bash


case "$1" in
	"generate")
		shift
		dart /opt/adracus/ActiveMigration/bin/generator.dart $@
	;;
	"migrate")
		shift
		dart /opt/adracus/ActiveMigration/bin/migrator.dart $@
	;;
	"update")
		wget -qO- https://raw.githubusercontent.com/Adracus/ActiveMigration/master/bin/install.sh | sudo bash
	;;
	*) echo "Use either migrate, generate or sudo amg update"
esac
