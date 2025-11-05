-- Create database
CREATE DATABASE banking_data_pipeline;
USE banking_data_pipeline;

-- Create customers table
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(100),
    age INT,
    city VARCHAR(100),
    income DECIMAL(10,2)
);

-- Create transactions table
CREATE TABLE transactions (
    txn_id INT PRIMARY KEY,
    customer_id INT,
    txn_date DATE,
    amount DECIMAL(10,2),
    txn_type VARCHAR(10),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
-- Insert customer data
INSERT INTO customers (customer_id, name, age, city, income) VALUES
(1, 'Rohan Mehta', 32, 'Mumbai', 90000),
(2, 'Priya Shah', 28, 'Bangalore', 75000),
(3, 'Amit Verma', 45, 'Pune', 110000),
(4, 'Neha Rao', 30, 'Delhi', 80000);

-- Insert transaction data
INSERT INTO transactions (txn_id, customer_id, txn_date, amount, txn_type) VALUES
(1, 1, '2025-09-15', 2500, 'debit'),
(2, 1, '2025-09-17', 10000, 'credit'),
(3, 2, '2025-09-20', 3000, 'debit'),
(4, 2, '2025-09-22', 8000, 'credit'),
(5, 3, '2025-09-25', 5000, 'debit'),
(6, 3, '2025-09-27', 7000, 'credit'),
(7, 4, '2025-09-28', 1500, 'debit'),
(8, 4, '2025-09-29', 9000, 'credit'),
(9, 4, '2025-09-29', 9000, 'credit');  -- duplicate to test cleanup

-- Step 1: Create temporary table with IDs to keep
CREATE TEMPORARY TABLE txn_keep_ids AS
SELECT MIN(txn_id) AS keep_id
FROM transactions
GROUP BY customer_id, txn_date, amount, txn_type;
SET SQL_SAFE_UPDATES = 0;

-- Now run your DELETE safely
DELETE FROM transactions
WHERE txn_id NOT IN (SELECT keep_id FROM txn_keep_ids);

-- Turn safe mode back ON
SET SQL_SAFE_UPDATES = 1;

SET SQL_SAFE_UPDATES = 0;
-- Step 2: Delete duplicates safely
DELETE FROM transactions
WHERE txn_id NOT IN (SELECT keep_id FROM txn_keep_ids);

-- Step 3: Drop temporary table
DROP TEMPORARY TABLE txn_keep_ids;

-- Step 4: Remove invalid rows (optional)
DELETE FROM transactions WHERE amount <= 0 OR customer_id IS NULL;
DELETE FROM customers WHERE name IS NULL;

-- Create or replace analytical view
CREATE OR REPLACE VIEW customer_financial_summary AS
SELECT
    c.customer_id,
    c.name,
    c.city,
    c.income,
    SUM(CASE WHEN t.txn_type = 'credit' THEN t.amount ELSE 0 END) AS total_credit,
    SUM(CASE WHEN t.txn_type = 'debit' THEN t.amount ELSE 0 END) AS total_debit,
    SUM(CASE WHEN t.txn_type = 'credit' THEN t.amount ELSE 0 END) -
    SUM(CASE WHEN t.txn_type = 'debit' THEN t.amount ELSE 0 END) AS net_balance
FROM customers c
LEFT JOIN transactions t ON c.customer_id = t.customer_id
GROUP BY c.customer_id, c.name, c.city, c.income;

SELECT name, city, net_balance
FROM customer_financial_summary
ORDER BY net_balance DESC
LIMIT 5;

SELECT city,
       ROUND(AVG(income), 2) AS avg_income,
       ROUND(AVG(net_balance), 2) AS avg_balance
FROM customer_financial_summary
GROUP BY city;

SELECT name,
       ROUND(total_credit / NULLIF(total_debit, 0), 2) AS credit_debit_ratio,
       net_balance
FROM customer_financial_summary;

SELECT name, city, net_balance
FROM customer_financial_summary
WHERE net_balance < 0;




