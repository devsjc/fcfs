package main

import (
	"net"
	"os"
	"strings"

	"github.com/rs/zerolog/log"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"

	pb "github.com/devsjc/fcfs/api/src/gen"
	rdiy "github.com/devsjc/fcfs/api/src/internal/repository/dummy"
	rpgx "github.com/devsjc/fcfs/api/src/internal/repository/postgres"
	service "github.com/devsjc/fcfs/api/src/internal/service"
)

func main() {
	log.Debug().Str("type", os.Getenv("DATABASE_TYPE")).Msg("Connecting to backend")
	switch strings.ToLower(os.Getenv("DATABASE_TYPE")) {
		case "postgres":
			apiServer := service.NewQuartzAPIServer(rpgx.NewPostgresClient())
		default:
			apiServer := service.NewQuartzAPIServer(rdiy.NewDummyClient())
	}


	log.Info().Int("port", 50051).Msg("Starting GRPC server")
	lis, err := net.Listen("tcp", ":50051")
	if err != nil {
		log.Fatal().Err(err).Msg("Failed to listen")
	}
	s := grpc.NewServer()
	pb.RegisterQuartzAPIServer(s, apiServer)
	reflection.Register(s)
	log.Info().Msg("Listening on :50051")
	s.Serve(lis)
};
