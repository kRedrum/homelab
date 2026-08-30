#!/bin/sh

# Set your ntfy topic here
NTFY_TOPIC="<NTFY_TOPIC>"

zpool status |grep -v scan | grep -v repaired > /tmp/zpool-status.txt

diff /opt/zfs/normal-zpool-status-output.txt /tmp/zpool-status.txt > /tmp/zpool-diff.txt

if test -s /tmp/zpool-diff.txt; then
    # 1. Send the email
    (
    echo "Possible zpool error on `hostname` -- 'zpool status' output differs"
    echo "from baseline. Differences:"
    echo " "
    cat /tmp/zpool-diff.txt
    echo " "
    echo "zpool status output:"
    echo " "
    cat /tmp/zpool-status.txt
    ) | /bin/mail -r "akitlosz2000@gmail.com" -s "zpool status anomaly on `hostname` `date`" akitlosz2000@gmail.com

    # 2. Send the ntfy push notification with icons
    curl \
        -H "Title: ZFS Pool Anomaly on $(hostname)" \
        -H "Tags: rotating_light,warning,hdd" \
        -H "Priority: high" \
        -d "Possible zpool error on $(hostname). Output differs from baseline. Check your email for the full status diff." \
        "https://ntfy.sh/${NTFY_TOPIC}"
fi

rm -f /tmp/zpool-status.txt /tmp/zpool-diff.txt#!/bin/sh

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
) | /bin/mail -r "akitlosz2000@gmail.com" -s "zpool status anomaly on `hostname` `date`" akitlosz2000@gmail.com

rm -f /tmp/zpool-status.txt /tmp/zpool-diff.txt