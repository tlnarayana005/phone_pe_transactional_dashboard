-- Reusable reporting views

DROP VIEW IF EXISTS v_fraud_alert_detail;
DROP VIEW IF EXISTS v_failure_analysis;
DROP VIEW IF EXISTS v_upi_usage_trend;
DROP VIEW IF EXISTS v_merchant_performance;
DROP VIEW IF EXISTS v_monthly_transaction_summary;
DROP VIEW IF EXISTS v_daily_transaction_summary;
CREATE VIEW v_daily_transaction_summary AS
SELECT
    DATE(transaction_datetime) AS txn_date,
    COUNT(*) AS total_txns,
    SUM(CASE WHEN status = 'SUCCESS' THEN 1 ELSE 0 END) AS success_txns,
    SUM(CASE WHEN status = 'FAILED' THEN 1 ELSE 0 END) AS failed_txns,
    ROUND(SUM(CASE WHEN status = 'SUCCESS' THEN amount ELSE 0 END), 2) AS revenue,
    ROUND(SUM(cashback_amount), 2) AS cashback
FROM transactions
GROUP BY DATE(transaction_datetime);

CREATE VIEW v_merchant_performance AS
SELECT
    m.merchant_name,
    m.category,
    COUNT(*) AS txn_count,
    ROUND(SUM(t.amount), 2) AS gross_volume,
    ROUND(SUM(CASE WHEN t.status = 'SUCCESS' THEN t.amount ELSE 0 END), 2) AS success_volume,
    ROUND(SUM(t.cashback_amount), 2) AS cashback_given
FROM transactions t
JOIN merchants m ON t.merchant_id = m.merchant_id
GROUP BY m.merchant_name, m.category;

CREATE VIEW v_upi_usage_trend AS
SELECT
    DATE_FORMAT(transaction_datetime, '%Y-%m') AS txn_month,
    COUNT(*) AS upi_txn_count,
    ROUND(SUM(amount), 2) AS upi_volume,
    ROUND(SUM(cashback_amount), 2) AS upi_cashback
FROM transactions
WHERE payment_method = 'UPI'
GROUP BY DATE_FORMAT(transaction_datetime, '%Y-%m');

CREATE VIEW v_failure_analysis AS
SELECT
    t.user_id,
    u.city,
    m.merchant_name,
    t.amount,
    t.payment_method,
    t.channel,
    t.transaction_datetime
FROM transactions t
JOIN users u ON t.user_id = u.user_id
JOIN merchants m ON t.merchant_id = m.merchant_id
WHERE t.status = 'FAILED';
CREATE VIEW v_monthly_transaction_summary AS
SELECT
    DATE_FORMAT(transaction_datetime, '%Y-%m') AS txn_month,
    COUNT(*) AS total_txns,
    SUM(CASE WHEN status = 'SUCCESS' THEN 1 ELSE 0 END) AS success_txns,
    SUM(CASE WHEN status = 'FAILED' THEN 1 ELSE 0 END) AS failed_txns,
    ROUND(SUM(CASE WHEN status = 'SUCCESS' THEN amount ELSE 0 END), 2) AS revenue,
    ROUND(SUM(cashback_amount), 2) AS cashback,
    ROUND(100.0 * SUM(CASE WHEN status = 'SUCCESS' THEN 1 ELSE 0 END) / COUNT(*), 2) AS success_rate_pct
FROM transactions
GROUP BY DATE_FORMAT(transaction_datetime, '%Y-%m');

CREATE VIEW v_fraud_alert_detail AS
SELECT
    fa.alert_id,
    fa.alert_type,
    fa.severity,
    fa.alert_message,
    fa.created_at AS alert_created_at,
    t.transaction_id,
    t.amount,
    t.payment_method,
    t.channel,
    t.transaction_datetime,
    u.full_name,
    u.phone,
    u.city AS user_city,
    m.merchant_name,
    m.category AS merchant_category
FROM fraud_alerts fa
JOIN transactions t ON fa.transaction_id = t.transaction_id
JOIN users u ON fa.user_id = u.user_id
JOIN merchants m ON t.merchant_id = m.merchant_id;


