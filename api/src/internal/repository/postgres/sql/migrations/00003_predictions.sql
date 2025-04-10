-- +goose Up

/*
Schema and tables to handle predicted generation data.

Predicted generation data is produced by various forecast models specific to a location.
A forecast is a set of predicted generations, beginning at the
*initialisation time*. Each subsequent generation's *target time* is equivalent to the
initialisation time plus the *horizon*.

From a frontend standpoint, the latest produced forecast is the most accurate
for a given location.
*/

CREATE SCHEMA pred;
CREATE EXTENSION IF NOT EXISTS pg_partman WITH SCHEMA partman;

/*- Tables ----------------------------------------------------------------------------------*/

/*
A forecast model is an ML model that generated predicted generation values.
Each model's name and version number uniquely identifies it.
*/
CREATE TABLE pred.models (
    model_id INTEGER GENERATED ALWAYS AS IDENTITY NOT NULL,
    name TEXT NOT NULL
        CHECK ( LENGTH(name) > 0 and LENGTH(name) < 64 ),
    version TEXT NOT NULL
        CHECK ( LENGTH(version) > 0 and LENGTH(version) < 64 ),
    created_at_utc TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (model_id),
    UNIQUE (name, version)
);

/*
Forecasts refer to the generation predictions created by a specific version
of a forecast model for a specific location with a specific initialization time.
There can only be one forecast per location per initialization time per model,
reruns should replace old values.
*/
CREATE TABLE pred.forecasts (
    -- Type of energy source
    source_type_id SMALLINT NOT NULL
        REFERENCES loc.source_types(source_type_id)
        ON DELETE RESTRICT,
    forecast_id INTEGER GENERATED ALWAYS AS IDENTITY NOT NULL,
    location_id INTEGER NOT NULL
        REFERENCES loc.locations(location_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    model_id INTEGER NOT NULL
        REFERENCES pred.models(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    init_time_utc TIMESTAMP NOT NULL,
    PRIMARY KEY (forecast_id),
    UNIQUE (location_id, init_time_utc, source_type_id, model_id)
);

-- Index for efficiently finding a location's forecasts
CREATE INDEX ON pred.forecasts (location_id, init_time_utc);

/*
Table to store predicted generation values.
Predicted generation values are the output of a forecast model.
There can only be one predicted generation per forecast per horizon.
This table gets very large very quickly, so to save space,
data is stored as smallints where possible, and the columns are
ordered to allow for efficient bit-packing.
*/
CREATE TABLE pred.predicted_generation_values (
    -- Could have the init_time_utc here to denormalise, but it is encoded in
    -- the horizon value anyway, which is itself a more useful index 
    horizon_mins SMALLINT NOT NULL
        CHECK (horizon_mins >= 0),
    -- Predicted generation confidence level values, as a percentage of capacity
    p10 SMALLINT
        CHECK (p10 IS NULL or p10 >= 0 and p10 <= 110),
    p50 SMALLINT NOT NULL
        CHECK (p50 >= 0 and p50 <= 110),
    p90 SMALLINT
        CHECK (p90 IS NULL or p90 >= 0 and p90 <= 110),
    forecast_id INTEGER NOT NULL
        REFERENCES pred.forecasts(forecast_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    -- Denormalisation from the location table to avoid joins
    location_id INTEGER NOT NULL
        REFERENCES loc.locations(location_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    -- Time that the predicted generation value corresponds to
    target_time_utc TIMESTAMP NOT NULL,
    metadata JSONB
        CHECK (metadata IS NULL or metadata != '{}'),
    PRIMARY KEY (horizon_mins, forecast_id)
)
-- Native partitioning. Note that unique indexes will only work if they include
-- the partition key.
PARTITION BY RANGE (target_time_utc);

-- Index for cross section queries (one target time, many locations)
CREATE INDEX ON pred.predicted_generation_values (target_time_utc, horizon_mins);
-- Index for timeseries queries (one location, many target times)
CREATE INDEX ON pred.predicted_generation_values (location_id, target_time_utc, horizon_mins);
-- Index for getting specific forecast values
CREATE INDEX ON pred.predicted_generation_values (forecast_id, target_time_utc, horizon_mins);

-- Manage partitions with pg_partman
SELECT partman.create_parent(
    p_parent_table => 'pred.predicted_generation_values',
    p_control => 'target_time_utc',
    p_type => 'range',
    p_interval => 'daily',
    p_automatic_maintenance => 'on',
    p_jobmon => false,
    p_premake => 7
);
UPDATE partman.part_config
SET retention = '1 month',
    -- Detacth as opposed to dropping partitions
    retention_keep_table = true,
    retention_keep_index = false,
    -- Retain the detatched partitions so they can be processed
    infinite_time_partitions = true
WHERE parent_table = 'public.predicted_generation_values';

/*- Materialized views ------------------------------------------------------------------*/

CREATE MATERIALIZED VIEW pred.predicted_generation_timeseries AS
WITH 
    vars AS (
        SELECT
            -- The desired horizon in minutes
            60 AS desired_horizon_mins,
            -- The window to look back for past values, in hours
            52 AS window_hours_backwards,
            -- The window to look forward for future values, in hours
            36 AS window_hours_forwards
    ),
    -- Get the forecast for each location with init_time corresponding to
    -- desired_horizon_mins prior to the current time
    desired_future_forecasts AS (
        SELECT DISTINCT ON (location_id)
            location_id, forecast_id
        FROM pred.forecasts
        JOIN vars ON true
        WHERE init_time_utc <= NOW() - MAKE_INTERVAL(mins => desired_horizon_mins)
        ORDER BY init_time_utc DESC
        LIMIT 1
    ),
    -- Get the forecast values corresponding to the above forecasts
    future_predicted_generation_values AS (
        SELECT
            p.location_id, p.target_time_utc, p.horizon_mins,
            p.p10, p.p50, p.p90, p.metadata
        FROM pred.predicted_generation_values AS p
        JOIN desired_future_forecasts AS f
            USING (forecast_id)
        JOIN vars ON true
        WHERE target_time_utc <= NOW() + MAKE_INTERVAL(hours => window_hours_forwards)
    ),
    -- Get the forecast values for each location and each target time that
    -- has a horizon equal to desired_horizon_mins, back to the current time
    -- minus window_hours_backwards
    past_predicted_generation_values AS (
        SELECT DISTINCT ON (location_id)
            p.location_id, p.target_time_utc, p.horizon_mins,
            p.p10, p.p50, p.p90, p.metadata
        FROM pred.predicted_generation_values AS p
        JOIN vars ON true
        WHERE target_time_utc >= NOW() - MAKE_INTERVAL(hours => window_hours_backwards)
            AND target_time_utc <= NOW() - MAKE_INTERVAL(mins => desired_horizon_mins)
            AND horizon_mins = desired_horizon_mins
    )
-- Union the above past and future predicted generation values into a timeseries per location
SELECT
    location_id, target_time_utc, horizon_mins,
    p10, p50, p90, metadata
FROM future_predicted_generation_values
UNION ALL
SELECT
    location_id, target_time_utc, horizon_mins,
    p10, p50, p90, metadata
FROM past_predicted_generation_values
ORDER BY location_id, target_time_utc, horizon_mins;
    
-- +goose Down
DROP SCHEMA pred CASCADE;

