gsutil cp -a public-read static/code.coffee gs://renature-static-assets/
gsutil setmeta -h Cache-Control:no-cache gs://renature-static-assets/code.coffee
