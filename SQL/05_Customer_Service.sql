-- ============================================================
-- 05 - CUSTOMER SERVICE & INTERACTION ANALYSIS
-- Banking Data Analytics | Google BigQuery
-- ============================================================

-- Objective:
-- Optimize customer service processes and improve satisfaction.


-- ============================================================
-- V.A
-- List each branch's name, total interactions, complaints,
-- complaint rate, number of employees and employee positions.
-- ============================================================

WITH customer_interactions AS (

    SELECT
        b.branch_id,
        b.branch_name,

        COUNT(ci.interaction_id) AS total_interactions,

        SUM(
            CASE
                WHEN ci.interaction_type = 'COMPLAINT' THEN 1
                ELSE 0
            END
        ) AS complaints

    FROM `scaler-dsml-sql-498010.citibank.branches` b

    JOIN `scaler-dsml-sql-498010.citibank.employees` e
        ON e.branch_id = b.branch_id

    JOIN `scaler-dsml-sql-498010.citibank.customer_interactions` ci
        ON ci.employee_id = e.employee_id

    GROUP BY
        b.branch_id,
        b.branch_name
),

no_of_employees AS (

    SELECT
        b.branch_id,
        b.branch_name,

        COUNT(e.employee_id) AS total_employees,

        STRING_AGG(
            DISTINCT position,
            ','
        ) AS positions

    FROM `scaler-dsml-sql-498010.citibank.branches` b

    JOIN `scaler-dsml-sql-498010.citibank.employees` e
        ON e.branch_id = b.branch_id

    GROUP BY
        b.branch_id,
        b.branch_name
)

SELECT
    ci.branch_name,
    ci.total_interactions,
    ci.complaints,

    ROUND(
        ci.complaints / ci.total_interactions * 100,
        2
    ) AS complaint_rate_percentage,

    ne.total_employees,
    ne.positions

FROM customer_interactions ci

JOIN no_of_employees ne
    ON ne.branch_id = ci.branch_id

ORDER BY
    complaint_rate_percentage DESC;


-- ============================================================
-- V.B
-- List customers who made complaints in at least three
-- different months.
-- ============================================================

WITH complaint_monthss AS (

    SELECT
        c.customer_id,

        CONCAT(
            c.first_name,
            ' ',
            c.last_name
        ) AS customer_name,

        COUNT(
            DISTINCT FORMAT_DATE(
                '%Y-%m',
                DATE(ci.interaction_date)
            )
        ) AS complaint_months,

        COUNT(ci.interaction_id) AS total_complaints,

        STRING_AGG(
            DISTINCT FORMAT_DATE(
                '%Y-%m',
                DATE(ci.interaction_date)
            ),
            ', '
            ORDER BY FORMAT_DATE(
                '%Y-%m',
                DATE(ci.interaction_date)
            )
        ) AS months_complained

    FROM `scaler-dsml-sql-498010.citibank.customers` c

    JOIN `scaler-dsml-sql-498010.citibank.customer_interactions` ci
        ON ci.customer_id = c.customer_id

    WHERE ci.interaction_type = 'COMPLAINT'

    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name

    HAVING COUNT(
        DISTINCT FORMAT_DATE(
            '%Y-%m',
            DATE(ci.interaction_date)
        )
    ) >= 3
)

SELECT
    customer_id,
    customer_name,
    complaint_months,
    total_complaints,
    months_complained

FROM complaint_monthss

ORDER BY
    complaint_months DESC,
    total_complaints DESC;
