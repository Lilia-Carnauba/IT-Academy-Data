-- Exercici 1 -- Analisis previa 
USE transactions;
SHOW TABLES;
DESCRIBE company;
DESCRIBE transaction;
SELECT COUNT(*) FROM transaction; 
SELECT COUNT(*) FROM company;

-- Exercici 2
SELECT DISTINCT c.country AS Países
FROM transaction AS t
JOIN company c ON t.company_id = c.id
WHERE t.declined = 0
ORDER BY Países;

SELECT COUNT(DISTINCT c.country) AS Cantidad_Países_Venta
FROM transaction AS t
JOIN company c ON t.company_id = c.id
WHERE t.declined = 0;

SELECT c.company_name AS Empresa,
AVG(t.amount) AS Top_Media_Ventas,
c.id AS ID_Empresa
FROM transaction AS t
JOIN company c ON t.company_id = c.id
WHERE t.declined = 0
GROUP BY Empresa, c.id
ORDER BY Top_Media_Ventas DESC
LIMIT 1;

-- Exercici 3 
SELECT *
FROM transaction AS t
WHERE t.company_id IN (SELECT c.id
                     FROM company AS c
                     WHERE c.country = 'Germany') AND t.declined = 0;


SELECT c.company_name AS Empresa
FROM company AS c
WHERE c.id IN (
    SELECT t.company_id
    FROM transaction AS t
    WHERE t.amount > (SELECT AVG(amount) FROM transaction)
);


SELECT c.company_name AS Empresa_sin_transacciones
FROM company AS c
WHERE c.id NOT IN (
    SELECT company_id
    FROM transaction
    WHERE company_id IS NOT NULL);

-- Output a 0, comprobación 
SELECT COUNT(*) FROM company;
SELECT COUNT(DISTINCT company_id) FROM transaction;
-- en ambas consultas aparecen la misma cantidad de empresas por lo que no hay nada para eliminar

-- Exercici 4
CREATE TABLE IF NOT EXISTS credit_card (
    id VARCHAR(15) PRIMARY KEY,
    iban VARCHAR(40),
    pan VARCHAR(20),
    pin VARCHAR(4),
    cvv VARCHAR(4), -- P2P
    expiring_date DATE -- P2P
);
-- (Comprobrando carga de datos) Mirar si en la tabla transaction tiene alguna tarjeta que no está en la tabla credict_card
SELECT DISTINCT credit_card_id
FROM transaction
WHERE credit_card_id NOT IN (SELECT id FROM credit_card);
-- Crear relacion entre tablas
ALTER TABLE transaction
ADD CONSTRAINT fk_transaction_credit_card
FOREIGN KEY (credit_card_id) REFERENCES credit_card(id);

-- Exercici 5 - primero hago la consulta para localizar el registro:
SELECT *
FROM credit_card
WHERE id = 'CcU-2938';
-- Actualización de IBAN tal como pide RRHH
UPDATE credit_card
SET iban = 'TR323456312213576817699999'
WHERE id = 'CcU-2938';
-- Comprobación de cambio en la BBDD
SELECT *
FROM credit_card
WHERE id = 'CcU-2938';

-- Exercici 6 
-- comprobación de entradas
SELECT * 
FROM credit_card 
WHERE id = 'CcU-9999';
SELECT * 
FROM company 
WHERE id = 'b-9999';
-- Inserción de registros en las tablas:
INSERT INTO credit_card (id) VALUES ('CcU-9999');
INSERT INTO company (id) VALUES ('b-9999');
-- Inserción de linea del enunciado sin timestamp, respetando la categoria de cada campo
INSERT INTO transaction (id, credit_card_id, company_id, user_id, lat, longitude, amount, declined)
VALUES ('108B1D1D-5B23-A76C-55EF-C568E49A99DD', 'CcU-9999', 'b-9999', 9999, 829.999, -117.999, 111.11, 0);
-- Comprobación de la inserción de lina con informaciones descritas
SELECT * 
FROM transaction
WHERE id = '108B1D1D-5B23-A76C-55EF-C568E49A99DD';

-- Exercici 7
-- Para registrar el antes y despues del ejercicico: 
SHOW COLUMNS 
FROM credit_card;
-- Para borrar la columna
ALTER TABLE credit_card
DROP COLUMN pan;
-- Para verificar el cambio
SHOW COLUMNS 
FROM credit_card;

