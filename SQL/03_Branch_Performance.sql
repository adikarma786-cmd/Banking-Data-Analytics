-- ============================================================
-- 03 - BRANCH PERFORMANCE ANALYSIS
-- Banking Data Analytics | Google BigQuery
-- ============================================================

-- Objective:
-- Evaluate branch efficiency and contribution to business outcomes.


-- ============================================================
-- III.A
-- List the top two branches with the highest number of accounts
-- opened each year.
-- ============================================================

WITH accounts_per_branch AS (
    SELECT
        b.branch_name,
        EXTRACT(
            YEAR FROM SAFE.PARSE_DATE(
                '%d-%m-%Y',
                NULLIF(a.opened_date, 'null')
            )
        ) AS year,
        COUNT(a.account_id) AS total_accounts
    FROM `scaler-dsml-sql-498010.citibank.branches` b
    LEFT JOIN `scaler-dsml-sql-498010.citibank.accounts` a
        ON a.branch_id = b.branch_id
    GROUP BY
        b.branch_name,
        year
),

ranking AS (
    SELECT
        branch_name,
        total_accounts,
        year,
        ROW_NUMBER() OVER (
            PARTITION BY year
            ORDER BY total_accounts DESC
        ) AS rn
    FROM accounts_per_branch
)

SELECT
    branch_name,
    total_accounts,
    year,
    rn
FROM ranking
WHERE rn <= 2
  AND year IS NOT NULL
ORDER BY
    year,
    total_accounts DESC;


-- ============================================================
-- III.B
-- Show branch employees, accounts, total transaction amount,
-- and performance rank based on transaction amount.
-- ============================================================

WITH no_of_employees AS (
    SELECT
        b.branch_id,
        b.branch_name,
        COUNT(e.employee_id) AS total_employees
    FROM `scaler-dsml-sql-498010.citibank.branches` b
    JOIN `scaler-dsml-sql-498010.citibank.employees` e
        ON e.branch_id = b.branch_id
    GROUP BY
        b.branch_id,
        b.branch_name
),

total_accounts AS (
    SELECT
        b.branch_id,
        COUNT(a.account_id) AS total_no_of_account
    FROM `scaler-dsml-sql-498010.citibank.branches` b
    JOIN `scaler-dsml-sql-498010.citibank.accounts` a
        ON a.branch_id = b.branch_id
    GROUP BY b.branch_id
),

total_transaction_amount AS (
    SELECT
        b.branch_id,
        SUM(t.amount) AS transaction_amount
    FROM `scaler-dsml-sql-498010.citibank.branches` b
    JOIN `scaler-dsml-sql-498010.citibank.accounts` a
        ON a.branch_id = b.branch_id
    JOIN `scaler-dsml-sql-498010.citibank.transactions` t
        ON a.account_id = t.account_id
    GROUP BY b.branch_id
),

ranking AS (
    SELECT
        ne.branch_name,
        ne.total_employees,
        ta.total_no_of_account,
        tta.transaction_amount,
        RANK() OVER (
            ORDER BY tta.transaction_amount DESC
        ) AS perf_rank
    FROM no_of_employees ne
    JOIN total_accounts ta
        ON ne.branch_id = ta.branch_id
    JOIN total_transaction_amount tta
        ON tta.branch_id = ta.branch_id
)

SELECT *
FROM ranking
ORDER BY perf_rank;


-- ============================================================
-- III.C
-- List yearly transaction amount by branch, cumulative
-- transaction amount over the years, and the average transaction
-- amount per year across all branches.
-- ============================================================

WITH yearly_transactions AS (
    SELECT
        b.branch_name,
        EXTRACT(YEAR FROM t.transaction_date) AS year,
        SUM(t.amount) AS total_transaction_amount
    FROM `scaler-dsml-sql-498010.citibank.branches` b
    JOIN `scaler-dsml-sql-498010.citibank.accounts` a
        ON b.branch_id = a.branch_id
    JOIN `scaler-dsml-sql-498010.citibank.transactions` t
        ON a.account_id = t.account_id
    GROUP BY
        b.branch_name,
        year
)

SELECT
    branch_name,
    year,
    total_transaction_amount,

    ROUND(
        SUM(total_transaction_amount) OVER (
            PARTITION BY branch_name
            ORDER BY year
        ),
        2
    ) AS cumulative_transaction_amount,

    ROUND(
        AVG(total_transaction_amount) OVER (
            PARTITION BY year
        ),
        2
    ) AS avg_transaction_amount_per_year

FROM yearly_transactions

ORDER BY
    branch_name,
    year;


-- ============================================================
-- III.D
-- List branch-level loan issuance, active loans, average interest
-- rate, and percentage of loans paid.
-- ============================================================

SELECT
    b.branch_id,
    b.branch_name,

    SUM(l.loan_amount) AS total_loan_amount_issued,

    COUNTIF(l.status = 'ACTIVE') AS active_loans,

    ROUND(
        AVG(l.interest_rate),
        2
    ) AS avg_interest_rate,

    ROUND(
        100 * SAFE_DIVIDE(
            COUNTIF(l.status = 'PAID'),
            COUNT(*)
        ),
        2
    ) AS percent_loans_paid

FROM `scaler-dsml-sql-498010.citibank.branches` b

JOIN `scaler-dsml-sql-498010.citibank.loans` l
    ON b.branch_id = l.branch_id

GROUP BY
    b.branch_id,
    b.branch_name

ORDER BY
    total_loan_amount_issued DESC;
