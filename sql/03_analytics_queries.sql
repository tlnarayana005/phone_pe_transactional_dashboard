-- Analytics queries for dashboard reporting

-- 1. Overall KPI summary
SELECT
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN status = 'SUCCESS' THEN 1 ELSE 0 END) AS successful_transactions,
    SUM(CASE WHEN status = 'FAILED' THEN 1 ELSE 0 END) AS failed_transactions,
    ROUND(SUM(CASE WHEN status = 'SUCCESS' THEN amount ELSE 0 END), 2) AS total_revenue,
    ROUND(SUM(cashback_amount), 2) AS total_cashback,
    ROUND(AVG(amount), 2) AS avg_transaction_amount
FROM transactions;

-- 2. Daily trend by calendar date
WITH daily AS (
    SELECT DATE(transaction_datetime) AS txn_date,
           COUNT(*) AS total_txn,
           SUM(CASE WHEN status = 'SUCCESS' THEN 1 ELSE 0 END) AS success_txn,
           SUM(CASE WHEN status = 'FAILED' THEN 1 ELSE 0 END) AS failed_txn,
           ROUND(SUM(CASE WHEN status = 'SUCCESS' THEN amount ELSE 0 END), 2) AS revenue
    FROM transactions
    GROUP BY DATE(transaction_datetime)
)
SELECT *
FROM daily
ORDER BY txn_date;

-- 3. Weekly and monthly breakdown using window functions
WITH monthly AS (
    SELECT
        DATE_FORMAT(transaction_datetime, '%Y-%m') AS month_id,
        SUM(amount) AS monthly_volume,
        SUM(CASE WHEN status = 'SUCCESS' THEN amount ELSE 0 END) AS monthly_success_volume,
        ROW_NUMBER() OVER (ORDER BY DATE_FORMAT(transaction_datetime, '%Y-%m')) AS rn
    FROM transactions
    GROUP BY DATE_FORMAT(transaction_datetime, '%Y-%m')
)
SELECT *
FROM monthly;

-- 4. Success vs failed payment analysis by payment method
SELECT
    payment_method,
    COUNT(*) AS total_attempts,
    SUM(CASE WHEN status = 'SUCCESS' THEN 1 ELSE 0 END) AS successful,
    SUM(CASE WHEN status = 'FAILED' THEN 1 ELSE 0 END) AS failed,
    ROUND(100.0 * SUM(CASE WHEN status = 'SUCCESS' THEN 1 ELSE 0 END) / COUNT(*), 2) AS success_rate_pct
FROM transactions
GROUP BY payment_method
ORDER BY success_rate_pct DESC;

-- 5. Top merchants by transaction volume
SELECT
    m.merchant_name,
    m.category,
    COUNT(t.transaction_id) AS transaction_count,
    ROUND(SUM(t.amount), 2) AS gross_volume,
    ROUND(SUM(t.cashback_amount), 2) AS cashback_given
FROM transactions t
JOIN merchants m ON t.merchant_id = m.merchant_id
GROUP BY m.merchant_name, m.category
ORDER BY gross_volume DESC;

-- 6. UPI usage trend by month
SELECT
    DATE_FORMAT(transaction_datetime, '%Y-%m') AS txn_month,
    COUNT(*) AS total_upi_txn,
    ROUND(SUM(amount), 2) AS upi_volume
FROM transactions
WHERE payment_method = 'UPI'
GROUP BY DATE_FORMAT(transaction_datetime, '%Y-%m')
ORDER BY txn_month;

-- 7. Revenue and cashback analysis
SELECT
    transaction_type,
    COUNT(*) AS txn_count,
    ROUND(SUM(amount), 2) AS amount,
    ROUND(SUM(cashback_amount), 2) AS cashback_total,
    ROUND(AVG(cashback_amount), 2) AS avg_cashback
FROM transactions
GROUP BY transaction_type
ORDER BY amount DESC;

-- 8. Fraud detection: repeated high-value transactions by the same user in a short interval
WITH txn_window AS (
    SELECT
        t.user_id,
        t.transaction_datetime,
        t.amount,
        LAG(t.transaction_datetime) OVER (PARTITION BY t.user_id ORDER BY t.transaction_datetime) AS previous_timestamp,
        LAG(t.amount) OVER (PARTITION BY t.user_id ORDER BY t.transaction_datetime) AS previous_amount
    FROM transactions t
    WHERE t.status = 'SUCCESS'
)
SELECT
    user_id,
    transaction_datetime,
    amount,
    previous_timestamp,
    previous_amount,
    TIMESTAMPDIFF(MINUTE, previous_timestamp, transaction_datetime) AS mins_since_previous
FROM txn_window
WHERE previous_timestamp IS NOT NULL
  AND amount >= 1000
  AND previous_amount >= 1000
  AND TIMESTAMPDIFF(MINUTE, previous_timestamp, transaction_datetime) <= 30
ORDER BY user_id, transaction_datetime;

-- 9. Merchant category contribution to success volume
SELECT
    m.category,
    COUNT(*) AS txn_count,
    ROUND(SUM(CASE WHEN t.status = 'SUCCESS' THEN t.amount ELSE 0 END), 2) AS success_volume,
    ROUND(100.0 * SUM(CASE WHEN t.status = 'SUCCESS' THEN t.amount ELSE 0 END) / NULLIF(SUM(t.amount), 0), 2) AS success_share_pct
FROM transactions t
JOIN merchants m ON t.merchant_id = m.merchant_id
GROUP BY m.category
ORDER BY success_volume DESC;

