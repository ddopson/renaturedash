gsutil cp -a public-read static/code.js gs://renature-static-assets/
gsutil setmeta -h Cache-Control:no-cache gs://renature-static-assets/code.js
