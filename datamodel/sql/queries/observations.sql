-- name: CreateObservation :one
INSERT INTO obs.observations (
    location_id, time_utc, generation, metric_prefix
) VALUES (
    $1, $2, $3, $4
) RETURNING id;

-- name: ListObservations :many
SELECT
    obs.observations.id,
    obs.observations.location_id,
    obs.observations.time_utc,
    obs.observations.generation,
    obs.observations.metric_prefix
FROM obs.observations;
