-- SECTION 5.2 — DEFAULT RATE BY CREDIT SCORE RANGES
-- Objective: Does Credit Score correlate with default risk?
-- Business Question: What is the optimal Credit Score threshold
--                    for loan approval decisions?
-- Filter: WHERE Loan Status IS NOT NULL
--         AND Credit Score BETWEEN 300 AND 850

-- ================================================================

-- Q5.2.1 — Credit Score range check for valid records
-- Verify min, max, average Credit Score after filtering
-- Expected output columns:
--   valid_records, min_score, max_score, avg_score
-- Note: This confirms data quality after removing nulls and outliers
-- Filter: WHERE Loan Status IS NOT NULL
--         AND Credit Score BETWEEN 300 AND 850

SELECT 
    COUNT(*) AS valid_records,
    MIN(`Credit Score`) AS min_score,
    MAX(`Credit Score`) AS max_score
FROM
    loan_data
WHERE
    `Loan Status` IS NOT NULL
        AND `Credit Score` BETWEEN 300 AND 850;

-- Q5.2.2 — Default rate by Credit Score bands
-- Use CASE WHEN to create Credit Score bands based on FICO ranges:
--   'Poor (300-579)'       = Credit Score >= 300 AND < 580
--   'Fair (580-669)'       = Credit Score >= 580 AND < 670
--   'Good (670-739)'       = Credit Score >= 670 AND < 740
--   'Very Good (740-799)'  = Credit Score >= 740 AND < 800
--   'Excellent (800-850)'  = Credit Score >= 800 AND <= 850
-- Expected output columns:
--   credit_score_band, total_loans, charged_off,
--   default_rate_pct, amount_at_risk, avg_loan_amount
-- Sort: ORDER BY default_rate_pct DESC
-- Note: These bands follow standard FICO score ranges
-- Filter: WHERE Loan Status IS NOT NULL
--         AND Credit Score BETWEEN 300 AND 850

SELECT
    CASE
        WHEN `Credit Score` >= 300 AND `Credit Score` < 580 THEN 'Poor (300-579)'
        WHEN `Credit Score` >= 580 AND `Credit Score` < 670 THEN 'Fair (580-669)'
        WHEN `Credit Score` >= 670 AND `Credit Score` < 740 THEN 'Good (670-739)'
        WHEN `Credit Score` >= 740 AND `Credit Score` < 800 THEN 'Very Good (740-799)'
        WHEN `Credit Score` >= 800 AND `Credit Score` <= 850 THEN 'Excellent (800-850)'
    END AS credit_score_band,
    COUNT(*) AS total_loans,
    COUNT(CASE
        WHEN `Loan Status` = 'Charged Off' THEN 1
    END) AS charged_off,
    ROUND(SUM(CASE
                WHEN `Loan Status` = 'Charged Off' THEN 1
                ELSE 0
            END) * 100.0 / COUNT(*),
            2) AS default_rate_pct,
    SUM(CASE
        WHEN `Loan Status` = 'Charged Off' THEN `Current Loan Amount`
        ELSE 0
    END) AS amount_at_risk,
    ROUND(AVG(`Current Loan Amount`), 0) AS avg_loan_amount
FROM
    loan_data
WHERE
    `Loan Status` IS NOT NULL
    AND `Credit Score` BETWEEN 300 AND 850
GROUP BY credit_score_band
ORDER BY default_rate_pct DESC;

-- Q5.2.3 — Credit Score distribution by Loan Status
-- Compare average Credit Score between Fully Paid vs Charged Off
-- Expected output columns:
--   loan_status, total_loans, avg_credit_score,
--   min_credit_score, max_credit_score
-- Sort: avg_credit_score descending
-- Note: This shows if defaulters have systematically lower scores

SELECT
    `Loan Status` AS loan_status,
    COUNT(*) AS total_loans,
    ROUND(AVG(`Credit Score`), 0) AS avg_credit_score,
    MIN(`Credit Score`) AS min_credit_score,
    MAX(`Credit Score`) AS max_credit_score
FROM
    loan_data
WHERE
    `Loan Status` IS NOT NULL
    AND `Credit Score` BETWEEN 300 AND 850
GROUP BY `Loan Status`
ORDER BY avg_credit_score DESC;