/*
Schema and tables to handle location-based data.

The generation data we store, be it predicted or otherwise, is always tied to a certain 
location. These locations vary in size and scope, from a single site to an entire country,
and the metadata we may want to store about them will also vary accordingly.

From an application standpoint, the location is pertinent in the case where we care about
the generated power as a fraction of the capacity of the location, as well as allowing us
to represent the data on a map.

In order to represent this supertype/subtype relationship, we will use a single table for the
supertype (location), plus a table for each subtype. This will allow us to more appropriately
represent the application.

https://stackoverflow.com/a/2672722
*/

CREATE SCHEMA loc;
COMMENT ON SCHEMA loc IS 'Locations schema';

/*- Tables ----------------------------------------------------------------------------------*/

CREATE TABLE loc.locations (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    latitude real NOT NULL,
    longitude real NOT NULL,
    capacity_kw integer NOT NULL,
    subtype varchar(10) NOT NULL,
    CHECK ( capacity_kw >= 0),
    CHECK ( subtype IN ('site', 'region')),
    UNIQUE (name, latitude, longitude, subtype),
);
COMMENT ON TABLE loc.locations IS 'Supertype table for locations.';
COMMENT ON COLUMN loc.locations.id IS 'Primary key for the location.';
COMMENT ON COLUMN loc.locations.name IS 'Name of the location.';
COMMENT ON COLUMN loc.locations.latitude IS 'Latitude assocciated with the location.';
COMMENT ON COLUMN loc.locations.longitude IS 'Longitude associated with the location.';
COMMENT ON COLUMN loc.locations.capacity_kw IS 'Capacity of the location in kilowatts.';
COMMENT ON COLUMN loc.locations.subtype IS 'Type of location (site, region).';


CREATE TABLE loc.site_metadata (
    id SERIAL PRIMARY KEY,
    location_id INTEGER NOT NULL,
    client_name varchar(255) NULLABLE,
    client_site_id varchar(255) NULLABLE,
    created_utc timestamp DEFAULT CURRENT_TIMESTAMP,
    orientation_deg smallint NULLABLE,
    pitch_deg smallint NULLABLE,
    CHECK ( (orientation_deg is NULL) or (orientation_deg >= 0 AND orientation_deg < 360)),
    CHECK ( (pitch_deg is NULL) or (pitch_deg >= 0 AND pitch_deg <= 180)),
    FOREIGN KEY (location_id) REFERENCES loc.location(id),
);
COMMENT ON TABLE loc.sites IS 'Subtype table for site-level locations.';
COMMENT ON COLUMN loc.sites.id IS 'Primary key for the site.';
COMMENT ON COLUMN loc.sites.location_id IS 'Foreign key to the location table.';
COMMENT ON COLUMN loc.sites.client_name IS 'Name of the client associated with the site.';
COMMENT ON COLUMN loc.sites.client_site_id IS 'ID of the site as given by the client.';
COMMENT ON COLUMN loc.sites.created_utc IS 'Timestamp of the creation of the site.';
COMMENT ON COLUMN loc.sites.orientation_deg IS 'Yaw of the site in degrees (0: N, 90: E, 180: S, 270: W)';
COMMENT ON COLUMN loc.sites.tilt_deg IS 'Pitch of the site in degrees (0: Points directly downwards, 180: Points directly upwards)';

CREATE TABLE loc.region_metadata (
    id SERIAL PRIMARY KEY,
    location_id INTEGER NOT NULL,
    region_name varchar(255) NOT NULL,
    boundary_geojson jsonb NOT NULL,
    FOREIGN KEY (location_id) REFERENCES loc.location(id),
);
COMMENT ON TABLE loc.regions IS 'Subtype table for region-level locations.';
COMMENT ON COLUMN loc.regions.id IS 'Primary key for the region.';
COMMENT ON COLUMN loc.regions.location_id IS 'Foreign key to the location table.';
COMMENT ON COLUMN loc.regions.region_name IS 'Name of the region.';
COMMENT ON COLUMN loc.regions.boundary_geojson IS 'GeoJSON representation of the region boundary.';


/*- Materialized Views ----------------------------------------------------------------------*/

CREATE MATERIALIZED VIEW loc.sites AS (
    SELECT 
        l.id AS location_id,
        l.name AS name,
        l.latitude AS latitude,
        l.longitude AS longitude,
        l.capacity_kw AS capacity_kw,
        l.created_utc AS created_utc,
        s.id AS site_id,
        s.client_name AS client_name,
        s.client_site_id AS client_site_id,
        s.created_utc AS created_utc
    FROM loc.locations l
    INNER JOIN loc.site_metadata s ON l.id = s.location_id
);
COMMENT ON MATERIALIZED VIEW loc.sites IS 'Materialized view of the site locations and metadata.';

CREATE MATERIALIZED VIEW loc.regions AS (
    SELECT 
        l.id AS location_id,
        l.name AS name,
        l.latitude AS latitude,
        l.longitude AS longitude,
        l.capacity_kw AS capacity_kw,
        l.created_utc AS created_utc,
        r.id AS region_id
    FROM loc.locations l
    INNER JOIN loc.region_metadata r ON l.id = r.location_id
);
COMMENT ON MATERIALIZED VIEW loc.regions IS 'Materialized view of the region locations and metadata.';

