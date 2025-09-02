/* --- Queries for the IAM table --- */

-- name: SetServiceAccountForTransaction :exec
SET LOCAL app.current_service_account = $1;

-- name: GetLocationPolicy :one
SELECT (
    role_name,
    location_uuid,
    service_account
) FROM iam.location_policies
INNER JOIN iam.roles USING (role_id)
WHERE service_account = $1
    AND role_name = ANY(sqlc.arg(role_names)::text [])
    AND location_uuid = $2;

-- name: CreateLocationPolies :exec
INSERT INTO iam.location_policies (
    role_id,
    service_account,
    location_uuid
) SELECT
    $1,
    $2,
    loc_uuid
FROM UNNEST(ARRAY[sqlc.arg(location_uuids)::uuid []]) AS t (loc_uuid);

-- name: DeleteLocationPolicies :exec
DELETE FROM iam.location_policies
WHERE service_account = $1
    AND location_uuid = ANY(sqlc.arg(location_uuids)::uuid []);

-- name: ListLocationPolicies :many
SELECT (
    role_name,
    location_uuid,
    service_account
) FROM iam.location_policies
INNER JOIN iam.roles USING (role_id)
WHERE service_account = $1
    AND role_name = ANY(sqlc.arg(role_names)::text []);
