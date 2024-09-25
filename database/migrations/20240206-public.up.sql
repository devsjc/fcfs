CREATE TYPE public.power_unit as ENUM ('W', 'kW', 'MW', 'GW', 'TW');
COMMENT ON TYPE public.power_unit IS 'Unit of power, in Watts of varying orders of magnitude';
