CREATE SCHEMA IF NOT EXISTS silver;

DROP TABLE IF EXISTS silver.silver_airline_on_time;

CREATE TABLE silver.silver_airline_on_time (
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    carrier CHAR(2) NOT NULL,
    carrier_name VARCHAR(255),
    airport CHAR(3) NOT NULL,
    airport_name VARCHAR(255),
    arr_flights INTEGER NOT NULL,
    arr_del15 INTEGER NOT NULL,
    carrier_ct INTEGER,
    weather_ct INTEGER,
    nas_ct INTEGER,
    security_ct INTEGER,
    late_aircraft_ct INTEGER,
    arr_cancelled INTEGER,
    arr_diverted INTEGER,
    arr_delay NUMERIC(10,2) NOT NULL,
    carrier_delay NUMERIC(10,2),
    weather_delay NUMERIC(10,2),
    nas_delay NUMERIC(10,2),
    security_delay NUMERIC(10,2),
    late_aircraft_delay NUMERIC(10,2),
    is_outlier_arr_delay INTEGER NOT NULL,
    flight_date DATE,
    CONSTRAINT pk_silver_airline_on_time PRIMARY KEY (year, month, carrier, airport)
);

COMMENT ON TABLE silver.silver_airline_on_time IS 'Camada SILVER: tabela única com dados de atrasos de voos limpos e enriquecidos.';

COMMENT ON COLUMN silver.silver_airline_on_time.year IS 'Ano do registro.';
COMMENT ON COLUMN silver.silver_airline_on_time.month IS 'Mês do registro (1-12).';
COMMENT ON COLUMN silver.silver_airline_on_time.carrier IS 'Código IATA da companhia aérea.';
COMMENT ON COLUMN silver.silver_airline_on_time.carrier_name IS 'Nome completo da companhia aérea.';
COMMENT ON COLUMN silver.silver_airline_on_time.airport IS 'Código IATA do aeroporto.';
COMMENT ON COLUMN silver.silver_airline_on_time.airport_name IS 'Nome completo do aeroporto.';
COMMENT ON COLUMN silver.silver_airline_on_time.arr_flights IS 'Número total de voos de chegada.';
COMMENT ON COLUMN silver.silver_airline_on_time.arr_del15 IS 'Número de voos com atraso >= 15 minutos.';
COMMENT ON COLUMN silver.silver_airline_on_time.carrier_ct IS 'Contagem de atrasos causados pela companhia aérea.';
COMMENT ON COLUMN silver.silver_airline_on_time.weather_ct IS 'Contagem de atrasos causados por condições climáticas.';
COMMENT ON COLUMN silver.silver_airline_on_time.nas_ct IS 'Contagem de atrasos causados pelo Sistema Nacional de Espaço Aéreo (NAS).';
COMMENT ON COLUMN silver.silver_airline_on_time.security_ct IS 'Contagem de atrasos causados por segurança.';
COMMENT ON COLUMN silver.silver_airline_on_time.late_aircraft_ct IS 'Contagem de atrasos causados por aeronave atrasada.';
COMMENT ON COLUMN silver.silver_airline_on_time.arr_cancelled IS 'Número de voos cancelados.';
COMMENT ON COLUMN silver.silver_airline_on_time.arr_diverted IS 'Número de voos desviados.';
COMMENT ON COLUMN silver.silver_airline_on_time.arr_delay IS 'Total de minutos de atraso na chegada.';
COMMENT ON COLUMN silver.silver_airline_on_time.carrier_delay IS 'Minutos de atraso causados pela companhia aérea.';
COMMENT ON COLUMN silver.silver_airline_on_time.weather_delay IS 'Minutos de atraso causados por condições climáticas.';
COMMENT ON COLUMN silver.silver_airline_on_time.nas_delay IS 'Minutos de atraso causados pelo Sistema Nacional de Espaço Aéreo (NAS).';
COMMENT ON COLUMN silver.silver_airline_on_time.security_delay IS 'Minutos de atraso causados por segurança.';
COMMENT ON COLUMN silver.silver_airline_on_time.late_aircraft_delay IS 'Minutos de atraso causados por aeronave atrasada.';
COMMENT ON COLUMN silver.silver_airline_on_time.is_outlier_arr_delay IS 'Flag indicando se arr_delay é outlier (1=sim, 0=não, calculado via IQR).';
COMMENT ON COLUMN silver.silver_airline_on_time.flight_date IS 'Data do voo (primeiro dia do mês, derivado de year e month).';