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
COMMENT ON SCHEMA pred IS 'Data for predicted generation';

/*- Tables ----------------------------------------------------------------------------------*/

/*
Forecasts refer to the generation predictions created by a specific version
of a forecast model for a specific location with a specific initialization time.
There can only be one forecast per location per initialization time per model,
reruns should replace old values.
*/
CREATE TABLE pred.forecasts (
    id SERIAL NOT NULL,
    location_id INT NOT NULL,
    created_utc TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    init_time_utc TIMESTAMP NOT NULL,
    forecast_model_id INT NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (location_id) REFERENCES loc.locations(id),
    FOREIGN KEY (forecast_model_id) REFERENCES pred.forecast_models(id),
    CREATE UNIQUE INDEX ON (location_id, init_time_utc, forecast_model_id)
);
COMMENT ON TABLE pred.forecasts IS 'Metadata for a forecast';
COMMENT ON ROW pred.forecasts.id IS 'Unique identifier for a forecast';
COMMENT ON ROW pred.forecasts.location_id IS 'Location the forecast is for';
COMMENT ON ROW pred.forecasts.created_utc IS 'Time the forecast was created';
COMMENT ON ROW pred.forecasts.init_time_utc IS 'Initialization time of the forecast';
COMMENT ON ROW pred.forecasts.forecast_model_id IS 'Model used to generate the forecast';

/*
A forecast model is an ML model that generated predicted generation values.
Each forecast model's name and version number uniquely identifies it.
*/
CREATE TABLE pred.forecast_models (
    id SERIAL NOT NULL,
    name VARCHAR(255) NOT NULL,
    version VARCHAR(255) NOT NULL,
    PRIMARY KEY (id),
    CREATE UNIQUE INDEX ON (name, version)
);
COMMENT ON TABLE pred.forecast_models IS 'Model used to generate a forecast';
COMMENT ON ROW pred.forecast_models.id IS 'Unique identifier for a forecast model';
COMMENT ON ROW pred.forecast_models.name IS 'Name of the forecast model';
COMMENT ON ROW pred.forecast_models.version IS 'Version of the forecast model';

/*
Predicted generation values are the output of a forecast model.
There can only be one predeicted generation value per forecast per location per horizon.
This table gets very large very quickly, so to save space, data is stored as smallints
where possible. However, because generation can be for locations that vary greatly in
size, we also store the unit of the generation.

- BIGINT: 8 bytes for 0W-2.14MW
- SMALLINT + ENUM: 2+4 = 6 bytes for 0W-32000TW 
*/
CREATE TABLE pred.predicted_generation (
    forecast_id INT NOT NULL,
    horizon_mins smallint NOT NULL,
    generation smallint NOT NULL,
    unit public.power_unit NOT NULL,
    CHECK (generation >= 0),
    CHECK (horizon_mins >= 0),
    PRIMARY KEY (forecast_id, location_id, horizon),
    FOREIGN KEY (forecast_id) REFERENCES pred.forecast(id),
);
COMMENT ON TABLE pred.predicted_generation IS 'Predicted generation values';
COMMENT ON ROW pred.predicted_generation.forecast_uuid IS 'Unique identifier for a forecast';
COMMENT ON ROW pred.predicted_generation.horizon IS 'Time horizon for the forecast';



