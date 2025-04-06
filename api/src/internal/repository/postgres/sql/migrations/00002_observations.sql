/*
Schema and tables to handle observed generation data.

Observations of generation data is usually measured by providers of inverters,
which are required in many sources of renewable energy to convert power from DC to AC.
Partnerships with these providers provide access to the data in order to
test the accuracy of predictions.
*/

-- +goose Up
-- +goose StatementBegin

CREATE SCHEMA obs;

/*- Tables ----------------------------------------------------------------------------------*/

-- Table to store observed generation values
CREATE TABLE obs.observations (
    observation_id INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    location_id INT NOT NULL
        REFERENCES loc.locations(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    source_type_id SMALLINT NOT NULL
        REFERENCES loc.source_types(source_type_id)
        ON DELETE RESTRICT,
    time_utc TIMESTAMP NOT NULL
        CHECK ( time_utc <= CURRENT_TIMESTAMP ),
    -- Observed generation in factors of Watts
    generation SMALLINT NOT NULL
        CHECK ( generation >= 0 ),
    -- Factor definiing power of 10 to multiply the generation by
    generation_unit_prefix_factor SMALLINT DEFAULT (0) NOT NULL
        CHECK ( unit_prefix_factor IN (0, 3, 6, 9, 12) ),
    PRIMARY KEY (id),
    UNIQUE (location_id, time_utc)
);

-- +goose StatementEnd

-- +goose Down
DROP SCHEMA obs CASCADE;
