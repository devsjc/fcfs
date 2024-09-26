--name: GetObservations :one
SELECT * FROM observations WHERE id = $1 LIMIT 1;
