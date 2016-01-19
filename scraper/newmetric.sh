if [ -z "$1" ]; then
  echo "Usage: $0 <metric>"
  exit 1
fi

./blah.py 0 $1 data/* > $1.json
gsutil cp $1.json  gs://renature-metrics-data/
