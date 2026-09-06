-- ============================================================
-- 06 - CARD PORTFOLIO OPTIMISATION ANALYSIS
-- Banking Data Analytics | Google BigQuery
-- ============================================================

-- Objective:
-- Optimize card offerings and usage to enhance customer value
-- and financial performance.


-- ============================================================
-- VI.A
-- List customers with an active credit card where the account
-- balance is 90% or more of the credit limit.
-- ============================================================

SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,

    cd.card_number,

    SAFE_CAST(
        cd.credit_limit AS FLOAT64
    ) AS credit_limit,

    a.balance,

    ROUND(
        a.balance
        / SAFE_CAST(cd.credit_limit AS FLOAT64)
        * 100,
        2
    ) AS percentage_credit_used

FROM `scaler-dsml-sql-498010.citibank.customers` c

JOIN `scaler-dsml-sql-498010.citibank.accounts` a
    ON c.customer_id = a.customer_id

JOIN `scaler-dsml-sql-498010.citibank.cards` cd
    ON a.account_id = cd.account_id

WHERE cd.card_status = 'ACTIVE'
  AND cd.card_type = 'CREDIT'
  AND a.balance >= 0.90
      * SAFE_CAST(cd.credit_limit AS FLOAT64);


-- ============================================================
-- VI.B
-- List each card type and month in 2025, showing total amount
-- spent, unique cardholders, and average transaction size.
-- ============================================================

SELECT
    cd.card_type,

    EXTRACT(
        MONTH FROM t.transaction_date
    ) AS month,

    SUM(t.amount) AS total_amount_spent,

    COUNT(DISTINCT cd.card_id) AS unique_cardholders,

    ROUND(
        AVG(t.amount),
        2
    ) AS average_transaction_size

FROM `scaler-dsml-sql-498010.citibank.transactions` t

JOIN `scaler-dsml-sql-498010.citibank.accounts` a
    ON t.account_id = a.account_id

JOIN `scaler-dsml-sql-498010.citibank.cards` cd
    ON a.account_id = cd.account_id

WHERE cd.card_status = 'ACTIVE'
  AND EXTRACT(
        YEAR FROM t.transaction_date
      ) = 2025

GROUP BY
    cd.card_type,
    month

ORDER BY
    cd.card_type,
    month;


-- ============================================================
-- VI.C
-- List each card type and transaction type, showing transaction
-- count, total transaction amount and average transaction amount.
-- ============================================================

SELECT
    cd.card_type,

    t.transaction_type,

    COUNT(t.transaction_id) AS transaction_count,

    SUM(t.amount) AS total_transaction_amount,

    ROUND(
        AVG(t.amount),
        2
    ) AS average_transaction_amount

FROM `scaler-dsml-sql-498010.citibank.cards` cd

JOIN `scaler-dsml-sql-498010.citibank.accounts` a
    ON cd.account_id = a.account_id

JOIN `scaler-dsml-sql-498010.citibank.transactions` t
    ON a.account_id = t.account_id

GROUP BY
    cd.card_type,
    t.transaction_type

ORDER BY
    cd.card_type,
    transaction_count DESC;
