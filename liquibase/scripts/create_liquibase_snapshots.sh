#!/bin/bash
#
#  This Source Code Form is subject to the terms of the Mozilla Public License,
#  v. 2.0. If a copy of the MPL was not distributed with this file, You can
#  obtain one at http://mozilla.org/MPL/2.0/. OpenMRS is also distributed under
#  the terms of the Healthcare Disclaimer located at http://openmrs.org/license.
#
#  Copyright (C) OpenMRS Inc. OpenMRS is a registered trademark and the OpenMRS
#  graphic logo is a trademark of OpenMRS Inc.
#

#
#  This script creates Liquibase snapshots from an OpenMRS database. It also creates the library
#  required by openmrs-core/liquibase/scripts/fix_liquibase_snapshots.sh (which is normally run next).
#
#  Run this script from the openmrs-core/liquibase folder.
#
#  The snapshots are written to the openmrs-core/liquibase/snapshots folder.
#

function build_openmrs_liquibase() {
	mvn clean install
}

function delete_snapshots() {
	echo "[INFO] deleting old Liquibase snapshots..."
	find ./snapshots/ -name "*SNAPSHOT*" -exec rm -rf {} \;	
}

function create_snapshots() {
	echo "[INFO] creating new Liquibase snapshots..."
	mvn \
	  -DoutputChangelogfile=liquibase-schema-only-SNAPSHOT.xml \
	  -Dusername="${1}" \
	  -Dpassword="${2}" \
	  liquibase:generateChangeLog

	mvn \
	  -DdiffTypes=data \
	  -DoutputChangelogfile=liquibase-core-data-SNAPSHOT.xml \
	  -Dusername="${1}" \
	  -Dpassword="${2}" \
	  liquibase:generateChangeLog	
}

function echo_usage() {
	echo "usage: . scripts/create_liquibase_snapshots.sh <username> <password>"
}

if [ "${1}" == "" ] || [ "${2}" == "" ]; then
	echo_usage
else
	delete_snapshots

	# The library openmrs-liquibase-X.Y.Z.-SNAPSHOT-jar-with-dependencies.jar is required
	# for running the next script (i.e. openmrs-core/liquibase/fix_liquibase_snapshots.sh).  
	#
	# However, building the library after running this script fails as the Liquibase
	# snapshot files generated by this script do not contain the OpenMRS license header.
	#
	# Hence the library is being built after deleting old snapshot files and before running
	# the script openmrs-core/liquibase/fix_liquibase_snapshots.sh.
	#
	build_openmrs_liquibase

	create_snapshots "${1}" "${2}"
fi

