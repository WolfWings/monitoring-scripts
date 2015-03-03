#!/bin/bash
#
# S.M.A.R.T. Drive Monitoring Script
#
# Copyright (C) 2015 - Wolf <wolfwings@gmail.com>
#
# Based on research data and blogs posted by BackBlaze regarding
# which S.M.A.R.T. properties correlate most strongly with drive
# failure in consumer hard drives.
#
# Licensed under the MIT License
#
# Requirements:
#       Software     Reason
#       bash 4.x     Associative Arrays
#       awk          does not use any GNU extensions
#       hdparm       serial number
#       smartctl     SMART attributes)

# E-Mail settings, who to contact, who to send as, subject.

declare -A EMAIL
EMAIL[FROM]='serverstatus@example.com'
EMAIL[TO]='serveradmin@example.com'
EMAIL[SUBJECT]='Daily Hard Drive S.M.A.R.T. Stats'

# Drive Header line, all the <TH> tags!

DRIVESHEADER='<tr><th>Cable</th><th colspan="2">Position</th><th>Status</th></tr>'

# The drive-specific strings sent to 'identify' each drive in the report.
# The default uses cable color and position in the case.
# If you change what you use here, update the header as well.
# The 'key' is the Serial Number of the drive.

declare -A DRIVES
DRIVES[14340D067A57]='<td style="background:#F50">&nbsp;</td><td>Rear</td><td>Lower</td>'
DRIVES[S321J9DFB00613]='<td style="background:#000">&nbsp;</td><td>Rear</td><td>Upper</td>'
DRIVES[S321J9DFB00608]='<td style="background:#FFF">&nbsp;</td><td>Front</td><td>Lower</td>'
DRIVES[S321J9DFB00625]='<td style="background:#00F">&nbsp;</td><td>Front</td><td>Upper</td>'

# The possible 'deaths' a drive can be subjected to.
# ANY non-zero value for the 'raw' value will be reported in the e-mail.
declare -A DEATHS
DEATHS[5]='Reallocated Sectors'
DEATHS[187]='Uncorrectable Errors'
DEATHS[188]='Command Timeouts'
DEATHS[197]='Pending Sector Count'
DEATHS[198]='Offline Uncorrectable'

# Build the awk script to filter for the list of deaths.
function join { local IFS="$1"; shift; echo "$*"; }
DEATHSAWK="/(^| )($(join '|' ${!DEATHS[@]}))"
DEATHSAWK="${DEATHSAWK}"' .{23} [-P][-O][-S][-R][-C][-K]'
DEATHSAWK="${DEATHSAWK}"'(   [0-9]{3}){3}    .... [0-9]+/ '
DEATHSAWK="${DEATHSAWK}"'{if ($NF != "0") print $1; }'

# Function called for each drive to print the status
function print_drive {
	echo -n '<tr>'
	if [ ${DRIVES[$1]+known} ]; then
		echo -n "${DRIVES[$1]}"
	else
		echo -n '<td colspan="3">Unknown drive' "$1" '</td>'
	fi
	echo -n '<td>'
	if [ -z "${2}" ]; then
		echo '<p>OK</p>';
	else
		echo
		for FAIL in ${2}; do
			if [ ${DEATHS[${FAIL}]+known} ]; then
				echo "<p><b>${DEATHS[${FAIL}]}</b></p>"
			else
				echo "<p><b><i><u>Unknown Failure: ${FAIL}</u></i></b></p>"
			fi
		done
	fi
	echo '</td></tr>'
}

declare -A SERIAL
declare -A SMART

# First gather all the statistics in parallel
for DRIVE in /dev/sd?; do
	SERIAL[${DRIVE}]=$(echo \
		$(hdparm -i ${DRIVE} \
		| awk '/SerialNo=/ { split($0, a, "SerialNo="); print a[2]; }'\
		) \
	&)
	SMART[${DRIVE}]=$(echo "$(smartctl -f brief -A ${DRIVE} | awk "${DEATHSAWK}")" &)
done

# Now wait for all the smartctl, hdparm, and awks to finish...
wait

# And finally we generate the e-mail.
BODY=$(
	echo '<!DOCTYPE html>'
	echo '<html><head><title></title></head><body>'
	echo ${DRIVESHEADER}
	for DRIVE in /dev/sd?; do
		print_drive ${SERIAL[${DRIVE}]} "${SMART[${DRIVE}]}"
	done
	echo '</body></html>'
)

echo "${BODY}" | mail \
-a "From: ${EMAIL[FROM]}" \
-a "MIME-Version: 1.0" \
-a "Content-Type: text/html" \
-s "Subject: ${EMAIL[SUBJECT]}" \
"${EMAIL[TO]}"
