FROM golang:alpine AS build-env

WORKDIR /go/src/tailscale

COPY tailscale/go.mod tailscale/go.sum ./
RUN go mod download

COPY tailscale .

ARG TARGETARCH
RUN cd /go/src/tailscale/cmd/derper/ && GOARCH=$TARGETARCH CGO_ENABLED=0 go build -ldflags "-s -w" -o /derper

FROM alpine:3.18

RUN apk add --no-cache ca-certificates

ENV ADDR=:443 \
    HTTP_PORT=80 \
    STUN_PORT=3478 \
    HOSTNAME= \
    CERTS_DIR=/app/certs/ \
    CONFIG_PATH= \
    CERTMODE=manual \
    STUN_ENABLE=true \
    DERP_ENABLE=true \
    VERIFY_CLIENTS=false \
    VERIFY_CLIENT_URL= \
    DEV=false \
    TS_DEBUG_KEY_PATH=

WORKDIR /app
RUN mkdir -p /app/certs

COPY --from=build-env /derper /app/derper

ENTRYPOINT ["sh", "-c", "/app/derper \
    --c=${CONFIG_PATH} \
    --a=${HTTPS_PORT} \
    --http-port=${HTTP_PORT} \
    --stun-port=${STUN_PORT} \
    --certmode=${CERTMODE} \
    --certdir=${CERTS_DIR} \
    --hostname=${HOSTNAME} \
    --stun=${STUN_ENABLE} \
    --derp=${DERP_ENABLE} \
    --verify-clients=${VERIFY_CLIENTS} \
    --verify-client-url=${VERIFY_CLIENT_URL} \
    --dev=${DEV}"]