-- Exercici 8
-- Creamos la base de datos
    CREATE DATABASE IF NOT EXISTS db_ex_8;
    USE db_ex_8;

 -- Creamos la tabla companies
    CREATE TABLE IF NOT EXISTS companies (
        company_id VARCHAR(50) PRIMARY KEY,
        company_name VARCHAR(255),
        phone VARCHAR(15),
        email VARCHAR(100),
        country VARCHAR(100),
        website VARCHAR(255),
        merchant_category VARCHAR(100),
        merchant_price_position VARCHAR(100)

    );

 -- Creamos la tabla credit_cards
    CREATE TABLE IF NOT EXISTS credit_cards (
        id VARCHAR(50) PRIMARY KEY,
        user_id VARCHAR(50),
        iban VARCHAR(100),
        pan	INT,
        pin	INT,
        cvv	INT,
        track1 VARCHAR(100),
        track2 VARCHAR(100),
        expiring_date DATE,
        card_type VARCHAR(50),
        card_renewal_flag BOOLEAN
    );

 -- Creamos la tabla user
    CREATE TABLE IF NOT EXISTS user (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100),
    surname VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(100),
    birth_date VARCHAR(100),
    country VARCHAR(100),
    city VARCHAR(100),
    postal_code VARCHAR(20),
    address VARCHAR(100),
    signup_date DATE,
    user_segment VARCHAR(100),
    income_band VARCHAR(50),
    continent VARCHAR(20)
);

 -- Creamos la tabla products
  CREATE TABLE IF NOT EXISTS products (
        id VARCHAR(50) PRIMARY KEY,
        product_name VARCHAR(100),
        price VARCHAR(20),
        colour VARCHAR(20),
        weight FLOAT,
        warehouse_id VARCHAR(50),
        category VARCHAR(100),
        brand VARCHAR(100),
        cost VARCHAR(20),
        launch_date	DATE
    );

-- Creamos la tabla transactions
    CREATE TABLE IF NOT EXISTS transactions (
        id VARCHAR(50) PRIMARY KEY,
        card_id VARCHAR(50),
        business_id VARCHAR(50), 
        timestamp TIMESTAMP,
        amount DECIMAL(10, 2),
        declined BOOLEAN,
        product_ids VARCHAR(50), 
        user_id VARCHAR(50),
        lat FLOAT,
        longitude FLOAT,
        discount_amount FLOAT,
        tax_amount FLOAT,
        shipping_amount FLOAT,
        channel VARCHAR(50),
        campaign_id	VARCHAR(50),
        device_type VARCHAR(50),
        is_international BOOLEAN,
        decline_reason VARCHAR(50),
        distance_km FLOAT,
        FOREIGN KEY (business_id) REFERENCES companies(company_id),
        FOREIGN KEY (card_id) REFERENCES credit_cards(id),
        FOREIGN KEY (user_id) REFERENCES user(id)

    );



LOAD DATA INFILE '/opt/homebrew/var/mysql-files/companies.csv'
INTO TABLE companies
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
-- 100 líneas

LOAD DATA INFILE '/opt/homebrew/var/mysql-files/credit_cards.csv'
INTO TABLE credit_cards
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
-- 5.000 líneas

LOAD DATA INFILE '/opt/homebrew/var/mysql-files/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
-- 100 líneas

LOAD DATA INFILE '/opt/homebrew/var/mysql-files/transactions.csv'
INTO TABLE transactions
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
-- 2.407 líneas

LOAD DATA INFILE '/opt/homebrew/var/mysql-files/american_users.csv'
INTO TABLE user
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, name, surname, phone, email, birth_date, country, city, postal_code, address, signup_date, user_segment, income_band)
SET continent = 'American';
-- 1.010 líneas

LOAD DATA INFILE '/opt/homebrew/var/mysql-files/european_users.csv'
INTO TABLE user
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, name, surname, phone, email, birth_date, country, city, postal_code, address, signup_date, user_segment, income_band)
SET continent = 'European';
-- 3.990 líneas					


-- Exercici 9
SELECT *
FROM user
WHERE id IN (SELECT user_id
             FROM transactions
             GROUP BY user_id
             HAVING COUNT(id) > 80);

-- Exercici 10 
SELECT cc.iban, ROUND(AVG(t.amount), 2) AS Media_Amount
FROM transactions AS t
JOIN credit_cards AS cc ON cc.id = t.card_id
WHERE t.business_id = (SELECT company_id
                      FROM companies
                      WHERE company_name = 'Donec Ltd') AND t.declined = 0
GROUP BY cc.iban;

