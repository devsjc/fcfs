-- +goose Up

/*
 * Schema and tables to handle access management data.
 *
 * This schema isn't for storing any personally identifiable information; rather for detailing
 * roles and policies for user tokens and resources in the database.
 *
 * Roles are stored in a lookup table, and are used to determine the allowable
 * actions a user can take on a resource. These roles are then applied to users and
 * resources via policies. These policies are simply matchings between service accounts,
 * resource ids, and roles.
 */

CREATE SCHEMA iam;

/*- Lookups -----------------------------------------------------------------------------------*/

-- Lookup table to store the possible roles
CREATE TABLE iam.roles (
    role_id SMALLINT GENERATED ALWAYS AS IDENTITY NOT NULL,
    role_name TEXT NOT NULL,
    CONSTRAINT role_name_format_check CHECK (
            LENGTH(role_name) > 0
            AND LENGTH(role_name) <= 64
            AND role_name = UPPER(role_name)
        ),
    PRIMARY KEY (role_id),
    UNIQUE (role_name)
);
INSERT INTO iam.roles (role_name) VALUES ('OWNER'), ('VIEWER');


/*- Tables ----------------------------------------------------------------------------------*/

/* 
 * Pivot table to define location policies.
 * These policies match service accounts to roles for specific locations. A service account is a
 * representation of the user or organisation that is accessing the resource.
 * A service account can only have one role for per location (can't be an OWNER *and* a VIEWER).
 */
CREATE TABLE iam.location_policies (
    role_id SMALLINT NOT NULL
        REFERENCES iam.roles(role_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    location_uuid UUID NOT NULL
        REFERENCES loc.locations(location_uuid)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    service_account TEXT NOT NULL,
    CONSTRAINT service_account_format_check CHECK ( LENGTH(service_account) > 0 ),
    PRIMARY KEY (service_account, role_id, location_uuid),
    UNIQUE (service_account, location_uuid)
);

/*- Functions -------------------------------------------------------------------------------*/

-- +goose StatementBegin
-- Trigger to ensure new locations are owned by the writing service account
CREATE OR REPLACE FUNCTION loc.set_location_owner()
RETURNS TRIGGER AS $$
DECLARE
    current_sa UUID;
BEGIN
    BEGIN
        current_sa := current_setting('app.current_service_account')::UUID;
    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'app.current_service_account must be set to create a location';
    END;
    INSERT INTO iam.location_policies (location_uuid, role_id, service_account)
    VALUES (
        NEW.location_uuid,
        (SELECT role_id FROM iam.roles WHERE role_name = 'OWNER'), 
        current_sa
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- +goose StatementEnd

CREATE OR REPLACE TRIGGER set_location_owner
AFTER INSERT ON loc.locations
FOR EACH ROW EXECUTE FUNCTION loc.set_location_owner();

-- +goose Down
DROP TRIGGER IF EXISTS set_location_owner ON loc.locations;
DROP SCHEMA iam CASCADE;
