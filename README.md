# drone-portainer-redeploy-plugin

Drone CI/CD plugin to re-deploy file based Portainer stack

based on [Example Bash Plugin for Drone CI/CD service.](https://github.com/go-training/drone-bash-plugin)

## Usage

```yml
---
pipeline:
  redeploy:
    image: dlvoy/drone-portainer-redeploy-plugin
    url: https://example.com
    stack: stack-name
    api_key: ptr_PORTAINER_ACCESS_TOKEN=
    debug: false
```

- `url` URL of your portainer repository
- `stack` name of stack to redeploy
- `api_key` access token to portainer, configured at your repository, at '/account' page
- `debug` if set to `true` display stack contents

**IMPORTANT!!**
- Env variables are not set/updated
- `debug: true` leak whole stack contents, and may include secrets if presents in stack YAML!!!!

## Building

```sh
# login your dockerhub account.
$ ./build-and-deploy.sh
```
