#!/bin/bash

mkdir -p /opt/dmarc-visualizer/parsedmarc/{input,output}
chmod a+w /opt/dmarc-visualizer/parsedmarc/output
mkdir -p /opt/dmarc-visualizer/elasticsearch/data
chmod a+w /opt/dmarc-visualizer/elasticsearch/data

podman build --tag grafana:parsedmarc ./grafana/
podman build --tag parsedmarc ./parsedmarc/

podman play kube --replace visualizer.yaml
