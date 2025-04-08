#!/bin/bash
docker build -t dlvoy/drone-portainer-redeploy-plugin:latest .
docker push dlvoy/drone-portainer-redeploy-plugin:latest