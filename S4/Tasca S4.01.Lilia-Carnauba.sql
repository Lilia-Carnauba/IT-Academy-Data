-- Nivell 1:
-- Exercici 1: 
-- 1. Escriu la consulta que uneix (JOIN) transaccions i companyies.
-- 2. Filtra els resultats per la data indicada i el país "Germany".
SELECT * 
FROM `sprint3-analytics-lilia.sprint3_silver.transactions_clean` AS t
JOIN `sprint3-analytics-lilia.sprint3_silver.companies_clean` AS c
  ON t.business_id = c.company_id
WHERE c.country = 'Germany'
    AND DATE(t.`timestamp`) = '2022-03-12';

-- Exercici 2: 
-- Pas 1: Generació de Dades Recents (Mocking Data) 
 
CREATE OR REPLACE TABLE `sprint3-analytics-lilia.sprint3_silver.transactions_recent` AS
SELECT * 
    EXCEPT(`timestamp`),
    TIMESTAMP_SUB(CURRENT_TIMESTAMP(),
    INTERVAL CAST(RAND() * 50 AS INT64) DAY) AS `timestamp`
FROM `sprint3-analytics-lilia.sprint3_silver.transactions_clean`;

-- Pas 2: Creació de la Taula Optimitzada (Partitioning & Clustering)

CREATE OR REPLACE TABLE `sprint3-analytics-lilia.sprint3_gold.fact_transactions_optimized`
PARTITION BY DATE(`timestamp`)
CLUSTER BY business_id
AS
SELECT *
FROM `sprint3-analytics-lilia.sprint3_silver.transactions_recent`;

-- Exercici 3: 
-- Pas 1:
SELECT *
FROM `sprint3-analytics-lilia.sprint3_silver.transactions_recent`
WHERE DATE(`timestamp`) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY);

-- Pas 2:
SELECT *
FROM `sprint3-analytics-lilia.sprint3_gold.fact_transactions_optimized`
WHERE DATE(`timestamp`) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY);

-- Exercici 4: 

CREATE MATERIALIZED VIEW `sprint3-analytics-lilia.sprint3_gold.mv_daily_sales` AS
SELECT
  DATE(`timestamp`) AS venta_diaria,
  SUM(amount) AS total_venta
FROM `sprint3-analytics-lilia.sprint3_gold.fact_transactions_optimized`
WHERE declined = 0
GROUP BY venta_diaria;

SELECT
  venta_diaria,
  ROUND(total_venta, 2) AS total_venta
FROM `sprint3-analytics-lilia.sprint3_gold.mv_daily_sales`
ORDER BY venta_diaria DESC;


