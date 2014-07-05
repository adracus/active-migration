#!/bin/bash


if [ "$1" = "generate" ]; then
	shift
	dart /opt/adracus/ActiveMigration/bin/generator.dart $@
else
	if [ "$1" = "migrate" ]; then
		shift
		dart /opt/adracus/ActiveMigration/bin/migrator.dart $@
	else
		echo "Use either amg generate or amg migrate"
	fi
fi
