#!/bin/sh
# nginx.image.tag has no Chart.AppVersion fallback (see chart/hyrax/values.yaml), so it must be bumped by hand alongside appVersion.
set -e

app_version=$(yq '.appVersion' chart/hyrax/Chart.yaml)
nginx_tag=$(yq '.nginx.image.tag' chart/hyrax/values.yaml)

if [ "$app_version" != "$nginx_tag" ]; then
  echo "chart/hyrax/values.yaml's nginx.image.tag ($nginx_tag) doesn't match chart/hyrax/Chart.yaml's appVersion ($app_version)."
  echo "Update nginx.image.tag to $app_version."
  exit 1
fi

echo "nginx.image.tag matches appVersion ($app_version)."
