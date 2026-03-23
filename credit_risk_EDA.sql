-- ================================================================
-- CREDIT RISK ANALYSIS — END TO END DATA ANALYSIS
-- Analyst: Kathiresan Senthilkumar
-- Dataset: loan_data — 100,514 rows, 19 columns
-- Database: credit_risk
-- Business Question: What borrower characteristics predict default?
-- What does a high risk borrower profile look like?
-- ================================================================

USE credit_risk;

-- ================================================================
-- SECTION 0 — DATA QUALITY & OVERVIEW
-- Objective: Understand data completeness and validity
--            before running any business analysis.
-- ================================================================

-- Q0.1 — Verify null rows and confirm clean record count
SELECT 
    COUNT(*) AS total_rows,
    COUNT(`Loan Status`) AS valid_rows,
    COUNT(*) - COUNT(`Loan Status`) AS null_rows
FROM loan_data;

-- Q0.2 — Check distinct Loan Status values
SELECT 
    `Loan Status`,
    COUNT(*) AS count
FROM loan_data
GROUP BY `Loan Status`;

-- Q0.3 — Check Credit Score range for outliers
SELECT 
    MIN(`Credit Score`) AS min_score,
    MAX(`Credit Score`) AS max_score,
    ROUND(AVG(`Credit Score`), 0) AS avg_score,
    COUNT(*) - COUNT(`Credit Score`) AS null_scores
FROM loan_data
WHERE `Loan Status` IS NOT NULL;

-- Q0.4 — Check Credit Score outliers above valid range
-- Valid credit score range: 300 to 850
-- Expected: count of records with Credit Score above 850

SELECT 
    COUNT(`Credit Score`) AS impossible_values
FROM
    credit_risk.loan_data
WHERE
    `Credit Score` > 850;

-- ================================================================
-- DATA QUALITY SUMMARY
-- Total rows: 100,514
-- Clean rows (Loan Status not null): 100,000
-- Null rows removed: 514
--
-- Credit Score issues:
--   Null Credit Scores: 19,154
--   Impossible values (above 850): 4,551
--   Total unusable for Credit Score analysis: 23,705 (24%)
--
-- Decision: All analyses filter WHERE `Loan Status` IS NOT NULL
--           Credit Score analyses add filter WHERE `Credit Score`
--           BETWEEN 300 AND 850
-- ================================================================

-- ================================================================
-- SECTION 1 — PORTFOLIO HEALTH OVERVIEW
-- Objective: Understand the overall loan portfolio before
--            drilling into default patterns.
-- Business Question: What is the overall default rate and
--                   what is the total value at risk?
-- ================================================================

-- Q1.1 — Overall portfolio summary
-- Expected output columns:
--   total_loans, fully_paid, charged_off,
--   default_rate_pct, total_loan_amount, amount_at_risk
-- Filter: WHERE Loan Status IS NOT NULL
-- Hint: Use CASE WHEN inside SUM to count specific statuses
--       Use ROUND for percentages and amounts

SELECT 
    COUNT(*) AS total_loans,
    COUNT(CASE
        WHEN `Loan Status` = 'Fully Paid' THEN 1
    END) AS fully_paid,
    COUNT(CASE
        WHEN `Loan Status` = 'Charged Off' THEN 1
    END) AS charged_off,
    ROUND(SUM(CASE
                WHEN `Loan Status` = 'Charged Off' THEN 1
                ELSE 0
            END) * 100.0 / COUNT(*),
            2) AS default_rate_pct,
    SUM(`Current Loan Amount`) AS total_loan_amount,
    SUM(CASE
        WHEN `Loan Status` = 'Charged Off' THEN `Current Loan Amount`
        ELSE 0
    END) AS amount_at_risk
FROM
    loan_data
WHERE
    `Loan Status` IS NOT NULL;
    
-- ================================================================
-- SECTION 2 — DEFAULT RATE BY LOAN PURPOSE
-- Objective: Identify which loan purposes carry the highest
--            default risk.
-- Business Question: Are certain loan purposes significantly
--                   more likely to result in default?
-- Filter: WHERE Loan Status IS NOT NULL
-- ================================================================

-- Q2.1 — Default rate by loan purpose
-- Expected output columns:
--   purpose, total_loans, charged_off,
--   default_rate_pct, total_amount, amount_at_risk
-- Sort: default_rate_pct descending
-- Note: Purpose column is called 'Purpose' in this dataset

