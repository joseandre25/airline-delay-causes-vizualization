-- 1. Ranking Top 3 Eficiência por Ano CTE
WITH metricas_anuais AS (
    SELECT
        t.num_ano,
        c.nom_cia,
        SUM(f.qtd_voo_cgd) AS total_voos,
        SUM(f.qtd_voo_can + f.qtd_atr_ats) AS voos_problematicos
    FROM dw.fat_atr f
    JOIN dw.dim_tmp t ON f.srk_tmp = t.srk_tmp
    JOIN dw.dim_cia c ON f.srk_cia = c.srk_cia
    GROUP BY t.num_ano, c.nom_cia
),
ranking_calculado AS (
    SELECT
        num_ano,
        nom_cia,
        total_voos,
        ROUND((1.0 - (voos_problematicos::NUMERIC / NULLIF(total_voos, 0))) * 100, 2) AS taxa_eficiencia,
        DENSE_RANK() OVER (PARTITION BY num_ano ORDER BY (1.0 - (voos_problematicos::NUMERIC / NULLIF(total_voos, 0))) DESC) AS ranking
    FROM metricas_anuais
    WHERE total_voos > 100 
)
SELECT * FROM ranking_calculado
WHERE ranking <= 3
ORDER BY num_ano DESC, ranking ASC;

-- 2. Pareto 80/20 Atrasos por Aeroporto (Soma Acumulada)
WITH total_atraso_apt AS (
    SELECT
        a.nom_apt,
        SUM(f.val_atr_mnt) AS total_minutos_atraso
    FROM dw.fat_atr f
    JOIN dw.dim_apt a ON f.srk_apt = a.srk_apt
    GROUP BY a.nom_apt
),
calculo_acumulado AS (
    SELECT
        nom_apt,
        total_minutos_atraso,
        SUM(total_minutos_atraso) OVER () AS total_global,
        SUM(total_minutos_atraso) OVER (ORDER BY total_minutos_atraso DESC) AS atraso_acumulado
    FROM total_atraso_apt
    WHERE total_minutos_atraso > 0
)
SELECT
    nom_apt,
    total_minutos_atraso,
    ROUND((atraso_acumulado / NULLIF(total_global,0)) * 100, 2) AS pct_acumulado
FROM calculo_acumulado
ORDER BY total_minutos_atraso DESC;

-- 3. Crescimento Mês a Mês (MoM) de Voos, trazendo a taxa do voo anterior
WITH voos_mensais AS (
    SELECT
        t.num_ano,
        t.num_mes,
        t.nom_mes,
        SUM(f.qtd_voo_cgd) AS voos_atuais
    FROM dw.fat_atr f
    JOIN dw.dim_tmp t ON f.srk_tmp = t.srk_tmp
    GROUP BY t.num_ano, t.num_mes, t.nom_mes
)
SELECT
    num_ano,
    num_mes,
    nom_mes,
    voos_atuais,
    LAG(voos_atuais) OVER (ORDER BY num_ano, num_mes) AS voos_mes_anterior,
    ROUND(
        ((voos_atuais - LAG(voos_atuais) OVER (ORDER BY num_ano, num_mes))::NUMERIC / 
        NULLIF(LAG(voos_atuais) OVER (ORDER BY num_ano, num_mes), 0)) * 100, 
    2) AS variacao_percentual
FROM voos_mensais
ORDER BY num_ano DESC, num_mes DESC;

-- 4. Big Numbers: Funil Operacional (Programados vs Realizados vs Perdas)
SELECT 
    t.num_ano,
    t.nom_mes,
    SUM(f.qtd_voo_cgd + f.qtd_voo_can + f.qtd_voo_div) AS voos_programados,
    SUM(f.qtd_voo_cgd) AS voos_realizados,
    SUM(f.qtd_voo_can) AS qtd_cancelados,
    SUM(f.qtd_voo_div) AS qtd_desviados,
    SUM(f.qtd_atr_ats) AS qtd_atrasados
