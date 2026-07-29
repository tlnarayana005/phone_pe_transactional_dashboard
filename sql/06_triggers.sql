-- MySQL trigger patterns for transaction auditing and fraud alerts

DROP TRIGGER IF EXISTS trg_transactions_after_insert_audit;
DROP TRIGGER IF EXISTS trg_transactions_after_update_audit;

DELIMITER $$

CREATE TRIGGER trg_transactions_after_insert_audit
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    INSERT INTO transaction_audit (
        transaction_id,
        user_id,
        amount,
        status,
        audit_note,
        created_at
    ) VALUES (
        NEW.transaction_id,
        NEW.user_id,
        NEW.amount,
        NEW.status,
        'Transaction inserted',
        CURRENT_TIMESTAMP
    );

    IF NEW.status = 'SUCCESS' AND NEW.amount >= 1000 AND (
        SELECT COUNT(*)
        FROM transactions t
        WHERE t.user_id = NEW.user_id
          AND t.status = 'SUCCESS'
          AND t.amount >= 1000
          AND t.transaction_datetime BETWEEN DATE_SUB(NEW.transaction_datetime, INTERVAL 30 MINUTE)
                                      AND NEW.transaction_datetime
    ) >= 2 THEN
        INSERT INTO fraud_alerts (
            transaction_id,
            user_id,
            alert_type,
            alert_message,
            severity,
            created_at
        ) VALUES (
            NEW.transaction_id,
            NEW.user_id,
            'HIGH_VALUE_BURST',
            'Multiple successful high-value transactions occurred within 30 minutes.',
            'HIGH',
            CURRENT_TIMESTAMP
        );
    END IF;
END $$

CREATE TRIGGER trg_transactions_after_update_audit
AFTER UPDATE ON transactions
FOR EACH ROW
BEGIN
    IF OLD.status <> NEW.status THEN
        INSERT INTO transaction_audit (
            transaction_id,
            user_id,
            amount,
            status,
            audit_note,
            created_at
        ) VALUES (
            NEW.transaction_id,
            NEW.user_id,
            NEW.amount,
            NEW.status,
            CONCAT('Status changed from ', OLD.status, ' to ', NEW.status),
            CURRENT_TIMESTAMP
        );
    END IF;
END $$

DELIMITER ;

-- Example manual backfill for historical suspicious transactions loaded before triggers:
INSERT INTO fraud_alerts (transaction_id, user_id, alert_type, alert_message, severity)
SELECT
    transaction_id,
    user_id,
    'HIGH_VALUE_BURST',
    'Historical high-value transaction burst found in seed or imported data.',
    'HIGH'
FROM (
    SELECT
        t.transaction_id,
        t.user_id,
        t.transaction_datetime,
        t.amount,
        LAG(t.transaction_datetime) OVER (PARTITION BY t.user_id ORDER BY t.transaction_datetime) AS previous_timestamp,
        LAG(t.amount) OVER (PARTITION BY t.user_id ORDER BY t.transaction_datetime) AS previous_amount
    FROM transactions t
    WHERE t.status = 'SUCCESS'
) suspicious
WHERE amount >= 1000
  AND previous_amount >= 1000
  AND TIMESTAMPDIFF(MINUTE, previous_timestamp, transaction_datetime) <= 30
  AND NOT EXISTS (
      SELECT 1
      FROM fraud_alerts fa
      WHERE fa.transaction_id = suspicious.transaction_id
        AND fa.alert_type = 'HIGH_VALUE_BURST'
  );
