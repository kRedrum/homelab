#!/bin/sh

zpool status |grep -v scan | grep -v repaired > /tmp/zpool-status.txt

diff /opt/zfs/normal-zpool-status-output.txt /tmp/zpool-status.txt > /tmp/zpool-diff.txt

test -s /tmp/zpool-diff.txt && (
echo "Possible zpool error on `hostname` -- 'zpool status' output differs"
echo "from baseline. Differences:"
echo " "
cat /tmp/zpool-diff.txt
echo " "
echo "zpool status output:"
echo " "
cat /tmp/zpool-status.txt
) | /bin/mail -r "<email>" -s "zpool status anomaly on `hostname` `date`" <email> 

rm -f /tmp/zpool-status.txt /tmp/zpool-diff.txt