package postgres

import (
	"context"
	"fmt"
	"net"
	"path/filepath"
	"testing"

	"github.com/devsjc/fcfs/api/src/internal/models"
	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/wait"

	"github.com/stretchr/testify/require"
)

func TestCapacityKWToMultiplier(t *testing.T) {
	// Test cases
	type TestCase struct{
		capacityKw int64
		expectedValue int16
		expectedMultiplier int16
		shouldError bool
	}
	tests := []TestCase{
		{-1, 0, 0, true},
		{0, 0, 0, false},
		{500, 500, 3, false},
		{32767, 32767, 3, false},
		{32768, 33, 6, false}, // Needs rounding, should go to 33 MW
		{33000, 33, 6, false},
		{1000000000, 1000, 9, false}, // 1TW
		{12345678, 12346, 6, false}, // 12 GW
	}

	for _, test := range tests {
		t.Run(fmt.Sprintf("capacityKw=%d", test.capacityKw), func(t *testing.T) {
			capacity, prefix, err := capacityKwToValueMultiplier(test.capacityKw)
			if test.shouldError {
				require.Error(t, err)
			} else {
				require.NoError(t, err)
				require.Equal(t, test.expectedValue, capacity)
				require.Equal(t, test.expectedMultiplier, prefix)
			}
		})
	}
}

// Build a Postgres container with the relevant extensions and some test data
func setupSuite(t *testing.T, ctx context.Context) (models.QuartzAPIServer, func(*testing.T)) {
	req := testcontainers.ContainerRequest{
		FromDockerfile: testcontainers.FromDockerfile{
			Context:    filepath.Join(".", "infra"),
			Dockerfile: "Containerfile",
			KeepImage: true,
		},
		Env: map[string]string{
			"POSTGRES_USER":     "postgres",
			"POSTGRES_PASSWORD": "postgres",
			"POSTGRES_DB":       "postgres",
		},
		Cmd:          []string{"postgres", "-c", "fsync=off"},
		ExposedPorts: []string{"5432/tcp"},
		WaitingFor:   wait.ForAll(
			wait.ForLog(
				"database system is ready to accept connections",
			).WithOccurrence(2),
			wait.ForListeningPort("5432/tcp"),
		),
	}
	pgC, err := testcontainers.GenericContainer(ctx, testcontainers.GenericContainerRequest{
        ContainerRequest: req,
        Started:          true,
    })
	require.NoError(t, err)
	containerPort, err := pgC.MappedPort(ctx, "5432/tcp")
	require.NoError(t, err)
	host, err := pgC.Host(ctx)
	require.NoError(t, err)

	connString := fmt.Sprintf(
		"postgres://postgres:postgres@%s/postgres",
		net.JoinHostPort(host, containerPort.Port()),
	)

	s := NewQuartzAPIPostgresServer(connString)
	t.Logf("Connected to fully migrated postgres container at %s", connString)

	return s, func(t *testing.T) {
		t.Logf("Cleaning up postgres container")
		testcontainers.CleanupContainer(t, pgC)
	}
}

func TestMigrate(t *testing.T) {
	ctx := context.Background()
	_, cleanup := setupSuite(t, ctx)
	defer cleanup(t)
}

func TestInsertGsp(t *testing.T) {
	ctx := context.Background()
	s, cleanup := setupSuite(t, ctx)
	defer cleanup(t)

	resp, err := s.CreateSolarGsp(ctx, &models.CreateGspRequest{
		Name: "Test GSP",
		Geometry: "POLYGON((0 0, 0 1, 1 1, 1 0, 0 0))",
		CapacityMw: 500,
		Metadata: "{}",
	})

	require.NoError(t, err, )
	require.Equal(t, resp.LocationId, "Test GSP")
	
}
