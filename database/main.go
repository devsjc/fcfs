package main

import (
    "github.com/golang-migrate/migrate/v4"
    _ "github.com/golang-migrate/migrate/v4/database/postgres"
    _ "github.com/golang-migrate/migrate/v4/source/file"
	"log"
)

func main() {
    m, err := migrate.New(
		"file://migrations",
        "postgres://localhost:5432/database?sslmode=disable"
	)
    m.Steps(2)
}
