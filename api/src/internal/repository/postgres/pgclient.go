// Package postgres defines a client for a PostgreSQL database that conforms to the
// DatabaseRepository interface in models.go. It uses the sqlc package to generate
// type-safe Go code from pure SQL queries.
package postgres

import (
	"context"
	"embed"
	"fmt"
	"math"
	"os"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/jackc/pgx/v5/stdlib"
	"github.com/pressly/goose/v3"
	"google.golang.org/grpc"

	models "github.com/devsjc/fcfs/api/src/internal/models"
	db "github.com/devsjc/fcfs/api/src/internal/repository/postgres/gen"

	"github.com/rs/zerolog/log"
)

//go:generate sqlc generate
//go:embed sql/migrations/*.sql
var embedMigrations embed.FS

const migrationsDir = "sql/migrations"

// capacityKWToMultiplier return a number, plus the index to raise 10 to the power to
// to get the resultant number of Watts, to the closest power of 3.
func capacityKWToMultiplier(capacityKw int64) (int16, int16, error) {
	if capacityKw < 0 {
		return 0, 0, fmt.Errorf("input capacity %d cannot be negative", capacityKw)
	}
	if capacityKw == 0 {
		return 0, 0, nil
	}

	currentValue := capacityKw * 1000 // Convert to Watts
	exponent := int16(0)
	const scaleFactor = 1000
	const halfScaleFactor = scaleFactor / 2
	const maxExponent = 18 // Limit to ExaWatts

	// Keep scaling up as long as the value exceeds the int16 limit
	for currentValue > int64(math.MaxInt16) {
		if exponent >= maxExponent {
			return 0, exponent, fmt.Errorf(
				"input represents a value greater than %d ExaWatts, which is not supported",
				math.MaxInt16,
			)
		}

		// Perform division with rounding: add half the divisor before dividing.
		nextValue := (currentValue + halfScaleFactor) / scaleFactor

		// Sanity check: If rounding resulted in 0 for a value that was previously > 0.
		// This is very unlikely with rounding unless the number is enormous and precision is lost,
		// but good to keep a check.
		if nextValue == 0 && currentValue > 0 {
			// Use exponent+3 as this would be the exponent if scaling completed
			return 0, exponent + 3, fmt.Errorf(
				"scaled value rounded to zero from large input %d at potential exponent %d",
				capacityKw, exponent+3)
		}

		currentValue = nextValue // Update currentValue with the rounded scaled value
		exponent += 3
	}

	// This is safe as currentValue is now less than or equal to int16 max
	resultValue := int16(currentValue)
	return resultValue, exponent, nil
}

type QuartzAPIPostgresServer struct {
	pool *pgxpool.Pool
}

// CreateSolarGsp implements proto.QuartzAPIServer.
func (q *QuartzAPIPostgresServer) CreateSolarGsp(ctx context.Context, req *models.CreateGspRequest) (*models.CreateLocationResponse, error) {
	log.Info().Msg("CreateSolarGsp called")
	// Establish a transaction with the database
	tx, err := q.pool.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("Failed to begin transaction: %v", err)
	}
	defer tx.Rollback(ctx)
	querier := db.New(tx)

	// Create a new location as a GSP
	params := db.CreateLocationParams{
		LocationTypeName:   "gsp",
		LocationName:       req.Name,
		Geom:   req.Geometry,
	}
	locationID, err := querier.CreateLocation(ctx, params)
	if err != nil {
		return nil, fmt.Errorf("Failed to create GSP: %v", err)
	}
	// Create a Solar source associated with the location
	capacity, prefix, err := capacityKWToMultiplier(req.CapacityKw)
	if err != nil {
		return nil, fmt.Errorf("Failed to convert capacity: %v", err)
	}
	sourceParams := db.CreateLocationSourceParams{
		LocationID:               locationID,
		SourceTypeName:           "solar",
		Capacity:                 capacity,
		CapacityUnitPrefixFactor: prefix,
		Metadata:                 []byte(req.Metadata),
	}
	_, err = querier.CreateLocationSource(ctx, sourceParams)
	if err != nil {
		return nil, fmt.Errorf("Failed to create source: %v", err)
	}
	err = tx.Commit(ctx)
	if err != nil {
		return nil, fmt.Errorf("Failed to commit transaction: %v", err)
	}
	return &models.CreateLocationResponse{
		LocationId: int64(locationID),
	}, nil
}

// CreateSolarSite implements proto.QuartzAPIServer.
func (q *QuartzAPIPostgresServer) CreateSolarSite(context.Context, *models.CreateSiteRequest) (*models.CreateLocationResponse, error) {
	panic("unimplemented")
}

// CreateWindGsp implements proto.QuartzAPIServer.
func (q *QuartzAPIPostgresServer) CreateWindGsp(context.Context, *models.CreateGspRequest) (*models.CreateLocationResponse, error) {
	panic("unimplemented")
}

// CreateWindSite implements proto.QuartzAPIServer.
func (q *QuartzAPIPostgresServer) CreateWindSite(context.Context, *models.CreateSiteRequest) (*models.CreateLocationResponse, error) {
	panic("unimplemented")
}

// GetActualCrossSection implements proto.QuartzAPIServer.
func (q *QuartzAPIPostgresServer) GetActualCrossSection(context.Context, *models.GetActualCrossSectionRequest) (*models.GetActualCrossSectionResponse, error) {
	panic("unimplemented")
}

// GetActualTimeseries implements proto.QuartzAPIServer.
func (q *QuartzAPIPostgresServer) GetActualTimeseries(*models.GetActualTimeseriesRequest, grpc.ServerStreamingServer[models.GetActualTimeseriesResponse]) error {
	panic("unimplemented")
}

// GetPredictedCrossSection implements proto.QuartzAPIServer.
func (q *QuartzAPIPostgresServer) GetPredictedCrossSection(context.Context, *models.GetPredictedCrossSectionRequest) (*models.GetPredictedCrossSectionResponse, error) {
	panic("unimplemented")
}

// GetPredictedTimeseries implements proto.QuartzAPIServer.
func (q *QuartzAPIPostgresServer) GetPredictedTimeseries(*models.GetPredictedTimeseriesRequest, grpc.ServerStreamingServer[models.GetPredictedTimeseriesResponse]) error {
	panic("unimplemented")
}

// NewPostgresClient creates a new PostgresClient instance and connects to the database
func NewQuartzAPIPostgresServer() *QuartzAPIPostgresServer {
	pool, err := pgxpool.New(
		context.Background(), os.Getenv("DATABASE_URL"),
	)
	if err != nil {
		log.Fatal().Msg("Unable to connect to database. Ensure DATABASE_URL is set correctly")
	}

	log.Debug().Msg("Running migrations")
	goose.SetBaseFS(embedMigrations)
	_ = goose.SetDialect("postgres")
	db := stdlib.OpenDBFromPool(pool)
	err = goose.Up(db, migrationsDir)
	if err != nil {
		log.Fatal().Msgf("Unable to apply migrations: %v", err)
	}
	err = db.Close()
	if err != nil {
		log.Fatal().Msgf("Unable to close database connection: %v", err)
	}

	return &QuartzAPIPostgresServer{pool: pool}
}


var _ models.QuartzAPIServer = (*QuartzAPIPostgresServer)(nil)
