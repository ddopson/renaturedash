#!/bin/bash
set -e

BASEDIR=/home/ddopson/renaturedash/scraper
TMP=$BASEDIR/tmp
LOCKFILE=/run/lock/renature-scraper.lock
GSUTIL=/home/ddopson/google-cloud-sdk/bin/gsutil

mkdir -p $TMP

if [ -z "$MAGIC_ENTRYPOINT_ENV_VAR" ]; then
  cd $BASEDIR
  export MAGIC_ENTRYPOINT_ENV_VAR=yup
  flock --timeout=0 $LOCKFILE $BASEDIR/sync.sh \
    || (echo 'Locked'; exit 1)
  exit
fi


echo "Ensuring Login."
curl -s -X POST --data .p=P3Auth --data .u= --data .q= --data x=45 --data y=19 192.168.1.44:8888/login.html \
  >/dev/null

echo "Getting download.html"
curl -s http://192.168.1.44:8888/download.html \
  > $TMP/download.html

cat $TMP/download.html \
  | perl -pe 's/<tr>/\n/g' \
  | perl -ne 'm/.*(data[-_]\d+[.]csv).*>(\d+) bytes.*/ && print "$1\t$2\n"' \
  | sort \
  > $TMP/want.txt
  
ls -lG data \
  | perl -pe 's/ +/\t/g'  \
  | cut -f8,4 \
  | perl -pe 's/(.*)\t(.*)/$2\t$1/' \
  | sort \
  > $TMP/haz.txt

echo -n "Have: "
comm -1 -2 $TMP/want.txt $TMP/haz.txt | wc -l

echo "Missing/Broken: "
comm -3 $TMP/want.txt $TMP/haz.txt

# Broken files ar elisted twice, so don't include them in missing.txt
comm -3 -2 $TMP/want.txt $TMP/haz.txt | cut -f1 > $TMP/missing.txt

for f in $(cat $TMP/missing.txt); do
  echo "Downloading $f"
  curl -s 192.168.1.44:8888/$f > $TMP/temp.csv || exit
  mv $TMP/temp.csv data/$f
done

curl -s 'renature-dashboard.appspot.com/query?metric=R1_TOP_AVG_CAL' > $TMP/latest.txt
PY_LATEST_TIME=$(cat $TMP/latest.txt)
echo "PY_LATEST_TIME=$PY_LATEST_TIME"

for metric in R1_TOP_AVG_CAL R1_BOT_AVG_CAL T1_VOLUME R2_BOT_AVG_CAL HEATER_OUTPUT_AVERAGE R1_MID_AVG_CAL; do
  for u in $(./blah.py $PY_LATEST_TIME $metric $(cat $TMP/missing.txt | perl -pe 's/^/data\//')); do
    echo "Curling $u"
    curl -s "$u"
    echo
  done
done


hour=$(( $(date +%s) / 3600))
last=$(cat $TMP/last_rsync || echo 0)
if [ $hour != $last ]; then
  echo "$hour" > $TMP/last_rsync
  $GSUTIL rsync data/ gs://renature-metrics-backup/
fi
