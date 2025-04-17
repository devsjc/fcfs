.PHONY: run-docker-db run-api

gen:
	uv run go generate ./...

run-db:
	docker build -f src/internal/repository/postgres/infra/Containerfile src/internal/repository/postgres/infra -t fcfs-pgdb:local && docker run --rm -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=postgres -p "5400:5432" fcfs-pgdb:local

run-api:
	DATABASE_URL=postgres://postgres:postgres@localhost:5400/postgres DATABASE_TYPE=postgres go run src/cmd/main.go

run-grpc-client:
	grpcui -plaintext localhost:50051
