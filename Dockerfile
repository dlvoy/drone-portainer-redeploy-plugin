FROM alpine
ADD redeploy.sh /bin/
RUN chmod +x /bin/redeploy.sh
RUN apk -Uuv add curl jq bash ca-certificates
ENTRYPOINT /bin/redeploy.sh
