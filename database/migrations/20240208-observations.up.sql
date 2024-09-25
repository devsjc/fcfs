/*
Schema and tables to handle observed generation data.

Generation data is usually observed by providers of inverters, which are
required in many sources of renewable energy to convert power from DC to AC.
Partnerships with these providers provide access to the data in order to
test the accuracy of predictions. 

*/

CREATE SCHEMA obs;
COMMENT ON SCHEMA obs IS 'Data for observed generation';

/*- Lookups -----------------------------------------------------------------------------------*/

CREATE TABLE obs.lu_power_units (
    seq TINYINT AUTOINCREMENT NOT NULL,
    name TEXT NOT NULL,
    CHECK ( name IN ('W', 'kW', 'MW', 'GW', 'TW') and LEN(name) <= 2),
    PRIMARY KEY (seq),
);
INSERT INTO obs.lu_power_units (name) VALUES ('W'), ('kW'), ('MW'), ('GW'), ('TW');
COMMENT ON TABLE obs.lu_power_units IS 'Lookup table for power units.';


/*- Tables ----------------------------------------------------------------------------------*/

CREATE TABLE obs.observations (
    id INT AUTOINCREMENT NOT NULL,
    location_id INT NOT NULL,
    time_utc TIMESTAMP NOT NULL,
    CHECK ( time_utc <= CURRENT_TIMESTAMP ),
    generation SMALLINT NOT NULL,
    CHECK ( generation >= 0 ),
    generation_units TINYINT NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (location_id) REFERENCES loc.locations(id),
    FOREIGN KEY (generation_units) REFERENCES obs.lu_power_units(seq),
    CREATE UNIQUE INDEX ON (location_id, time_utc),
);
COMMENT ON TABLE obs.observations IS 'Observed generation data.';
COMMENT ON COLUMN obs.observations.id IS 'Unique identifier for the observation.';
COMMENT ON COLUMN obs.observations.location_id IS 'Location of the observed generation.';
COMMENT ON COLUMN obs.observations.time_utc IS 'Time of the observation in UTC.';
COMMENT ON COLUMN obs.observations.generation IS 'Observed generation value.';
COMMENT ON COLUMN obs.observations.generation_units IS 'Units of the observed generation.';