SELECT 
    purpose,
    COUNT(CASE
        WHEN `Loan Status` = 'Charged Off' THEN 1
    END) AS charged_off,
    COUNT(*) AS total_loans,
    ROUND(SUM(CASE
                WHEN `Loan Status` = 'Charged Off' THEN 1
                ELSE 0
            END) * 100.0 / COUNT(*),
            2) AS default_rate_pct,
    SUM(`Current Loan Amount`) AS total_loan_amount,
    SUM(CASE
        WHEN `Loan Status` = 'Charged Off' THEN `Current Loan Amount`
        ELSE 0
    END) AS amount_at_risk
FROM
    loan_data
WHERE
    `Loan Status` IS NOT NULL
GROUP BY purpose
ORDER BY default_rate_pct DESC;

-- ================================================================
-- SECTION 3 — DEFAULT RATE BY LOAN TERM
-- Objective: Does loan term length affect default risk?
-- Business Question: Are long term loans significantly more
--                   likely to default than short term loans?
-- Filter: WHERE Loan Status IS NOT NULL
-- ================================================================

-- Q3.1 — Default rate by term
-- Expected output columns:
--   term, total_loans, charged_off,
--   default_rate_pct, amount_at_risk
-- Sort: default_rate_pct descending

SELECT 
    Term,
    COUNT(CASE
        WHEN `Loan Status` = 'Charged Off' THEN 1
    END) AS charged_off,
    COUNT(*) AS total_loans,
    ROUND(SUM(CASE
                WHEN `Loan Status` = 'Charged Off' THEN 1
                ELSE 0
            END) * 100.0 / COUNT(*),
            2) AS default_rate_pct,
    SUM(`Current Loan Amount`) AS total_loan_amount,
    SUM(CASE
        WHEN `Loan Status` = 'Charged Off' THEN `Current Loan Amount`
        ELSE 0
    END) AS amount_at_risk
FROM
    loan_data
WHERE
    `Loan Status` IS NOT NULL
GROUP BY Term
ORDER BY default_rate_pct DESC;

-- ================================================================
-- SECTION 4 — DEFAULT RATE BY HOME OWNERSHIP
-- Objective: Does home ownership status affect default risk?
-- Business Question: Are renters more likely to default
--                   than homeowners or mortgage holders?
-- Filter: WHERE Loan Status IS NOT NULL
-- ================================================================

-- Q4.1 — Default rate by home ownership
-- Expected output columns:
--   home_ownership, total_loans, charged_off,
--   default_rate_pct, amount_at_risk
-- Sort: default_rate_pct descending

SELECT 
    `Home Ownership` as home_ownership,
    COUNT(CASE
        WHEN `Loan Status` = 'Charged Off' THEN 1
    END) AS charged_off,
    COUNT(*) AS total_loans,
    ROUND(SUM(CASE
                WHEN `Loan Status` = 'Charged Off' THEN 1
                ELSE 0
            END) * 100.0 / COUNT(*),
            2) AS default_rate_pct,
    SUM(`Current Loan Amount`) AS total_loan_amount,
    SUM(CASE
        WHEN `Loan Status` = 'Charged Off' THEN `Current Loan Amount`
        ELSE 0
    END) AS amount_at_risk
FROM
    loan_data
WHERE
    `Loan Status` IS NOT NULL
GROUP BY `Home Ownership`
ORDER BY default_rate_pct DESC;

-- ================================================================
-- SECTION 5 — DEFAULT RATE BY CREDIT PROBLEMS
-- Objective: Does credit history affect default rate?
-- Business Question: Do borrowers with prior credit problems
--                   default significantly more?
-- Filter: WHERE Loan Status IS NOT NULL
-- Note: This column has no major null issues
-- ================================================================

-- Q5.1 — Default rate by number of credit problems
-- Expected output columns:
--   credit_problems, total_loans, charged_off,
--   default_rate_pct, amount_at_risk
-- Sort: credit_problems ascending

SELECT 
    `Number of Credit Problems` as credit_problems,
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
    END) AS amount_at_risk
FROM
    loan_data
WHERE
    `Loan Status` IS NOT NULL
GROUP BY `Number of Credit Problems`
ORDER BY `Number of Credit Problems` ASC;

-- NOTE: Credit problem counts above 5 have sample sizes
-- too small for reliable analysis (n < 20).
-- Focus insights on 0-5 range which covers 99.9% of loans.

-- ================================================================
-- SECTION 6 — DEFAULT RATE BY INCOME BAND
-- Objective: Does annual income level affect default risk?
-- Business Question: Do lower income borrowers default more?
-- Filter: WHERE Loan Status IS NOT NULL
--         AND Annual Income IS NOT NULL
-- ================================================================


-- Q6.0 — Investigate Annual Income distribution
-- Check min, max, average income
-- and count how many records exceed realistic thresholds

