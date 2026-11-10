-- 1.1 Crear proyecto y dataset gold en la terrminal
gcloud projects create sprint3-analytics-lilia --name="sprint3-analytics-lilia"
gcloud config set project sprint3-analytics-lilia
gcloud config get-value project
gcloud services enable bigquery.googleapis.com
bq --location=EU mk --dataset sprint3-analytics-lilia:sprint3-gold
bq ls --project_id=sprint3-analytics-lilia

-- 1.2 crear por la interfaz la capa bronze 
-- 1.3 Usar sql para crear la capa silver
CREATE SCHEMA IF NOT EXISTS `sprint3-analytics-lilia.sprint3_silver`
OPTIONS (location = 'EU');

-- Comprobacion creacion y localizacion de todos los datasets
SELECT schema_name, location
FROM `region-eu`.INFORMATION_SCHEMA.SCHEMATA;

-- 2 Carga de datos tal como descrito en la tabla:
CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-lilia.sprint3_bronze.transactions_raw`
OPTIONS (
    format = 'CSV',
    uris = ['gs://bootcamp-data-analytics-public/ERP/transactions.csv'],
    field_delimiter = ';',
    skip_leading_rows = 1
);

CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-lilia.srpint3_bronze.european_users_raw`
OPTIONS (
    format = 'CSV',
    uris = ['gs://bootcamp-data-analytics-public/CRM/european_users.csv'],
    field_delimiter = ';',
    skip_leading_rows = 1
);

CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-lilia.sprint3_bronze.american_users_raw`
OPTIONS (
    format = 'CSV',
    uris = ['gs://bootcamp-data-analytics-public/CRM/american_users.csv'],
    field_delimiter = ';',
    skip_leading_rows = 1
);

CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-lilia.sprint3_bronze.credit_cards_raw`
OPTIONS (
    format = 'CSV',
    uris = ['gs://bootcamp-data-analytics-public/CRM/credit_cards.csv'],
    field_delimiter = ';',
    skip_leading_rows = 1
);

CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-lilia.sprint3_bronze.companies_raw` (
company_id STRING,
company_name STRING,
phone STRING,
email STRING,
country STRING,
website STRING
)
OPTIONS (
    format = 'CSV',
    uris = ['gs://bootcamp-data-analytics-public/ERP/companies.csv'],
    skip_leading_rows = 1
);

-- 5. El teu cap vol saber quins van ser els 5 dies amb més ingressos de l'any 2021
SELECT 
    DATE(`timestamp`) AS fecha,
    ROUND(SUM(amount), 2) AS total_ingresos
FROM `sprint3-analytics-lilia.sprint3_bronze.transactions_raw_native`
WHERE declined = 0
    AND EXTRACT(YEAR FROM `timestamp`) = 2021
GROUP BY fecha
ORDER BY total_ingresos DESC
LIMIT 5;

-- Llista el nom, país i data de les transaccions realitzades per empreses que van fer operacions entre 100 i 200 euros
-- en alguna d'aquestes dates: 29-04-2015, 20-07-2018 o 13-03-2024.
SELECT
  c.company_name AS empresa,
  c.country AS pais,
  DATE(t.`timestamp`) AS fecha
FROM `sprint3-analytics-lilia.sprint3_bronze.transactions_raw_native` AS t
JOIN `sprint3-analytics-lilia.sprint3_bronze.companies_raw` AS c
  ON t.business_id = c.company_id
WHERE
  t.amount BETWEEN 100 AND 200
  AND DATE(t.`timestamp`)
    IN (DATE '2015-04-29', DATE '2018-07-20', DATE '2024-03-13')
  AND declined = 0
ORDER BY fecha;

-- Nivel 2 
-- Exercici 1

CREATE OR REPLACE TABLE `sprint3-analytics-lilia.sprint3_silver.products_clean` AS 
SELECT 
id AS product_id,
product_name AS name,
price,
colour,
weight,
SAFE_CAST(REPLACE(warehouse_id, 'WH-', '') AS INT64) AS warehouse_id,
category,
brand,
cost,
launch_date
FROM `sprint3-analytics-lilia.sprint3_bronze.products_raw`;

-- Verificacion nulos tras transformar tipo de dato
SELECT COUNT(*) AS filas_nulas
FROM `sprint3-analytics-lilia.sprint3_silver.products_clean`
WHERE warehouse_id IS NULL;
-- Comprobar tipo de dato tras las tranformaciones
SELECT column_name, data_type
FROM `sprint3-analytics-lilia.sprint3_silver`.INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'products_clean'
ORDER BY ordinal_position;

-- Limpiar price
CREATE OR REPLACE TABLE `sprint3-analytics-lilia.sprint3_silver.products_clean` AS 
SELECT 
id AS product_id,
product_name AS name,
SAFE_CAST(REPLACE(price, '$', '') AS FLOAT64) AS price,
colour,
weight,
SAFE_CAST(REPLACE(warehouse_id, 'WH-', '') AS INT64) AS warehouse_id,
category,
brand,
cost,
launch_date
FROM `sprint3-analytics-lilia.sprint3_bronze.products_raw`;

-- Nivel 2 
-- Exercici 2
CREATE OR REPLACE TABLE `sprint3-analytics-lilia.sprint3_silver.transactions_clean` AS 
SELECT 
    id AS transaction_id,
    card_id,
    business_id,
    timestamp,
    IFNULL(SAFE_CAST(amount AS FLOAT64), 0) AS amount,
    declined,
    ARRAY(
        SELECT SAFE_CAST(TRIM(p) AS INT64)
        FROM UNNEST(SPLIT(product_ids, ',')) AS p
        WHERE SAFE_CAST(TRIM(p) AS INT64) IS NOT NULL
    ) AS product_ids,
    user_id,
    SAFE_CAST(lat AS FLOAT64) AS lat,
    SAFE_CAST(longitude AS FLOAT64) AS longitude
FROM `sprint3-analytics-lilia.sprint3_bronze.transactions_raw_native`;

-- Nivel 2 
-- Exercici 3
CREATE OR REPLACE TABLE `sprint3-analytics-lilia.sprint3_silver.users_combined` AS 
SELECT 
id AS user_id,
name,
surname,
phone,
email,
birth_date,
country,
city,
postal_code,
address,
'USA' AS origin
FROM `sprint3-analytics-lilia.sprint3_bronze.american_users_raw`

UNION ALL 

SELECT 
id AS user_id,
name,
surname,
phone,
email,
birth_date,
country,
city,
postal_code,
address,
'Europe' AS origin
FROM `sprint3-analytics-lilia.sprint3_bronze.european_users_raw`;

-- Nivel 2 
-- Exercici 4 
-- Crear tabla credit_card
CREATE OR REPLACE TABLE `sprint3-analytics-lilia.sprint3_silver.credit_card_clean` AS 
SELECT 
id AS card_id,
user_id,
iban,
pan,
pin,
cvv,
track1,
track2,
expiring_date
FROM `sprint3-analytics-lilia.sprint3_bronze.credit_card_raw`;

-- Crear tabla companies
CREATE OR REPLACE TABLE `sprint3-analytics-lilia.sprint3_silver.companies_clean` AS 
SELECT 
company_id,
company_name,
phone,
email,
country,
website
FROM `sprint3-analytics-lilia.sprint3_bronze.companies_raw`;

-- Nivel 3 
-- Exercici 1
CREATE OR REPLACE VIEW `sprint3-analytics-lilia.sprint3_gold.v_marketing_kpis`AS 
SELECT 
    c.company_name AS Empresa,
    c.phone AS Telefono,
    c.country AS Pais,
    ROUND(AVG(t.amount), 2) AS Media_compras,
    CASE
        WHEN AVG(t.amount) > 260 THEN 'Premium'
        ELSE 'Standard'
    END AS Clasificacion
FROM `sprint3-analytics-lilia.sprint3_silver.companies_clean` AS c
LEFT JOIN `sprint3-analytics-lilia.sprint3_silver.transactions_clean` AS t
    ON c.company_id = t.business_id
GROUP BY c.company_name, c.phone, c.country;

SELECT *
FROM `sprint3-analytics-lilia.sprint3_gold.v_marketing_kpis`
ORDER BY 
    CASE
    WHEN Clasificacion = 'Premium' THEN 0
    ELSE 1
    END,
    Media_compras DESC;


-- Nivel 3 
-- Exercici 2
CREATE OR REPLACE TABLE `sprint3-analytics-lilia.sprint3_gold.product_sales_ranking` AS
WITH sold AS (
    SELECT pid AS product_id
    FROM `sprint3-analytics-lilia.sprint3_silver.transactions_clean`,
        UNNEST(product_ids) AS pid
)
SELECT
    p.product_id,
    p.name,
    p.price,
    p.colour,
    COUNT(s.product_id) AS total_sold
FROM `sprint3-analytics-lilia.sprint3_silver.products_clean` AS p
LEFT JOIN sold AS s 
    ON SAFE_CAST(p.product_id AS INT64) = s.product_id
GROUP BY p.product_id, p.name, p.price, p.colour
ORDER BY total_sold DESC;

-- Nivel 3 
-- Exercici 3
select * 
FROM sprint3-analytics-lilia.sprint3_gold.product_sales_ranking;
