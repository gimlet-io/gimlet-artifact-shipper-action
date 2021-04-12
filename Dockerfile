FROM alpine:3.13

RUN apk --no-cache add curl git openssl

RUN curl -L https://github.com/gimlet-io/gimlet-cli/releases/download/v0.7.0/gimlet-$(uname)-$(uname -m) -o gimlet && \
      chmod +x gimlet

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
