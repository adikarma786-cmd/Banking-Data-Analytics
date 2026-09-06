-- ============================================================
-- 04 - FINANCIAL RISK & REVENUE ANALYSIS
-- Banking Data Analytics | Google BigQuery
-- ============================================================

-- Objective:
-- Assess financial performance and risk exposure through loans
-- and transaction trends.


-- ============================================================
-- IV.A
-- List the top three branches with the highest loan default
-- rates for each loan type.
-- ============================================================

WITH total_loans AS (
    SELECT
        l.loan_type,
        b.branch_name,
        COUNT(l.loan_id) AS total_loans
    FROM `scaler-dsml-sql-498010.citibank.branches` b
    JOIN `scaler-dsml-sql-498010.citibank.loans` l
        ON l.branch_id = b.branch_id
    GROUP BY
        l.loan_type,
        b.branch_name
),

default_loans AS (
    SELECT
        l.loan_type,
        b.branch_name,
        COUNT(l.loan_id) AS defaulted_loans
    FROM `scaler-dsml-sql-498010.citibank.branches` b
    JOIN `scaler-dsml-sql-498010.citibank.loans` l
        ON l.branch_id = b.branch_id
    WHERE l.status = 'DEFAULTED'
    GROUP BY
        l.loan_type,
        b.branch_name
),

default_rates AS (
    SELECT
        dl.loan_type,
        dl.branch_name,
        tl.total_loans,
        dl.defaulted_loans,
        ROUND(
            (dl.defaulted_loans / tl.total_loans) * 100,
            2
        ) AS default_rate_percentage
    FROM default_loans dl
    JOIN total_loans tl
        ON tl.branch_name = dl.branch_name
       AND tl.loan_type = dl.loan_type
),

ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY loan_type
            ORDER BY default_rate_percentage DESC
        ) AS rn
    FROM default_rates
)

SELECT
    loan_type,
    branch_name,
    total_loans,
    defaulted_loans,
    default_rate_percentage
FROM ranked
WHERE rn <= 3
ORDER BY
    loan_type,
    default_rate_percentage DESC;


-- ============================================================
-- IV.B
-- Calculate active-loan interest revenue by branch and the
-- percentage contribution to total interest revenue.
-- ============================================================

WITH branch_revenue AS (
    SELECT
        b.branch_name,
        SUM(
            l.loan_amount * l.interest_rate / 100
        ) AS interest_revenue
    FROM `scaler-dsml-sql-498010.citibank.branches` b
    JOIN `scaler-dsml-sql-498010.citibank.loans` l
        ON b.branch_id = l.branch_id
    WHERE l.status = 'ACTIVE'
    GROUP BY b.branch_name
)

SELECT
    branch_name,
    interest_revenue,
    ROUND(
        interest_revenue
        / SUM(interest_revenue) OVER () * 100,
        2
    ) AS contribution_percentage
FROM branch_revenue
ORDER BY interest_revenue DESC;


-- ============================================================
-- IV.C
-- Identify active loans with no payment or more than 180 days
-- since the last payment as of April 30, 2025.
-- ============================================================

WITH last_payment AS (
    SELECT
        loan_id,
        MAX(payment_date) AS last_payment_date
    FROM `scaler-dsml-sql-498010.citibank.loan_payments`
    GROUP BY loan_id
)

SELECT
    l.loan_id,
    CONCAT(
        c.first_name,
        ' ',
        c.last_name
    ) AS customer_name,
    l.loan_amount,

    DATE_DIFF(
        DATE '2025-04-30',
        DATE(lp.last_payment_date),
        DAY
    ) AS days_overdue

FROM `scaler-dsml-sql-498010.citibank.loans` l

JOIN `scaler-dsml-sql-498010.citibank.customers` c
    ON c.customer_id = l.customer_id

LEFT JOIN last_payment lp
    ON lp.loan_id = l.loan_id

WHERE l.status = 'ACTIVE'
  AND (
        lp.last_payment_date IS NULL
        OR DATE_DIFF(
            DATE '2025-04-30',
            DATE(lp.last_payment_date),
            DAY
        ) > 180
      )

ORDER BY days_overdue DESC;


-- ============================================================
-- IV.D
-- Compare January-August transaction amounts year-over-year
-- and calculate the percentage increase/decrease.
-- ============================================================

WITH yearly_transactions AS (
    SELECT
        EXTRACT(YEAR FROM transaction_date) AS year,
        SUM(amount) AS total_transaction_amount
    FROM `scaler-dsml-sql-498010.citibank.transactions`
    WHERE EXTRACT(MONTH FROM transaction_date) BETWEEN 1 AND 8
    GROUP BY year
),

yearly_with_previous AS (
    SELECT
        year,
        total_transaction_amount,
        LAG(total_transaction_amount) OVER (
            ORDER BY year
        ) AS previous_year_amount
    FROM yearly_transactions
)

SELECT
    year,
    total_transaction_amount,
    previous_year_amount,

    ROUND(
        (
            total_transaction_amount
            - previous_year_amount
        )
        / previous_year_amount * 100,
        2
    ) AS percentage_increase

FROM yearly_with_previous

WHERE previous_year_amount IS NOT NULL

ORDER BY year;
