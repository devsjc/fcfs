// Package postgres defines a client for a PostgreSQL database that conforms to the
// DatabaseRepository interface in models.go. It uses the sqlc package to generate
// type-safe Go code from pure SQL queries.
package postgres

import (
	"embed"
	"context"
	"os"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/jackc/pgx/v5/stdlib"
	"github.com/pressly/goose/v3"

	"github.com/devsjc/fcfs/api/src/internal"

	"github.com/rs/zerolog/log"
)

//go:generate sqlc generate
//go:embed sql/migrations/*.sql
var embedMigrations embed.FS

const migrationsDir = "sql/migrations"

type PostgresClient struct {
	pool *pgxpool.Pool
}

// // NewPostgresClient creates a new PostgresClient instance and connects to the database
func NewPostgresClient() *PostgresClient {
	pool, err := pgxpool.New(
		context.Background(), os.Getenv("DATABASE_URL"),
	)
	if err != nil {
		log.Fatal().Err(err).Msg("Unable to connect to database")
	}

	return &PostgresClient{pool: pool}
}

func Migrate(c *PostgresClient) error {
	goose.SetBaseFS(embedMigrations)
	err := goose.SetDialect("postgres")
	if err != nil {
		return err
	}
	db := stdlib.OpenDBFromPool(c.pool)
	err = goose.Up(db, migrationsDir)
	if err != nil {
		return err
	}
	err = db.Close()
	if err != nil {
		return nil
	}
	return nil
}

// GetActualYieldForLocations implements internal.DatabaseRepository.
func (p *PostgresClient) GetActualYieldForLocations(locIDs []string, timeUnix int64) ([]internal.DBActualLocalisedYield, error) {
	panic("unimplemented")
}

// GetActualYieldsForLocation implements internal.DatabaseRepository.
func (p *PostgresClient) GetActualYieldsForLocation(locID string) ([]internal.DBActualYield, error) {
	panic("unimplemented")
}

// GetPredictedYieldForLocations implements internal.DatabaseRepository.
func (p *PostgresClient) GetPredictedYieldForLocations(locIDs []string, timeUnix int64) ([]internal.DBPredictedLocalisedYield, error) {
	panic("unimplemented")
}

// GetPredictedYieldsForLocation implements internal.DatabaseRepository.
func (p *PostgresClient) GetPredictedYieldsForLocation(locID string) ([]internal.DBPredictedYield, error) {
	panic("unimplemented")
}

// Migrate implements internal.DatabaseRepository.
func (p *PostgresClient) Migrate() error {
	panic("unimplemented")
}

// Compile check to ensure that the DummyClient implements the DatabaseService interface.
var _ internal.DatabaseRepository = &PostgresClient{}
