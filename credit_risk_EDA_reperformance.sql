-- ================================================================
-- SECTION 8 — PROCESS REPERFORMANCE: LOAN AMOUNT INTEGRITY
-- Objective: Independently verify loan amount data reliability
--            and identify discrepancies in reported figures.
-- Business Question: Are the loan amount figures trustworthy?
--                   What is the true portfolio exposure
--                   when data integrity issues are resolved?
-- ================================================================

-- Q8.1 — Scale of sentinel value contamination
-- Sentinel value identified: 99,999,999
-- Expected output columns:
--   total_clean_loans, sentinel_records,
--   sentinel_pct, non_sentinel_records
-- Filter: WHERE Loan Status IS NOT NULL


SELECT COUNT(*) AS total_clean_loans, (SELECT SUM(CASE
        WHEN `Current Loan Amount` = 99999999 THEN 1
        ELSE 0
        END)  FROM loan_data) AS sentinel_records,
        ROUND(SUM(CASE
                WHEN `Current Loan Amount` = 99999999 THEN 1
                ELSE 0
            END) * 100.0 / COUNT(*),
            2) AS sentinel_pct,
        ROUND(SUM(CASE
                WHEN `Current Loan Amount` <> 99999999 THEN 1
                ELSE 0
            END) * 100.0 / COUNT(*),
            2) AS non_sentinel_pct    
FROM loan_data
WHERE `Loan Status` IS NOT NULL
;


-- Q8.2 — Compare reported portfolio metrics vs reperformed metrics
-- Reported figures from Section 1 used ALL records including sentinel values
-- Reperformed figures exclude sentinel values (Current Loan Amount <> 99999999)
-- Expected output columns:
--   metric, reported_figure, reperformed_figure, variance
-- Build this as a UNION query — one row per metric
-- Metrics to compare:
--   Total loan amount
--   Average loan amount  
--   Amount at risk (Charged Off loans only)
--   Average loan amount for Charged Off loans
-- Filter base: WHERE Loan Status IS NOT NULL

WITH reported as (SELECT SUM(`Current Loan Amount`) as total_loan_amount,
	   ROUND(AVG(`Current Loan Amount`),2) as avg_loan_amount,
       SUM(CASE
        WHEN `Loan Status` = 'Charged Off' THEN `Current Loan Amount`
        ELSE 0
		END) AS amount_at_risk,
        ROUND(AVG(CASE 
        WHEN `Loan Status` = 'Charged Off' THEN `Current Loan Amount` 
        ELSE NULL 
    END) ,2)AS avg_charged_off_loans
FROM loan_data
WHERE `Loan Status` IS NOT NULL),

reperformed as (SELECT SUM(`Current Loan Amount`) as total_loan_amount,
	   ROUND(AVG(`Current Loan Amount`),2) as avg_loan_amount,
       SUM(CASE
        WHEN `Loan Status` = 'Charged Off' THEN `Current Loan Amount`
        ELSE 0
		END) AS amount_at_risk,
        ROUND(AVG(CASE 
        WHEN `Loan Status` = 'Charged Off' THEN `Current Loan Amount` 
        ELSE NULL 
    END) ,2) AS avg_charged_off_loans
FROM loan_data
WHERE `Loan Status` IS NOT NULL AND `Current Loan Amount` <> 99999999)

SELECT 'Total Loan Amount' AS metric, r.total_loan_amount AS reported, p.total_loan_amount AS reperformed, (r.total_loan_amount - p.total_loan_amount) AS variance FROM Reported r, Reperformed p
UNION ALL
SELECT 'Average Loan Amount', r.avg_loan_amount, p.avg_loan_amount, (r.avg_loan_amount - p.avg_loan_amount) FROM Reported r, Reperformed p
UNION ALL
SELECT 'Amount at Risk', r.amount_at_risk, p.amount_at_risk, (r.amount_at_risk - p.amount_at_risk) FROM Reported r, Reperformed p
UNION ALL
SELECT 'Avg Charged Off Loan', r.avg_charged_off_loans, p.avg_charged_off_loans, (r.avg_charged_off_loans - p.avg_charged_off_loans) FROM Reported r, Reperformed p;

-- KEY REPERFORMANCE FINDING:
-- Sentinel values (99,999,999) are concentrated exclusively
-- in Fully Paid loans. Zero sentinel values in Charged Off loans.
-- This means:
--   Amount at risk figures — FULLY RELIABLE
--   Default rate percentages — FULLY RELIABLE
--   Total portfolio amount — OVERSTATED by $1.148 trillion
--   Average loan amount — Reported $11.76M vs True $312,313
-- Likely cause: Legacy system overwrites loan amount field
-- with maximum sentinel value upon loan closure/payoff.

-- Q8.3 — Confirm sentinel value distribution by loan status
-- Verify that sentinel values exist only in Fully Paid loans
-- Expected output columns:
--   loan_status, sentinel_count, total_loans, sentinel_pct
-- This confirms the reperformance finding definitively
-- Filter: WHERE Loan Status IS NOT NULL

SELECT 
    `Loan Status`,
    SUM(CASE
        WHEN `Current Loan Amount` = 99999999 THEN 1
        ELSE 0
    END) AS sentinel_count,
    ROUND(SUM(CASE
                WHEN `Current Loan Amount` = 99999999 THEN 1
                ELSE 0
            END) * 100.0 / COUNT(*),
            2) AS sentinel_pct
FROM
    loan_data
WHERE
    `Loan Status` IS NOT NULL
GROUP BY `Loan Status`
;
