# monitoring-scripts
A collection of monitoring scripts used to keep tabs on a server and investigate issues on a remote server.

## cron/hdsmart.sh
Intended to go in /etc/cron.daily or the like, this script checks the output of smartctl, pairing the output up against
serial numbers (fetched via hdparm) to allow for arbitrary descriptions of the drive health. It ignores many S.M.A.R.T.
attributes, focussing entirely on the five that BackBlaze has shown as near-universal indicators of failing drives.

As this script is based on the [BackBlaze findings][], it is targetted at consumer-level drives which are at the upper-
most tier of storage capacity available when they were manufactured, and is also not verified as appropriate for SAS or
other *enterprise* hardware.

The top few lines of the script are where you set the e-mail address details for the report, hard drive serial numbers,
and which SMART attributes you care about. If any of them return non-zero in the 'raw' value, the script considers that
a failing drive state and lists the descriptive reason in the e-mail, otherwise it lists 'OK' for the drive status.

[BackBlaze findings]: https://www.backblaze.com/blog/hard-drive-smart-stats/
