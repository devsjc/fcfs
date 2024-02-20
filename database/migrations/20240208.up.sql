CREATE SCHEMA predicted_data;
COMMENT ON SCHEMA predicted_data IS 'Data for predicted generation';

CREATE TABLE predicted_data.forecast_metadata (
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    location_uuid UUID NOT NULL,
    created_utc TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    init_time_utc TIMESTAMP NOT NULL,
    forecast_model_id INT NOT NULL,
    PRIMARY KEY (uuid),
    FOREIGN KEY (location_uuid) REFERENCES public.locations(uuid),
    FOREIGN KEY (forecast_model_id) REFERENCES predicted_data.forecast_model(id)
);
COMMENT ON TABLE predicted_data.forecast_metadata IS 'Metadata for a forecast';
COMMENT ON ROW predicted_data.forecast_metadata.uuid IS 'Unique identifier for a forecast';
COMMENT ON ROW predicted_data.forecast_metadata.location_uuid IS 'Location the forecast is for';
COMMENT ON ROW predicted_data.forecast_metadata.created_utc IS 'Time the forecast was created';
COMMENT ON ROW predicted_data.forecast_metadata.init_time_utc IS 'Initialization time of the forecast';
COMMENT ON ROW predicted_data.forecast_metadata.forecast_model_id IS 'Model used to generate the forecast';

CREATE TABLE predicted_data.forecast_model (
    name VARCHAR(255) NOT NULL,
    version VARCHAR(255) NOT NULL,
    id SERIAL NOT NULL,
    PRIMARY KEY (model, version)
);
COMMENT ON TABLE predicted_data.forecast_model IS 'Model used to generate a forecast';
COMMENT ON ROW predicted_data.forecast_model.name IS 'Name of the model';
COMMENT ON ROW predicted_data.forecast_model.version IS 'Version of the model';

CREATE TABLE predicted_data.predicted_generation (
    forecast_uuid UUID NOT NULL,
    horizon_mins smallint NOT NULL,
    generation smallint NOT NULL,
    unit public.power_unit NOT NULL,
    PRIMARY KEY (forecast_uuid, location_uuid, horizon),
    FOREIGN KEY (forecast_uuid) REFERENCES predicted_data.forecast_metadata(uuid),
);
COMMENT ON TABLE predicted_data.predicted_generation IS 'Predicted generation values';
COMMENT ON ROW predicted_data.predicted_generation.forecast_uuid IS 'Unique identifier for a forecast';
COMMENT ON ROW predicted_data.predicted_generation.horizon IS 'Time horizon for the forecast';

CREATE SCHEMA locations;

CREATE SCHEMA actual_data;


