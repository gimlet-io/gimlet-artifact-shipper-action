FROM alpine:3.15.4

RUN apk --no-cache add bash curl git openssl jq

WORKDIR /action

RUN curl -L https://github.com/gimlet-io/gimlet-cli/releases/download/cli-v0.18.0-rc.6/gimlet-$(uname)-$(uname -m) -o /usr/local/bin/gimlet && chmod +x /usr/local/bin/gimlet

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
