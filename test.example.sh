docker run --rm \
  -e PLUGIN_URL=https://example.com \
  -e PLUGIN_STACK=stack-name \
  -e PLUGIN_API_KEY="ptr_PORTAINER_ACCESS_TOKEN=" \
  -e PLUGIN_DEBUG=true \
  dlvoy/drone-portainer-redeploy-plugin