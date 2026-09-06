-- ============================================================
-- 01 - INITIAL EXPLORATORY ANALYSIS
-- Banking Data Analytics
-- ============================================================

-- I.A
-- Retrieve data types for columns in the customers table

SELECT
    column_name,
    data_type
FROM `scaler-dsml-sql-498010.citibank.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'customers';


-- ============================================================
-- I.B
-- Find the date range of customer creation

SELECT
    MIN(created_at) AS min_creation_date,
    MAX(created_at) AS max_creation_date
FROM `scaler-dsml-sql-498010.citibank.customers`;


-- Find the date range of transactions

SELECT
    MIN(transaction_date) AS min_transaction_date,
    MAX(transaction_date) AS max_transaction_date
FROM `scaler-dsml-sql-498010.citibank.transactions`;


-- ============================================================
-- I.C
-- Count accounts by branch, account type and account status

SELECT
    b.branch_name,
    a.account_type,
    a.status,
    COUNT(a.account_id) AS total_number_of_accounts
FROM `scaler-dsml-sql-498010.citibank.branches` b
JOIN `scaler-dsml-sql-498010.citibank.accounts` a
    ON a.branch_id = b.branch_id
GROUP BY
    b.branch_name,
    a.account_type,
    a.status
ORDER BY
    b.branch_name,
    total_number_of_accounts DESC;
