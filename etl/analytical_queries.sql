-- ============================================================================
-- 1. NORMALIZED 6-ENTITY RELATIONAL SCHEMA (3NF) + COMPOSITE INDEXES
-- ============================================================================

CREATE TABLE IF NOT EXISTS merchants (
    merchant_id VARCHAR(36) PRIMARY KEY,
    merchant_name VARCHAR(120) NOT NULL,
    category VARCHAR(64) NOT NULL,
    city VARCHAR(64) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS users (
    user_id VARCHAR(36) PRIMARY KEY,
    full_name VARCHAR(120) NOT NULL,
    kyc_status VARCHAR(20) NOT NULL CHECK (kyc_status IN ('VERIFIED', 'PENDING', 'REJECTED')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS wallets (
    wallet_id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    current_balance DECIMAL(14, 2) NOT NULL DEFAULT 0.00,
    currency CHAR(3) NOT NULL DEFAULT 'INR',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_wallet_user FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE IF NOT EXISTS transactions (
    transaction_id VARCHAR(36) PRIMARY KEY,
    merchant_id VARCHAR(36) NOT NULL,
    user_id VARCHAR(36) NOT NULL,
    wallet_id VARCHAR(36) NOT NULL,
    amount DECIMAL(14, 2) NOT NULL CHECK (amount > 0),
    payment_method VARCHAR(32) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('SUCCESS', 'PENDING', 'FAILED', 'REVERSED')),
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    CONSTRAINT fk_tx_merchant FOREIGN KEY (merchant_id) REFERENCES merchants(merchant_id),
    CONSTRAINT fk_tx_user FOREIGN KEY (user_id) REFERENCES users(user_id),
    CONSTRAINT fk_tx_wallet FOREIGN KEY (wallet_id) REFERENCES wallets(wallet_id)
);

CREATE TABLE IF NOT EXISTS risk_flags (
    risk_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    transaction_id VARCHAR(36) NOT NULL,
    risk_score INT NOT NULL,
    risk_reason VARCHAR(128) NOT NULL,
    flagged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_risk_tx FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id)
);

CREATE TABLE IF NOT EXISTS audit_logs (
    audit_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    transaction_id VARCHAR(36) NOT NULL,
    previous_status VARCHAR(20),
    new_status VARCHAR(20) NOT NULL,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_audit_tx FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id)
);

-- Composite index for high-frequency merchant time-range queries
CREATE INDEX idx_tx_merchant_created ON transactions (merchant_id, created_at, status);


-- ============================================================================
-- 2. ANALYTICAL SQL QUERIES (WINDOW FUNCTIONS, CTEs, MULTI-TABLE JOINS)
-- ============================================================================

-- QUERY A: Daily & Monthly Cumulative Merchant Settlement Velocity (Resets Monthly)
WITH daily_merchant_volume AS (
    SELECT
        t.merchant_id,
        m.merchant_name,
        DATE(t.created_at) AS settlement_date,
        DATE_FORMAT(t.created_at, '%Y-%m') AS settlement_month,
        COUNT(t.transaction_id) AS daily_txn_count,
        SUM(t.amount) AS daily_settled_amount
    FROM transactions t
    INNER JOIN merchants m ON t.merchant_id = m.merchant_id
    WHERE t.status = 'SUCCESS'
    GROUP BY t.merchant_id, m.merchant_name, DATE(t.created_at), DATE_FORMAT(t.created_at, '%Y-%m')
)
SELECT
    merchant_id,
    merchant_name,
    settlement_date,
    daily_txn_count,
    daily_settled_amount,
    SUM(daily_settled_amount) OVER (
        PARTITION BY merchant_id, settlement_month
        ORDER BY settlement_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS monthly_cumulative_balance,
    AVG(daily_settled_amount) OVER (
        PARTITION BY merchant_id
        ORDER BY settlement_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS rolling_7d_avg_settlement
FROM daily_merchant_volume
ORDER BY merchant_id, settlement_date;


-- QUERY B: Top 3 Merchants per Category by Settled Volume (Using DENSE_RANK)
WITH merchant_category_totals AS (
    SELECT
        m.category,
        m.merchant_id,
        m.merchant_name,
        COUNT(t.transaction_id) AS total_txns,
        COALESCE(SUM(CASE WHEN t.status = 'SUCCESS' THEN t.amount ELSE 0 END), 0) AS settled_volume,
        ROUND(
            100.0 * SUM(CASE WHEN t.status = 'SUCCESS' THEN 1 ELSE 0 END) / NULLIF(COUNT(t.transaction_id), 0),
            2
        ) AS payment_success_rate_pct
    FROM merchants m
    LEFT JOIN transactions t ON m.merchant_id = t.merchant_id
    GROUP BY m.category, m.merchant_id, m.merchant_name
),
ranked_merchants AS (
    SELECT
        *,
        DENSE_RANK() OVER (PARTITION BY category ORDER BY settled_volume DESC) AS category_rank
    FROM merchant_category_totals
)
SELECT
    category,
    category_rank,
    merchant_id,
    merchant_name,
    total_txns,
    settled_volume,
    payment_success_rate_pct
FROM ranked_merchants
WHERE category_rank <= 3
ORDER BY category, category_rank;


-- QUERY C: High-Risk Anomaly & Audit Compliance Report across 4 Joined Tables
SELECT
    t.transaction_id,
    m.merchant_name,
    m.category,
    u.kyc_status,
    t.amount,
    r.risk_reason,
    r.risk_score,
    a.previous_status,
    a.new_status,
    t.created_at
FROM transactions t
INNER JOIN merchants m ON t.merchant_id = m.merchant_id
INNER JOIN users u ON t.user_id = u.user_id
INNER JOIN risk_flags r ON t.transaction_id = r.transaction_id
LEFT JOIN audit_logs a ON t.transaction_id = a.transaction_id
WHERE r.risk_score >= 70
ORDER BY t.amount DESC, t.created_at DESC;
