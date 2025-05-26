#!/bin/bash

mkdir -p /opt/dmarc-visualizer/parsedmarc/{input,output}
chmod a+w /opt/dmarc-visualizer/parsedmarc/output
mkdir -p /opt/dmarc-visualizer/elasticsearch/data
chmod a+w /opt/dmarc-visualizer/elasticsearch/data

podman build --tag grafana:parsedmarc ./grafana/
podman build --tag parsedmarc ./parsedmarc/

podman pod create --replace --name dmarc-visualizer -p 3000:3000

podman run -d --name dmarc-visualizer-elasticsearch \
  --pod dmarc-visualizer \
  --replace \
  -e TERM=xterm \
  -e discovery.type=single-node \
  -e xpack.security.http.ssl.enabled=false \
  -v /opt/dmarc-visualizer/elasticsearch/data:/usr/share/elasticsearch/data \
  docker.elastic.co/elasticsearch/elasticsearch@sha256:fefc5c834958f142371b0f64b6cbd77e00c3d53c83f87842e7cd17ce2fd1fa87 \
  eswrapper

podman exec -it dmarc-visualizer-elasticsearch elasticsearch-setup-passwords auto

podman run -d --name dmarc-visualizer-parsedmarc \
  --pod dmarc-visualizer \
  --replace \
  -e TERM=xterm \
  -v /opt/dmarc-visualizer/parsedmarc/input:/input:ro \
  -v /opt/dmarc-visualizer/parsedmarc/output:/output \
  localhost/parsedmarc:latest \
  /usr/local/bin/parsedmarc -c /parsedmarc.ini /input/* --debug

podman run -d --name dmarc-visualizer-grafana \
  --pod dmarc-visualizer \
  --replace \
  -e TERM=xterm \
  -e GF_INSTALL_PLUGINS=grafana-piechart-panel,grafana-worldmap-panel \
  -e GF_AUTH_ANONYMOUS_ENABLED=true \
  localhost/grafana:parsedmarc
