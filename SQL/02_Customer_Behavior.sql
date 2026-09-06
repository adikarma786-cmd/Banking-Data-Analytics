-- 02 - CUSTOMER BEHAVIOR ANALYSIS
-- Banking Data Analytics | Google BigQuery

-- II.A - Balance category vs transaction frequency
WITH cte1 AS (
    SELECT DISTINCT
        a.customer_id,
        ROUND(AVG(a.balance), 2) AS avg_balance_per_customer,
        COUNT(t.transaction_id) AS transaction_count_per_customer
    FROM `scaler-dsml-sql-498010.citibank.accounts` a
    LEFT JOIN `scaler-dsml-sql-498010.citibank.transactions` t
        ON a.account_id = t.account_id
    GROUP BY a.customer_id
)
SELECT
    CASE
        WHEN avg_balance_per_customer > 50000 THEN 'High Balance'
        WHEN avg_balance_per_customer > 10000
             AND avg_balance_per_customer <= 50000 THEN 'Medium Balance'
        WHEN avg_balance_per_customer <= 10000 THEN 'Low Balance'
    END AS balance_category,
    ROUND(AVG(transaction_count_per_customer), 2) AS avg_transaction_count,
    COUNT(*) AS customer_count,
    ROUND(AVG(avg_balance_per_customer), 2) AS avg_balance
FROM cte1
GROUP BY balance_category
ORDER BY avg_transaction_count DESC;


-- II.B - Top two transaction months for each account type in 2025
WITH monthly_report AS (
    SELECT
        EXTRACT(MONTH FROM t.transaction_date) AS month,
        a.account_type,
        COUNT(t.transaction_id) AS transaction_count,
        SUM(t.amount) AS transaction_amount
    FROM `scaler-dsml-sql-498010.citibank.transactions` t
    JOIN `scaler-dsml-sql-498010.citibank.accounts` a
        ON a.account_id = t.account_id
    WHERE EXTRACT(YEAR FROM t.transaction_date) = 2025
    GROUP BY month, a.account_type
),
ranking AS (
    SELECT
        account_type,
        month,
        transaction_count,
        transaction_amount,
        ROW_NUMBER() OVER (
            PARTITION BY account_type
            ORDER BY transaction_count DESC
        ) AS rn
    FROM monthly_report
)
SELECT
    account_type,
    FORMAT_DATE('%B', DATE(2025, month, 1)) AS month_name,
    transaction_count,
    transaction_amount
FROM ranking
WHERE rn <= 2;


-- II.C - Credit card transactions by age group as of June 1, 2025
SELECT
    CASE
        WHEN DATE_DIFF(
            DATE '2025-06-01',
            SAFE.PARSE_DATE('%d-%m-%Y', cus.date_of_birth),
            YEAR
        ) < 30 THEN 'Under 30'
        WHEN DATE_DIFF(
            DATE '2025-06-01',
            SAFE.PARSE_DATE('%d-%m-%Y', cus.date_of_birth),
            YEAR
        ) BETWEEN 30 AND 50 THEN '30-50'
        WHEN DATE_DIFF(
            DATE '2025-06-01',
            SAFE.PARSE_DATE('%d-%m-%Y', cus.date_of_birth),
            YEAR
        ) > 50 THEN 'Over 50'
    END AS age_category,
    COUNT(t.transaction_id) AS transaction_count
FROM `scaler-dsml-sql-498010.citibank.customers` cus
JOIN `scaler-dsml-sql-498010.citibank.accounts` a
    ON a.customer_id = cus.customer_id
JOIN `scaler-dsml-sql-498010.citibank.cards` car
    ON car.account_id = a.account_id
JOIN `scaler-dsml-sql-498010.citibank.transactions` t
    ON t.account_id = a.account_id
WHERE car.card_type = 'CREDIT'
  AND SAFE.PARSE_DATE('%d-%m-%Y', cus.date_of_birth) IS NOT NULL
GROUP BY age_category
ORDER BY transaction_count DESC;


-- II.D - Top 10 customers by total active-account balance
WITH cte AS (
    SELECT
        c.customer_id,
        SUM(a.balance) AS total_balance,
        COUNT(a.account_id) AS total_accounts,
        MIN(a.opened_date) AS earliest_acc_open_date
    FROM `scaler-dsml-sql-498010.citibank.customers` c
    JOIN `scaler-dsml-sql-498010.citibank.accounts` a
        ON a.customer_id = c.customer_id
    WHERE a.status = 'ACTIVE'
    GROUP BY c.customer_id
    ORDER BY total_balance DESC
    LIMIT 10
)
SELECT
    CONCAT(c.first_name, ' ', c.last_name) AS name,
    c.email,
    cte.total_balance,
    cte.total_accounts,
    cte.earliest_acc_open_date
FROM cte
JOIN `scaler-dsml-sql-498010.citibank.customers` c
    ON c.customer_id = cte.customer_id;


-- II.E - Customers with more than one active loan
WITH loan_number AS (
    SELECT
        c.customer_id,
        COUNT(l.loan_id) AS number_of_active_loans,
        SUM(l.loan_amount) AS total_loan_amount
    FROM `scaler-dsml-sql-498010.citibank.customers` c
    JOIN `scaler-dsml-sql-498010.citibank.loans` l
        ON l.customer_id = c.customer_id
    WHERE l.status = 'ACTIVE'
    GROUP BY c.customer_id
)
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS name,
    l.number_of_active_loans,
    l.total_loan_amount
FROM `scaler-dsml-sql-498010.citibank.customers` c
JOIN loan_number l
    ON c.customer_id = l.customer_id
WHERE l.number_of_active_loans > 1
ORDER BY l.total_loan_amount DESC;
