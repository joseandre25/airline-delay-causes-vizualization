-- GOLD ddl.sql (enxuto, mnemônicos 3 letras, coerente com ETL em gold.*)
-- Star Schema (1 FATO): dim_tmp, dim_cia, dim_apt, fat_atr

CREATE SCHEMA IF NOT EXISTS dw;

DROP TABLE IF EXISTS dw.fat_atr;
DROP TABLE IF EXISTS dw.dim_apt;
DROP TABLE IF EXISTS dw.dim_cia;
DROP TABLE IF EXISTS dw.dim_tmp;

-- =========================
-- DIM_TMP (tempo)
-- =========================
CREATE TABLE dw.dim_tmp (
    srk_tmp BIGSERIAL NOT NULL,
    num_ano INTEGER NOT NULL,
    num_mes INTEGER NOT NULL,
    dat_tmp DATE NOT NULL,
    num_tri INTEGER,
    nom_mes VARCHAR(20),

    CONSTRAINT pri_dim_tmp PRIMARY KEY (srk_tmp),
    CONSTRAINT uni_dim_tmp_ano_mes UNIQUE (num_ano, num_mes),
    CONSTRAINT chk_dim_tmp_mes_rng CHECK (num_mes BETWEEN 1 AND 12)
);

-- =========================
-- DIM_CIA (companhia)
-- =========================
CREATE TABLE dw.dim_cia (
    srk_cia BIGSERIAL NOT NULL,
    cod_cia CHAR(2) NOT NULL,
    nom_cia VARCHAR(255),

    CONSTRAINT pri_dim_cia PRIMARY KEY (srk_cia),
    CONSTRAINT uni_dim_cia_cod UNIQUE (cod_cia)
);

-- =========================
-- DIM_APT (aeroporto)
-- =========================
CREATE TABLE dw.dim_apt (
    srk_apt BIGSERIAL NOT NULL,
    cod_apt CHAR(3) NOT NULL,
    nom_apt VARCHAR(255),

    CONSTRAINT pri_dim_apt PRIMARY KEY (srk_apt),
    CONSTRAINT uni_dim_apt_cod UNIQUE (cod_apt)
);

-- =========================
-- FAT_ATR (fato única)
-- =========================
CREATE TABLE dw.fat_atr (
    srk_fat BIGSERIAL NOT NULL,

    srk_tmp BIGINT NOT NULL,
    srk_cia BIGINT NOT NULL,
    srk_apt BIGINT NOT NULL,

    -- gerais
    qtd_voo_arr INTEGER NOT NULL,
    qtd_atr_del INTEGER NOT NULL,              -- del = atraso >= 15 min
    qtd_voo_can INTEGER NOT NULL DEFAULT 0,
    qtd_voo_div INTEGER NOT NULL DEFAULT 0,
    val_atr_mnt NUMERIC(10,2) NOT NULL,        -- mnt = minutos

    -- contagens por causa
    qtd_atr_cia     INTEGER NOT NULL DEFAULT 0,
    qtd_atr_cli     INTEGER NOT NULL DEFAULT 0,
    qtd_atr_nas     INTEGER NOT NULL DEFAULT 0,
    qtd_atr_seg     INTEGER NOT NULL DEFAULT 0,
    qtd_atr_aer_tar INTEGER NOT NULL DEFAULT 0, -- tar = tardio (late)

    -- minutos por causa
    val_atr_cia_mnt     NUMERIC(10,2) NOT NULL DEFAULT 0,
    val_atr_cli_mnt     NUMERIC(10,2) NOT NULL DEFAULT 0,
    val_atr_nas_mnt     NUMERIC(10,2) NOT NULL DEFAULT 0,
    val_atr_seg_mnt     NUMERIC(10,2) NOT NULL DEFAULT 0,
    val_atr_aer_tar_mnt NUMERIC(10,2) NOT NULL DEFAULT 0,

    -- qualidade
    ind_out_atr BOOLEAN NOT NULL DEFAULT FALSE,

    -- KPIs (calculados no ETL)
    val_tax_atr NUMERIC(12,6),  -- tax = taxa
    val_atr_pvo NUMERIC(14,6),  -- pvo = por voo

    CONSTRAINT pri_fat_atr PRIMARY KEY (srk_fat),
    CONSTRAINT uni_fat_atr_gra UNIQUE (srk_tmp, srk_cia, srk_apt)
);

-- FKs via ALTER TABLE (estilo do exemplo)
ALTER TABLE dw.fat_atr ADD CONSTRAINT for_fat_atr_tmp
    FOREIGN KEY (srk_tmp) REFERENCES dw.dim_tmp (srk_tmp) ON DELETE RESTRICT;

ALTER TABLE dw.fat_atr ADD CONSTRAINT for_fat_atr_cia
    FOREIGN KEY (srk_cia) REFERENCES dw.dim_cia (srk_cia) ON DELETE RESTRICT;

ALTER TABLE dw.fat_atr ADD CONSTRAINT for_fat_atr_apt
    FOREIGN KEY (srk_apt) REFERENCES dw.dim_apt (srk_apt) ON DELETE RESTRICT;

-- Checks mínimos (consistência básica)
ALTER TABLE dw.fat_atr ADD CONSTRAINT chk_fat_atr_del_le_arr
    CHECK (qtd_atr_del <= qtd_voo_arr);

ALTER TABLE dw.fat_atr ADD CONSTRAINT chk_fat_atr_cnt_nng
    CHECK (
        qtd_voo_arr >= 0 AND qtd_atr_del >= 0 AND qtd_voo_can >= 0 AND qtd_voo_div >= 0 AND
        qtd_atr_cia >= 0 AND qtd_atr_cli >= 0 AND qtd_atr_nas >= 0 AND qtd_atr_seg >= 0 AND qtd_atr_aer_tar >= 0
    );

ALTER TABLE dw.fat_atr ADD CONSTRAINT chk_fat_atr_val_nng
    CHECK (
        val_atr_mnt >= 0 AND
        val_atr_cia_mnt >= 0 AND val_atr_cli_mnt >= 0 AND val_atr_nas_mnt >= 0 AND
        val_atr_seg_mnt >= 0 AND val_atr_aer_tar_mnt >= 0
    );

-- Anti NaN/Inf (enxuto)
ALTER TABLE dw.fat_atr ADD CONSTRAINT chk_fat_atr_val_atr_mnt_nan
    CHECK (val_atr_mnt::text !~* '^(nan|inf|-inf)$');

ALTER TABLE dw.fat_atr ADD CONSTRAINT chk_fat_atr_val_tax_atr_nan
    CHECK (val_tax_atr IS NULL OR val_tax_atr::text !~* '^(nan|inf|-inf)$');

ALTER TABLE dw.fat_atr ADD CONSTRAINT chk_fat_atr_val_atr_pvo_nan
    CHECK (val_atr_pvo IS NULL OR val_atr_pvo::text !~* '^(nan|inf|-inf)$');

-- Índices (joins e filtros no BI)
CREATE INDEX idx_fat_atr_tmp ON dw.fat_atr(srk_tmp);
CREATE INDEX idx_fat_atr_cia ON dw.fat_atr(srk_cia);
CREATE INDEX idx_fat_atr_apt ON dw.fat_atr(srk_apt);
