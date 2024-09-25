CREATE SCHEMA IF NOT EXISTS public;

/*- Lookups -----------------------------------------------------------------------------------*/

CREATE TABLE public.lu_power_units (
    seq TINYINT AUTO INCREMENT NOT NULL,
    name TEXT NOT NULL,
    CHECK ( name IN ('W', 'kW', 'MW', 'GW', 'TW') and LEN(name) <= 2),
    PRIMARY KEY (seq),
);
INSERT INTO public.lu_power_units (name) VALUES ('W'), ('kW'), ('MW'), ('GW'), ('TW');
COMMENT ON TABLE public.lu_power_units IS 'Lookup table for power units.';
