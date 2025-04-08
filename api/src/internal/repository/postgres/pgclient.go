// Package postgres defines a client for a PostgreSQL database that conforms to the
// DatabaseRepository interface in models.go. It uses the sqlc package to generate
// type-safe Go code from pure SQL queries.
package postgres

import (
	"database/sql"
	"github.com/pressly/goose/v3"
	_ "embed"
)

//go:generate sqlc generate
//go:embed sql/migrations/*.sql
var embedMigrations embed.FS

const migrationsDir = "sql/migrations"


