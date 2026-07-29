-- PhonePe-style transaction analytics schema
-- MySQL 8+ syntax

DROP TABLE IF EXISTS transaction_audit;
DROP TABLE IF EXISTS fraud_alerts;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS wallets;
DROP TABLE IF EXISTS merchants;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    user_id INT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE,
    city VARCHAR(60),
    is_upi_active INT NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE merchants (
    merchant_id INT PRIMARY KEY,
    merchant_name VARCHAR(120) NOT NULL,
    category VARCHAR(80) NOT NULL,
    city VARCHAR(60),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE wallets (
    wallet_id INT PRIMARY KEY,
    user_id INT NOT NULL,
    wallet_type VARCHAR(30) NOT NULL,
    wallet_balance DECIMAL(12,2) NOT NULL DEFAULT 0,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_wallet_user FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY,
    user_id INT NOT NULL,
    merchant_id INT NOT NULL,
    wallet_id INT,
    amount DECIMAL(12,2) NOT NULL,
    status VARCHAR(20) NOT NULL,
    payment_method VARCHAR(20) NOT NULL,
    channel VARCHAR(20) NOT NULL,
    transaction_type VARCHAR(20) NOT NULL,
    cashback_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    transaction_datetime TIMESTAMP NOT NULL,
    location VARCHAR(100),
    device_id VARCHAR(50),
    CONSTRAINT fk_transaction_user FOREIGN KEY (user_id) REFERENCES users(user_id),
    CONSTRAINT fk_transaction_merchant FOREIGN KEY (merchant_id) REFERENCES merchants(merchant_id),
    CONSTRAINT fk_transaction_wallet FOREIGN KEY (wallet_id) REFERENCES wallets(wallet_id)
);

CREATE TABLE transaction_audit (
    audit_id INT PRIMARY KEY AUTO_INCREMENT,
    transaction_id INT NOT NULL,
    user_id INT NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    status VARCHAR(20) NOT NULL,
    audit_note VARCHAR(200),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_audit_transaction FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id)
);

CREATE TABLE fraud_alerts (
    alert_id INT PRIMARY KEY AUTO_INCREMENT,
    transaction_id INT NOT NULL,
    user_id INT NOT NULL,
    alert_type VARCHAR(80) NOT NULL,
    alert_message VARCHAR(255) NOT NULL,
    severity VARCHAR(20) NOT NULL DEFAULT 'MEDIUM',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_fraud_transaction FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id),
    CONSTRAINT fk_fraud_user FOREIGN KEY (user_id) REFERENCES users(user_id)
);
-- Indexes for analytics performance
CREATE INDEX idx_transactions_user_time ON transactions(user_id, transaction_datetime);
CREATE INDEX idx_transactions_merchant_time ON transactions(merchant_id, transaction_datetime);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_transactions_payment_method ON transactions(payment_method);
CREATE INDEX idx_transactions_amount ON transactions(amount);
CREATE INDEX idx_wallets_user ON wallets(user_id);
CREATE INDEX idx_users_city ON users(city);
CREATE INDEX idx_merchants_category ON merchants(category);
CREATE INDEX idx_fraud_alerts_user_time ON fraud_alerts(user_id, created_at);