FROM dw.fat_atr f
JOIN dw.dim_tmp t ON f.srk_tmp = t.srk_tmp
GROUP BY t.num_ano, t.num_mes, t.nom_mes
ORDER BY t.num_ano, t.num_mes;

-- 5. Breakdown de Causas de Atraso em Minutos
SELECT 
    t.num_ano,
    c.nom_cia,
    SUM(f.val_atr_cia_mnt) AS min_culpa_cia,
    SUM(f.val_atr_nas_mnt) AS min_culpa_sistema_aereo,
    SUM(f.val_atr_seg_mnt) AS min_culpa_seguranca,
    SUM(f.val_atr_cli_mnt) AS min_culpa_clima,
    SUM(f.val_atr_aer_tar_mnt) AS min_culpa_aeronave_tardia
FROM dw.fat_atr f
JOIN dw.dim_tmp t ON f.srk_tmp = t.srk_tmp
JOIN dw.dim_cia c ON f.srk_cia = c.srk_cia
GROUP BY t.num_ano, c.nom_cia;

-- 6. Matriz de Calor (Heatmap): Sazonalidade de Atrasos
SELECT 
    t.nom_mes,
    t.num_mes,
    c.nom_cia,
    SUM(f.qtd_atr_ats) AS total_atrasos,
    SUM(f.qtd_voo_cgd) AS total_voos,
    ROUND((SUM(f.qtd_atr_ats)::NUMERIC / NULLIF(SUM(f.qtd_voo_cgd),0)) * 100, 2) AS taxa_atraso
FROM dw.fat_atr f
JOIN dw.dim_tmp t ON f.srk_tmp = t.srk_tmp
JOIN dw.dim_cia c ON f.srk_cia = c.srk_cia
GROUP BY t.nom_mes, t.num_mes, c.nom_cia
ORDER BY t.num_mes;

-- 7. Scatter Plot: Severidade (Média) vs Frequência (Total)
SELECT 
    a.nom_apt,
    SUM(f.qtd_atr_ats) AS frequencia_atrasos,
    ROUND(AVG(NULLIF(f.val_atr_mnt, 0)), 1) AS media_minutos_por_atraso
FROM dw.fat_atr f
JOIN dw.dim_apt a ON f.srk_apt = a.srk_apt
GROUP BY a.nom_apt
HAVING SUM(f.qtd_atr_ats) > 50 
ORDER BY frequencia_atrasos DESC;

-- 8. Evolução Temporal de Cancelamentos e Desvios
SELECT 
    t.num_ano,
    t.num_mes,
    t.dat_tmp,
    SUM(f.qtd_voo_can) AS total_cancelados,
    SUM(f.qtd_voo_div) AS total_desviados
FROM dw.fat_atr f
JOIN dw.dim_tmp t ON f.srk_tmp = t.srk_tmp
GROUP BY t.num_ano, t.num_mes, t.dat_tmp
ORDER BY t.num_ano, t.num_mes;

-- 9. Market Share (Volume de Voos por Cia)
SELECT 
    t.num_ano,
    c.nom_cia,
    SUM(f.qtd_voo_cgd) AS voos_realizados
FROM dw.fat_atr f
JOIN dw.dim_cia c ON f.srk_cia = c.srk_cia
JOIN dw.dim_tmp t ON f.srk_tmp = t.srk_tmp
GROUP BY t.num_ano, c.nom_cia
ORDER BY t.num_ano, voos_realizados DESC;

-- 10. Efeito Dominó: Atrasos causados por aeronave anterior
SELECT 
    a.nom_apt,
    SUM(f.qtd_atr_aer_tar) AS qtd_atrasos_efeito_domino,
    SUM(f.val_atr_aer_tar_mnt) AS minutos_efeito_domino
FROM dw.fat_atr f
JOIN dw.dim_apt a ON f.srk_apt = a.srk_apt
GROUP BY a.nom_apt
ORDER BY minutos_efeito_domino DESC
LIMIT 20;