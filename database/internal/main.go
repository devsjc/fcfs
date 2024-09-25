package main

import (
    "github.com/golang-migrate/migrate/v4"
    _ "github.com/golang-migrate/migrate/v4/database/postgres"
    _ "github.com/golang-migrate/migrate/v4/database/sqlite"
    _ "github.com/golang-migrate/migrate/v4/source/file"
	"github.com/rs/zerolog/log"
)

func main() {
	m, err := migrate.New(
		"file://../migrations",
		"sqlite://./test.db",
	)
	if err != nil {
		log.Fatal().Msgf("failed to create migration instance: %v", err)
	}
	err = m.Up()
	if err != nil {
		log.Fatal().Msgf("failed to apply migrations: %v", err)
	}
}
