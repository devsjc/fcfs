FROM golang:1.24 AS build

# Download protoc binary
ARG PROTOC_VERSION=23.3
RUN wget -q https://github.com/protocolbuffers/protobuf/releases/download/v31.1/protoc-31.1-linux-x86_64.zip -O /tmp/protoc.zip && \
    unzip -q /tmp/protoc.zip -d /usr/local/bin && \
    rm /tmp/protoc.zip

WORKDIR /go/src/app
COPY go.mod go.sum Makefile ./
COPY cmd/ cmd/
COPY internal/ internal/

RUN go mod download
RUN go mod verify
RUN go install tool
RUN make gen
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /go/bin/app cmd/main.go

FROM gcr.io/distroless/static-debian11 AS app

COPY --from=build /go/bin/app /
CMD ["/app"]