SELECT 
    MIN(`Annual Income`) AS min,
    MAX(`Annual Income`) AS max,
    ROUND(AVG(`Annual Income`), 0) AS avg, 
    COUNT(case when `Annual Income` > 500000 THEN 1 END) AS above_500k
FROM
    loan_data;
    
-- DATA NOTE: Annual Income contains extreme outliers.
-- Max value $165M, average $1.37M — clearly erroneous.
-- Likely cause: missing decimal points in source data entry.
-- Decision: Filter Annual Income to realistic range
-- for Indian/global retail lending context.
-- Using threshold of <= 500,000 as reasonable upper bound
-- for personal loan borrowers.

-- Q6.0b — Check income distribution in detail
-- Count loans in each realistic income range
-- to understand where the data actually sits

SELECT 
    SUM(CASE WHEN `Annual Income` < 50000 THEN 1 ELSE 0 END) AS below_50k,
    SUM(CASE WHEN `Annual Income` >= 50000 AND `Annual Income` < 100000 THEN 1 ELSE 0 END) AS '50k_to_100k',
    SUM(CASE WHEN `Annual Income` >= 100000 AND `Annual Income` < 200000 THEN 1 ELSE 0 END) AS '100k_to_200k',
    SUM(CASE WHEN `Annual Income` >= 200000 AND `Annual Income` < 300000 THEN 1 ELSE 0 END) AS '200k_to_300k',
    MIN(`Annual Income`) AS min_income
FROM loan_data
WHERE `Annual Income` < 500000;

       

-- Q6.1 — Default rate by income band
-- Use CASE WHEN to create income bands:
--   'Under 50K'   = Annual Income < 50000
--   '50K-100K'    = Annual Income >= 50000 AND < 100000
--   '100K-200K'   = Annual Income >= 100000 AND < 200000
--   '200K-500K'   = Annual Income >= 200000 AND < 500000
--   'Above 500K'  = Annual Income >= 500000
-- Expected output columns:
--   income_band, total_loans, charged_off,
--   default_rate_pct, amount_at_risk
-- Sort: default_rate_pct descending

SELECT 
    CASE
        WHEN `Annual Income` < 50000 THEN 'Under 50K'
        WHEN
            `Annual Income` >= 50000
                AND `Annual Income` < 100000
        THEN
            '50K-100K'
        WHEN
            `Annual Income` >= 100000
                AND `Annual Income` < 200000
        THEN
            '100K-200K'
        WHEN
            `Annual Income` >= 200000
                AND `Annual Income` < 500000
        THEN
            '200K-500K'
        WHEN `Annual Income` >= 500000 THEN 'Above 500K'
    END AS income_band,
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
    END) AS amount_at_risk
FROM
    loan_data
WHERE
    `Loan Status` IS NOT NULL
        AND `Annual Income` IS NOT NULL
        AND `Annual Income` <= 500000
GROUP BY income_band
ORDER BY default_rate_pct DESC;

-- Q6 — ABANDONED: Annual Income data quality insufficient
-- Issues found:
--   Minimum income: $76,627 — suspiciously high floor
--   Maximum income: $165,557,393 — clearly erroneous
--   Average income: $1,378,277 — distorted by outliers
--   Only 3,629 records fall within realistic bands
--   Remaining 96,371 records have unreliable income values
-- Decision: Income band analysis skipped.
--           Annual Income not suitable for reliable segmentation
--           in this dataset without significant data cleaning.

-- ================================================================
-- SECTION 7 — HIGH RISK BORROWER PROFILE
-- Objective: Combine all findings to identify the characteristics
--            of the highest risk borrower.
-- Business Question: What does a high risk borrower look like
--                   and what is their combined default rate?
-- ================================================================

-- Q7.1 — High risk profile identification
-- Based on findings so far the high risk profile is:
--   Term = Long Term
--   Purpose IN ('small_business', 'Business Loan')
--   Home Ownership = 'Rent'
--   Number of Credit Problems >= 1
-- Expected output columns:
--   risk_profile (label these as 'HIGH RISK'),
--   total_loans, charged_off,
--   default_rate_pct, amount_at_risk
-- Compare against overall portfolio default rate of 22.64%
-- Filter: WHERE Loan Status IS NOT NULL

SELECT
	'HIGH RISK' AS risk_profile,
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
    END) AS amount_at_risk
FROM
    loan_data
WHERE
    `Loan Status` IS NOT NULL
        AND Term = 'Long Term'
        AND Purpose IN ('small_business' , 'Business Loan')
        AND `Home Ownership` = 'Rent'
        AND `Number of Credit Problems` >= 1;



