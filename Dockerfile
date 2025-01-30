FROM golang:alpine AS builder

RUN apk add --no-cache fuse-dev git libc-dev clang clang-dev

RUN git clone https://github.com/distribyted/distribyted.git /app

WORKDIR /app

RUN rm -rf vendor go.mod go.sum

RUN sed -ie 's/billziss-gh/winfsp/g' fuse/*.go

RUN go mod init github.com/distribyted/distribyted && go mod tidy

RUN CXX=clang++ go build -o distribyted cmd/distribyted/main.go

RUN mkdir /tmp/lib && cp /lib/ld-musl-* /tmp/lib

FROM scratch

COPY --chown=65532 --from=builder /app/distribyted /app/distribyted
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

COPY --from=builder /tmp/lib/ /lib/
COPY --from=builder /usr/lib/libstdc++.so.6 /usr/lib/libstdc++.so.6
COPY --from=builder /usr/lib/libgcc_s.so.1 /usr/lib/libgcc_s.so.1

VOLUME /config

EXPOSE 4444/tcp
EXPOSE 36911/tcp

CMD [ "/app/distribyted", "-config", "/config/config.yaml" ]
