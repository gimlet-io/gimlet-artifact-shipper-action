FROM alpine:3.13.4

RUN apk --no-cache add bash curl git openssl

WORKDIR /action

RUN curl -L https://github.com/gimlet-io/gimlet-cli/releases/download/v0.7.0/gimlet-$(uname)-$(uname -m) -o /usr/local/bin/gimlet && \
      chmod +x /usr/local/bin/gimlet

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
