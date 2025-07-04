# FCFS Data Platform

**Reimagining OCF's Data Platform for Performance and Useability**

## Installation

Install using docker

```bash
$ docker build . --tag api:local
```

or via Go

```
$ go install github.com/devsjc/fcfs
```

## Documentation

### External schema (replacing `pydantic` in the old `datamodel`)

The Data Platform defines a strongly typed _data contract_ as its external interface. This is the
API that any external clients have to use to interact with the platform. The schema for this is
defined via Protocol Buffers in `proto/ocf/dp`.

Boilerplate code for client and server implementations is generated in the required language from
these `.proto` files using the `protoc` compiler.

Changes to the schema modifies the data contract, and will require client and server
implementations to regenerate their bindings and update their code. As such they should be made
with purpose and care.

**Generating bindings**

```
make gen-ext
```

This will populate the `protogen` directory with language-specific bindings for implementations
of server and client code.

These bindings are then used to implement the server code in `src/internal/service/server.go`.
They should also be imported or copied into external codebases to create type-safe and contract-bound clients.

The server then implements custom logic to serve the generated interface
via the use of an abstraction, representing a data repository.
This interface - or boundary layer - between the API logic and the data layer
is defined in `src/internal/models.go`, along with other models relevant to the internal logic of the API.

By separating the layers like this,
the API can be easily tested and extended without needing to change the underlying data layer;
similarly, data layers can be swapped out or modified without breaking the API contract.

```
+----------+                     +----------+                             + - - - - - - - - +
|  Client  |  <--- GRPC API -->  |  Server  |  <-- Database Interface --> : Data Repository :
+----------+                     +----------+                             + - - - - - - - - +

|<--Uses generated bindings-->|  |<------------Logic in the the API repository------------->|          
```

[Postgres](https://www.postgresql.org/) is the only planned concrete data repository implementation,
but there is also a dummy repository for testing purposes. These are found in `src/internal/repository`.

## Example usage

```bash
$ go run src/cmd/main/go
```

