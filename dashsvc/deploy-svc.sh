set -e

gcloud --project renature-dashboard preview app modules delete default --version $(gcloud --project renature-dashboard preview app modules list | perl -pe 's/ +/\t/g' | cut -f2 | grep 2015 | head -n1) --quiet
gcloud --project renature-dashboard preview app deploy --promote app.yaml --quiet