-- Nivel 2 
-- Exercici 1
WITH Vip_Stats AS (
  SELECT
    user_id,
    SUM(amount) AS total_gastat,
    COUNT(*) AS num_compres,
    ROUND(AVG(amount), 2) AS tiquet_mig,
    MAX(amount) AS max_compra
  FROM `sprint3-analytics-lilia.sprint3_silver.transactions_clean``
  WHERE declined = 0
  GROUP BY user_id
  HAVING SUM(amount) > 500
)
SELECT 
  u.user_id,
  CONCAT(u.name, ' ', u.surname) AS nom_complet,
  u.email,
  v.num_compres,
  v.tiquet_mig,
  v.max_compra,
  ROUND(v.total_gastat, 2) AS total_gastat
FROM Vip_Stats AS v
JOIN `sprint3-analytics-lilia.sprint3_silver.users_combined`AS u
  ON v.user_id = u.user_id
ORDER BY v.total_gastat DESC;

-- Exercici 2
WITH ventas AS (
  SELECT 
    venta_diaria AS Data,
    total_venta AS ventas_hoy,
    LAG(total_venta) OVER (ORDER BY venta_diaria) AS ventas_ayer
  FROM `sprint3-analytics-lilia.sprint3_gold.mv_daily_sales`
)
SELECT
  Data,
  ROUND(ventas_hoy, 2) AS ventas_hoy,
  ROUND(ventas_ayer, 2) AS ventas_ayer,
  ROUND(SAFE_DIVIDE(ventas_hoy - ventas_ayer, ventas_ayer) * 100, 2) AS diff_percentual
FROM ventas
ORDER BY Data;

-- Exercici 3
SELECT
  venta_diaria AS Data,
  ROUND(total_venta, 2) AS ventas_hoy,
  ROUND(
    SUM(total_venta) OVER (
      PARTITION BY EXTRACT(YEAR FROM venta_diaria)
      ORDER BY venta_diaria
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2
  ) AS ventas_acumuladas_YTD
FROM `sprint3-analytics-lilia.sprint3_gold.mv_daily_sales`
ORDER BY Data;

-- Exercici 4
WITH tercera_compra AS (
  SELECT
    user_id,
    DATE(`timestamp`) AS data_tercera_compra,
    amount AS importe_tercera_compra,
    ROUND(
      AVG(amount) OVER (
        PARTITION BY user_id
        ORDER BY `timestamp`, transaction_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
      ), 2
    ) AS mitjana_3_primeres
  FROM `sprint3-analytics-lilia.sprint3_silver.transactions_clean`
  WHERE declined = 0
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY user_id
    ORDER BY `timestamp`, transaction_id
  ) = 3
)
SELECT
  u.user_id,
  CONCAT(u.name, ' ', u.surname) AS nombre_completo,
  u.email,
  t.data_tercera_compra,
  t.importe_tercera_compra,
  t.mitjana_3_primeres
FROM tercera_compra AS t
JOIN `sprint3-analytics-lilia.sprint3_silver.users_combined` AS u
  ON t.user_id = u.user_id
ORDER BY u.user_id;

-- Nivel 3
-- Exercici 1
CREATE OR REPLACE TABLE `sprint3-analytics-lilia.sprint3_gold.dim_transactions_flat` AS
SELECT
  t.transaction_id,
  t.`timestamp`,
  t.amount AS total_ticket,
  pid AS product_sku,
  p.name AS product_name,
  SAFE_CAST(REPLACE(p.price, '$', '') AS NUMERIC) AS product_price
FROM `sprint3-analytics-lilia.sprint3_silver.transactions_clean` AS t
CROSS JOIN UNNEST(t.product_ids) AS pid
LEFT JOIN `sprint3-analytics-lilia.sprint3_silver.products_clean` AS p
  ON SAFE_CAST(p.product_id AS INT64) = pid
WHERE t.declined = 0;


-- Exercici 2
SELECT
  product_name,
  COUNT(*) AS unidades_vendidas
FROM `sprint3-analytics-lilia.sprint3_gold.dim_transactions_flat`
WHERE product_name IS NOT NULL
GROUP BY product_name
ORDER BY unidades_vendidas DESC, product_name
LIMIT 5;

-- Exercici 3
-- Pass 1: 
CREATE OR REPLACE FUNCTION `sprint3-analytics-lilia.sprint3_gold.calculate_tax`(amount NUMERIC)
RETURNS NUMERIC
AS (ROUND(amount * 1.21, 2));

-- Pass 2
CREATE OR REPLACE TABLE `sprint3-analytics-lilia.sprint3_gold.dim_transactions_flat` AS
WITH flat AS (
  SELECT
    t.transaction_id,
    t.`timestamp`,
    t.amount AS total_ticket,
    pid AS product_sku,
    p.name AS product_name,
    SAFE_CAST(REPLACE(p.price, '$', '') AS NUMERIC) AS product_price
  FROM `sprint3-analytics-lilia.sprint3_silver.transactions_clean` AS t
  CROSS JOIN UNNEST(t.product_ids) AS pid
  LEFT JOIN `sprint3-analytics-lilia.sprint3_silver.products_clean` AS p
    ON SAFE_CAST(p.product_id AS INT64) = pid
  WHERE t.declined = 0
)
SELECT *,
  `sprint3-analytics-lilia.sprint3_gold.calculate_tax`(product_price) AS product_price_tax_inc
FROM flat;
