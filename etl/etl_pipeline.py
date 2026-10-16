"""
Commercial & SME Payment Transaction ETL & Validation Pipeline
Handles batch ingestion, deduplication (idempotency), dead-letter quarantine routing,
rule-based risk/anomaly scoring, and ledger balance reconciliation.
"""

from datetime import datetime
from typing import Dict, List, Tuple
import pandas as pd


REQUIRED_COLUMNS = {
    "transaction_id",
    "merchant_id",
    "user_id",
    "wallet_id",
    "amount",
    "payment_method",
    "status",
    "created_at",
    "updated_at",
}

VALID_STATUSES = {"SUCCESS", "PENDING", "FAILED", "REVERSED"}
HIGH_VALUE_THRESHOLD = 50000.0  # INR threshold for audit/risk flagging


def validate_and_partition_batch(
    raw_records: List[Dict],
) -> Tuple[pd.DataFrame, pd.DataFrame]:
    """
    Validates raw incoming transaction dicts, deduplicates retries idempotently,
    and partitions records into (valid_df, quarantine_df).
    """
    if not raw_records:
        return pd.DataFrame(), pd.DataFrame()

    valid_rows = []
    quarantine_rows = []

    for row in raw_records:
        missing_cols = REQUIRED_COLUMNS - set(row.keys())
        if missing_cols:
            bad_row = dict(row)
            bad_row["error_reason"] = f"MISSING_COLUMNS:{','.join(sorted(missing_cols))}"
            quarantine_rows.append(bad_row)
            continue

        # 1. Null primary/foreign key check
        if any(row.get(k) is None or str(row.get(k)).strip() == "" for k in ("transaction_id", "merchant_id", "user_id", "wallet_id")):
            bad_row = dict(row)
            bad_row["error_reason"] = "NULL_ENTITY_KEY"
            quarantine_rows.append(bad_row)
            continue

        # 2. Positive numeric amount check
        try:
            amount = float(row["amount"])
            if amount <= 0:
                raise ValueError("Non-positive transaction amount")
        except (ValueError, TypeError):
            bad_row = dict(row)
            bad_row["error_reason"] = "INVALID_OR_NEGATIVE_AMOUNT"
            quarantine_rows.append(bad_row)
            continue

        # 3. Status domain validation
        if str(row["status"]).upper() not in VALID_STATUSES:
            bad_row = dict(row)
            bad_row["error_reason"] = "INVALID_STATUS_CODE"
            quarantine_rows.append(bad_row)
            continue

        # 4. Timestamp ordering check (updated_at cannot precede created_at)
        try:
            created_dt = datetime.fromisoformat(str(row["created_at"]))
            updated_dt = datetime.fromisoformat(str(row["updated_at"]))
            if updated_dt < created_dt:
                bad_row = dict(row)
                bad_row["error_reason"] = "TIMESTAMP_DRIFT_UPDATED_BEFORE_CREATED"
                quarantine_rows.append(bad_row)
                continue
        except ValueError:
            bad_row = dict(row)
            bad_row["error_reason"] = "MALFORMED_ISO_TIMESTAMP"
            quarantine_rows.append(bad_row)
            continue

        clean_row = dict(row)
        clean_row["amount"] = round(amount, 2)
        clean_row["status"] = str(row["status"]).upper()
        valid_rows.append(clean_row)

    valid_df = pd.DataFrame(valid_rows)
    quarantine_df = pd.DataFrame(quarantine_rows)

    # 5. Idempotent Deduplication: Keep latest state per transaction_id based on updated_at
    if not valid_df.empty:
        valid_df = valid_df.sort_values("updated_at", ascending=True)
        duplicate_mask = valid_df.duplicated(subset=["transaction_id"], keep="last")

        if duplicate_mask.any():
            dups_df = valid_df[duplicate_mask].copy()
            dups_df["error_reason"] = "DUPLICATE_TRANSACTION_RETRY"
            quarantine_df = pd.concat([quarantine_df, dups_df], ignore_index=True)
            valid_df = valid_df[~duplicate_mask].reset_index(drop=True)

    return valid_df, quarantine_df


def detect_transaction_anomalies(valid_df: pd.DataFrame) -> pd.DataFrame:
    """
    Applies rule-based anomaly detection for audit and risk tables:
    Rule 1: High-value single transaction (> HIGH_VALUE_THRESHOLD).
    Rule 2: Statistical outlier (> 3x merchant's mean transaction value when merchant has >= 3 txns).
    """
    if valid_df.empty:
        return valid_df

    df = valid_df.copy()
    merchant_stats = df.groupby("merchant_id")["amount"].transform("mean")
    merchant_counts = df.groupby("merchant_id")["amount"].transform("count")

    df["is_high_value"] = df["amount"] >= HIGH_VALUE_THRESHOLD
    df["is_velocity_outlier"] = (merchant_counts >= 3) & (df["amount"] > 3.0 * merchant_stats)
    df["risk_flag"] = df["is_high_value"] | df["is_velocity_outlier"]

    def _assign_risk_reason(row) -> str:
        reasons = []
        if row["is_high_value"]:
            reasons.append("HIGH_VALUE_THRESHOLD_EXCEEDED")
        if row["is_velocity_outlier"]:
            reasons.append("EXCEEDS_3X_MERCHANT_AVERAGE")
        return "|".join(reasons) if reasons else "NORMAL"

    df["risk_reason"] = df.apply(_assign_risk_reason, axis=1)
    return df


def reconcile_wallet_ledger(
    opening_balance: float, transactions_df: pd.DataFrame, reported_closing_balance: float
) -> Dict[str, object]:
    """
    Verifies wallet balance integrity:
    opening_balance - sum(SUCCESS debits) == reported_closing_balance
    """
    if transactions_df.empty:
        settled_debits = 0.0
    else:
        settled_debits = float(
            transactions_df.loc[transactions_df["status"] == "SUCCESS", "amount"].sum()
        )

    expected_closing = round(opening_balance - settled_debits, 2)
    discrepancy = round(reported_closing_balance - expected_closing, 2)

    return {
        "opening_balance": round(opening_balance, 2),
        "settled_debits": round(settled_debits, 2),
        "expected_closing_balance": expected_closing,
        "reported_closing_balance": round(reported_closing_balance, 2),
        "discrepancy": discrepancy,
        "is_reconciled": abs(discrepancy) < 1e-2,
    }
