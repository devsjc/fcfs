/// This file is used to generate SDK files from proto definitions.
/// Requires protoc tool installed: https://grpc.io/docs/protoc-installation/
// See also: https://grpc.io/docs/languages/go/quickstart/#prerequisites
package proto

//go:generate go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
//go:generate go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
//go:generate npm install -g @protobuf-ts/plugin @redocly/cli
//go:generate protoc --version

//go:generate protoc --go_out=../internal/models --go_opt=paths=source_relative api.proto
//go:generate protoc --go-grpc_out=require_unimplemented_servers=false:../internal/models --go-grpc_opt=paths=source_relative api.proto
//go:generate protoc --ts_out=../sdk/javascript --ts_opt=output_javascript api.proto
//go:generate protoc --python_betterproto_out=../sdk/python api.proto
//go:generate protoc -I=. --openapi_out=../sdk/html api.proto
//go:generate redocly build-docs ../sdk/html/openapi.yaml --output ../sdk/html/index.html
