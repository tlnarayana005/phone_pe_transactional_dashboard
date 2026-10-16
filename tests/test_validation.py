import pytest
import pandas as pd
from etl.etl_pipeline import (
    validate_and_partition_batch,
    detect_transaction_anomalies,
    reconcile_wallet_ledger,
)


def _sample_valid_record(**overrides):
    base = {
        "transaction_id": "TXN_1001",
        "merchant_id": "MERCH_01",
        "user_id": "USER_01",
        "wallet_id": "WAL_01",
        "amount": 1250.50,
        "payment_method": "UPI",
        "status": "SUCCESS",
        "created_at": "2026-03-10T10:00:00",
        "updated_at": "2026-03-10T10:00:05",
    }
    base.update(overrides)
    return base


def test_valid_record_passes_ingestion():
    valid_df, quarantine_df = validate_and_partition_batch([_sample_valid_record()])
    assert len(valid_df) == 1
    assert quarantine_df.empty
    assert valid_df.iloc[0]["amount"] == 1250.50


def test_negative_or_zero_amount_routed_to_quarantine():
    records = [
        _sample_valid_record(transaction_id="TXN_NEG", amount=-500.0),
        _sample_valid_record(transaction_id="TXN_ZERO", amount=0),
    ]
    valid_df, quarantine_df = validate_and_partition_batch(records)
    assert valid_df.empty
    assert len(quarantine_df) == 2
    assert set(quarantine_df["error_reason"]) == {"INVALID_OR_NEGATIVE_AMOUNT"}


def test_idempotent_deduplication_keeps_latest_timestamp():
    records = [
        _sample_valid_record(
            transaction_id="TXN_DUP",
            status="PENDING",
            updated_at="2026-03-10T10:00:02",
        ),
        _sample_valid_record(
            transaction_id="TXN_DUP",
            status="SUCCESS",
            updated_at="2026-03-10T10:00:09",
        ),
    ]
    valid_df, quarantine_df = validate_and_partition_batch(records)
    assert len(valid_df) == 1
    assert valid_df.iloc[0]["status"] == "SUCCESS"
    assert len(quarantine_df) == 1
    assert quarantine_df.iloc[0]["error_reason"] == "DUPLICATE_TRANSACTION_RETRY"


def test_timestamp_drift_is_quarantined():
    bad_ts = _sample_valid_record(
        transaction_id="TXN_DRIFT",
        created_at="2026-03-10T12:00:00",
        updated_at="2026-03-10T11:59:00",
    )
    valid_df, quarantine_df = validate_and_partition_batch([bad_ts])
    assert valid_df.empty
    assert quarantine_df.iloc[0]["error_reason"] == "TIMESTAMP_DRIFT_UPDATED_BEFORE_CREATED"


def test_anomaly_detection_flags_high_value_and_velocity_outliers():
    records = [
        _sample_valid_record(transaction_id="T1", merchant_id="M1", amount=100.0),
        _sample_valid_record(transaction_id="T2", merchant_id="M1", amount=120.0),
        _sample_valid_record(transaction_id="T3", merchant_id="M1", amount=110.0),
        _sample_valid_record(transaction_id="T4", merchant_id="M1", amount=60000.0),  # High value & >3x avg
    ]
    valid_df, _ = validate_and_partition_batch(records)
    scored_df = detect_transaction_anomalies(valid_df)
    flagged = scored_df[scored_df["transaction_id"] == "T4"].iloc[0]
    assert bool(flagged["risk_flag"]) is True
    assert "HIGH_VALUE_THRESHOLD_EXCEEDED" in flagged["risk_reason"]


def test_wallet_ledger_reconciliation_detects_drift():
    valid_df, _ = validate_and_partition_batch([
        _sample_valid_record(transaction_id="T1", amount=500.0, status="SUCCESS"),
        _sample_valid_record(transaction_id="T2", amount=300.0, status="FAILED"),
    ])
    # Opening 2000 - 500 settled = 1500 expected
    ok_report = reconcile_wallet_ledger(2000.0, valid_df, reported_closing_balance=1500.0)
    assert ok_report["is_reconciled"] is True

    drift_report = reconcile_wallet_ledger(2000.0, valid_df, reported_closing_balance=1200.0)
    assert drift_report["is_reconciled"] is False
    assert drift_report["discrepancy"] == -300.0
