-- Stored procedures for operational reporting

DROP PROCEDURE IF EXISTS sp_daily_transaction_report;
DROP PROCEDURE IF EXISTS sp_top_merchants_by_period;
DROP PROCEDURE IF EXISTS sp_fraud_alert_report;
DELIMITER $$
CREATE PROCEDURE sp_daily_transaction_report(IN report_date DATE)
BEGIN
    SELECT
        DATE(transaction_datetime) AS txn_date,
        COUNT(*) AS total_txns,
        SUM(CASE WHEN status = 'SUCCESS' THEN 1 ELSE 0 END) AS success_txns,
        SUM(CASE WHEN status = 'FAILED' THEN 1 ELSE 0 END) AS failed_txns,
        ROUND(SUM(CASE WHEN status = 'SUCCESS' THEN amount ELSE 0 END), 2) AS revenue,
        ROUND(SUM(cashback_amount), 2) AS cashback
    FROM transactions
    WHERE DATE(transaction_datetime) = report_date
    GROUP BY DATE(transaction_datetime);
END $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE sp_top_merchants_by_period(IN days_back INT)
BEGIN
    SELECT
        m.merchant_name,
        m.category,
        COUNT(*) AS txn_count,
        ROUND(SUM(t.amount), 2) AS gross_volume,
        ROUND(SUM(t.cashback_amount), 2) AS cashback_given
    FROM transactions t
    JOIN merchants m ON t.merchant_id = m.merchant_id
    WHERE t.transaction_datetime >= (
        SELECT DATE_SUB(MAX(transaction_datetime), INTERVAL days_back DAY)
        FROM transactions
    )
    GROUP BY m.merchant_name, m.category
    ORDER BY gross_volume DESC
    LIMIT 10;
END $$
DELIMITER ;
DELIMITER $$
CREATE PROCEDURE sp_fraud_alert_report(IN min_amount DECIMAL(12,2), IN lookback_minutes INT)
BEGIN
    WITH suspicious AS (
        SELECT
            t.transaction_id,
            t.user_id,
            u.full_name,
            t.amount,
            t.transaction_datetime,
            LAG(t.transaction_datetime) OVER (PARTITION BY t.user_id ORDER BY t.transaction_datetime) AS previous_timestamp,
            LAG(t.amount) OVER (PARTITION BY t.user_id ORDER BY t.transaction_datetime) AS previous_amount
        FROM transactions t
        JOIN users u ON t.user_id = u.user_id
        WHERE t.status = 'SUCCESS'
    )
    SELECT
        transaction_id,
        user_id,
        full_name,
        amount,
        previous_amount,
        transaction_datetime,
        previous_timestamp,
        TIMESTAMPDIFF(MINUTE, previous_timestamp, transaction_datetime) AS mins_since_previous
    FROM suspicious
    WHERE amount >= min_amount
      AND previous_amount >= min_amount
      AND TIMESTAMPDIFF(MINUTE, previous_timestamp, transaction_datetime) <= lookback_minutes
    ORDER BY user_id, transaction_datetime;
END $$
DELIMITER ;