-- Nivel 2 - Exercici 1
SELECT DATE(t.timestamp) AS Fecha,
       ROUND(SUM(t.amount), 2) AS Total_Ventas
FROM transactions AS t
WHERE declined = 0
GROUP BY Fecha
ORDER BY Total_Ventas DESC
LIMIT 5;

-- Nivel 2 - Exercici 2
SELECT c.company_name AS Nombre,
       c.phone AS Telefono,
       c.country AS Pais,
       DATE(t.timestamp) AS Fecha,
       t.amount AS Amount
FROM transactions AS t
JOIN companies AS c ON c.company_id = t.business_id
WHERE t.amount BETWEEN 350 AND 400
  AND DATE(t.timestamp) IN ('2015-04-29', '2018-07-20', '2024-03-13') AND t.declined = 0
ORDER BY Amount DESC;

-- Nivel 2 - Exercici 3
SELECT c.company_name AS Empresa,
       COUNT(t.id) AS Num_Transacciones,
       CASE
           WHEN COUNT(t.id) >= 400 THEN '400 o más'
           ELSE 'Menos de 400'
       END AS Clasificacion
FROM transactions AS t
JOIN companies AS c ON c.company_id = t.business_id
WHERE t.declined = 0
GROUP BY c.company_id, Empresa
ORDER BY Num_Transacciones DESC; -- simplemente para conferir si la clasificación fue correcta

-- Nivel 2 - Exercici 4 - localizar el registro que deve ser eliminado
SELECT *
FROM transactions
WHERE id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';
DELETE FROM transactions -- eliminar fila de la tabla
WHERE id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';

-- Nivel 2 - Exercici 5
CREATE VIEW Vista_Marketing AS
SELECT c.company_name AS Nombre_Empresa,
       c.phone AS Telefono,
       c.country AS Pais,
       ROUND(AVG(t.amount), 2) AS Media_Compra
FROM transactions AS t
JOIN companies AS c ON c.company_id = t.business_id
WHERE t.declined = 0
GROUP BY c.company_id, Nombre_Empresa, Telefono, Pais;

SELECT *
FROM Vista_Marketing
ORDER BY Media_Compra DESC;

-- Nivel 3 - Exercici 1

CREATE TABLE IF NOT EXISTS estado_tarjeta AS
SELECT card_id,
       CASE
           WHEN SUM(declined) = 3 THEN 'inactiva'
           ELSE 'activa'
       END AS status
FROM (
    SELECT card_id, declined,
           ROW_NUMBER() OVER (PARTITION BY card_id ORDER BY timestamp DESC) AS rn
    FROM transactions
) AS ranking
WHERE rn <= 3
GROUP BY card_id;

-- Por fin la consulta solicitada
SELECT COUNT(*) AS Tarjetas_Activas
FROM estado_tarjeta
WHERE status = 'activa';

-- Comprobación de clasificacion (SELECT COUNT(*) AS Tarjetas_Activas FROM estado_tarjeta WHERE status = 'inactiva';)

-- Nivel 3 - Exercici 2

-- Creación de la tabla intermedia venta_producto 
CREATE TABLE venta_producto (
    transaction_id VARCHAR(50),
    product_id VARCHAR(50),
    PRIMARY KEY (transaction_id, product_id),
    FOREIGN KEY (transaction_id) REFERENCES transactions(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);

-- Para rellenar la nueva tabla:
INSERT INTO venta_producto (transaction_id, product_id)
SELECT t.id, jt.product_id
FROM transactions t
JOIN JSON_TABLE(
  CONCAT('["', REPLACE(REPLACE(t.product_ids, ' ', ''), ',', '","'), '"]'),
  '$[*]' COLUMNS (product_id VARCHAR(50) PATH '$')
) AS jt;

-- Comprobando valores de la nueva tabla
SELECT COUNT(*) FROM venta_producto;

-- Comprobando que todos los productos que están en transaction están en la nueva tabla: 
SELECT t.id,
       LENGTH(t.product_ids) - LENGTH(REPLACE(t.product_ids, ',', '')) + 1 AS esperados,
       COUNT(vp.product_id) AS insertados
FROM transactions t
LEFT JOIN venta_producto vp ON t.id = vp.transaction_id
GROUP BY t.id, t.product_ids
HAVING esperados <> insertados;


-- Veces producto vendido
SELECT p.id, p.product_name, COUNT(vp.transaction_id) AS veces_vendido
FROM products p
LEFT JOIN venta_producto vp ON p.id = vp.product_id
GROUP BY p.id, p.product_name
ORDER BY veces_vendido DESC;


