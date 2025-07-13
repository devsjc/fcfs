FROM golang:1.24 AS build

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

