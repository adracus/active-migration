#!/bin/bash


if [ "$1" = "generate" ]; then
	echo $@
	shift
	dart /opt/adracus/ActiveMigration/bin/generator.dart $@
else
	if [ "$1" = "migrate" ]; then
		shift
		dart /opt/adracus/ActiveMigration/bin/migrator.dart $@
	else
		echo "Use either amg generate or amg migrate"
		h1 = $(dart /opt/adracus/ActiveMigration/bin/migrator.dart -help)
		h2 = $(dart /opt/adracus/ActiveMigration/bin/generator.dart -help)
		echo $h1
		echo $h2
	fi
fi
