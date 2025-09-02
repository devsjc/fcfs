-- +goose Up

/*
 * Schema and tables to handle access management data.
 *
 * This schema isn't for storing any personally identifiable information; rather for detailing
 * roles and policies for user tokens and resources in the database.
 *
 * Roles are stored in a lookup table, and are used to determine the allowable
 * actions a user can take on a resource. These roles are then applied to users and 
 * resources via policies. These policies are simply matchings between user tokens,
 * resource ids, and roles.
 */

CREATE SCHEMA iam;

/*- Lookups -----------------------------------------------------------------------------------*/

-- Lookup table to store the user roles
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

-- Pivot table to define location policies (match user tokens with locations and roles)
CREATE TABLE iam.location_policies (
    role_id SMALLINT NOT NULL
        REFERENCES iam.roles(role_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    location_uuid UUID NOT NULL
        REFERENCES loc.locations(location_uuid)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    -- A token representing a service account (user/organization)
    service_account TEXT NOT NULL,
    CONSTRAINT service_account_format_check CHECK ( LENGTH(service_account) > 0 ),
    PRIMARY KEY (service_account, role_id, location_uuid),
    -- Can't have more than one role for a given service account and location
    UNIQUE (service_account, location_uuid)
);

/*- Functions -------------------------------------------------------------------------------*/

-- Function to check if a location policy exists for the current service account
CREATE OR REPLACE FUNCTION iam.location_policy_exists(
    policy_location_uuid UUID,
    policy_role_name TEXT
) RETURNS BOOLEAN AS $$
DECLARE
    current_service_account TEXT;
BEGIN
    current_service_account := current_setting('app.current_service_account')::TEXT;
    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'app.current_service_account is not set';
    END;
RETURN EXISTS (
        SELECT 1 FROM iam.location_policies AS lp
        WHERE
            lp.location_uuid = policy_location_uuid
            AND lp.service_account = current_service_account
            AND lp.role_id = (
                SELECT role_id FROM iam.roles WHERE role_name = UPPER(policy_role_name)
            )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


/*- Policies --------------------------------------------------------------------------------*/

CREATE POLICY view_location ON loc.locations
FOR SELECT TO PUBLIC
    USING (iam.location_policy_exists(location_uuid, 'VIEWER'));

CREATE POLICY own_location ON loc.locations
FOR ALL TO PUBLIC
    USING (iam.location_policy_exists(location_uuid, 'OWNER'))
    WITH CHECK (iam.location_policy_exists(location_uuid, 'OWNER'));

ALTER TABLE loc.locations ENABLE ROW LEVEL SECURITY;

CREATE POLICY view_source_history ON loc.sources_history
FOR SELECT TO authenticated
    USING (iam.location_policy_exists(location_uuid, 'VIEWER'));

CREATE POLICY own_source_history ON loc.sources_history
FOR ALL TO authenticated
    USING (iam.location_policy_exists(location_uuid, 'OWNER'))
    WITH CHECK (iam.location_policy_exists(location_uuid, 'OWNER'));

ALTER TABLE loc.sources_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY view_mv_source ON loc.sources_mv
FOR SELECT TO authenticated
    USING (iam.location_policy_exists(location_uuid, 'VIEWER'));

CREATE POLICY own_mv_source ON loc.sources_mv
FOR ALL TO authenticated
    USING (iam.location_policy_exists(location_uuid, 'OWNER'))
    WITH CHECK (iam.location_policy_exists(location_uuid, 'OWNER'));

ALTER TABLE loc.sources_mv ENABLE ROW LEVEL SECURITY;

/*- Triggers -------------------------------------------------------------------------------*/

CREATE OR REPLACE FUNCTION iam.create_owner_policy_on_location_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO iam.location_policies (role_id, service_account, location_uuid)
    VALUES (
        (SELECT role_id FROM iam.roles WHERE role_name = 'OWNER'),
        current_setting('app.current_service_account')::TEXT,
        NEW.location_uuid
    );
    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'app.current_service_account is not set';
    END;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER create_owner_policy_on_location_insert
AFTER INSERT ON loc.locations
FOR EACH ROW EXECUTE FUNCTION iam.create_owner_policy_on_location_insert();


-- +goose Down
DROP POLICY IF EXISTS view_location ON loc.locations;
DROP POLICY IF EXISTS own_location ON loc.locations;
ALTER TABLE loc.locations DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS view_source_history ON loc.sources_history;
DROP POLICY IF EXISTS own_source_history ON loc.sources_history;
ALTER TABLE loc.sources_history DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS view_mv_source ON loc.sources_mv;
DROP POLICY IF EXISTS own_mv_source ON loc.sources_mv;
ALTER TABLE loc.sources_mv DISABLE ROW LEVEL SECURITY;
DROP SCHEMA iam CASCADE;
