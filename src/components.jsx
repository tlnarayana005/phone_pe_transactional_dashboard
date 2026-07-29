import { Download, RefreshCw } from 'lucide-react';
import { money } from './analytics.js';

export function Header({ onRefresh, onExport, disabled }) {
  return (
    <header className="app-header">
      <div>
        <p className="eyebrow">Payments Intelligence</p>
        <h1>PhonePe Transaction Analytics</h1>
      </div>
      <div className="header-actions">
        <button className="icon-button" onClick={onRefresh} title="Refresh dashboard" aria-label="Refresh dashboard">
          <RefreshCw size={18} />
        </button>
        <button className="text-button" onClick={onExport} disabled={disabled}>
          <Download size={16} />
          Export CSV
        </button>
      </div>
    </header>
  );
}

export function Filters({ method, status, onMethodChange, onStatusChange }) {
  return (
    <aside className="side-panel">
      <section className="filter-block">
        <h2>Filters</h2>
        <label htmlFor="methodFilter">Payment Method</label>
        <select id="methodFilter" value={method} onChange={(event) => onMethodChange(event.target.value)}>
          <option value="ALL">All methods</option>
          <option value="UPI">UPI</option>
          <option value="CARD">Card</option>
        </select>

        <label htmlFor="statusFilter">Status</label>
        <select id="statusFilter" value={status} onChange={(event) => onStatusChange(event.target.value)}>
          <option value="ALL">All statuses</option>
          <option value="SUCCESS">Success</option>
          <option value="FAILED">Failed</option>
        </select>
      </section>

      <section className="filter-block compact">
        <h2>Fraud Rule</h2>
        <div className="rule-row"><span>Amount</span><strong>INR 1,000+</strong></div>
        <div className="rule-row"><span>Window</span><strong>30 min</strong></div>
        <div className="rule-row"><span>Pattern</span><strong>2+ txns</strong></div>
      </section>
    </aside>
  );
}

export function StatGrid({ stats }) {
  return (
    <section className="kpi-grid">
      {stats.map(([label, value, note]) => (
        <article className="kpi-card" key={label}>
          <div className="kpi-label">{label}</div>
          <div className="kpi-value">{value}</div>
          <div className="kpi-note">{note}</div>
        </article>
      ))}
    </section>
  );
}

export function Panel({ title, subtitle, className = '', children }) {
  return (
    <article className={`panel ${className}`}>
      <div className="panel-title">
        <h2>{title}</h2>
        <span>{subtitle}</span>
      </div>
      {children}
    </article>
  );
}

export function BarList({ rows, format = (value) => value }) {
  const max = Math.max(...rows.map((row) => row.value), 1);

  if (!rows.length) {
    return <div className="empty-state">No data for the current filters.</div>;
  }

  return (
    <div className="bar-list">
      {rows.map((row) => (
        <div className="bar-row" key={row.label}>
          <div className="bar-label"><span>{row.label}</span><strong>{format(row.value)}</strong></div>
          <div className="bar-track"><div className="bar-fill" style={{ width: `${(row.value / max) * 100}%` }} /></div>
        </div>
      ))}
    </div>
  );
}

export function MerchantTable({ rows }) {
  return (
    <div className="table-wrap">
      <table>
        <thead><tr><th>Merchant</th><th>Category</th><th>Txns</th><th>Volume</th></tr></thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.name}>
              <td>{row.name}</td>
              <td>{row.category}</td>
              <td>{row.count}</td>
              <td className="amount">{money.format(row.volume)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export function FraudList({ alerts }) {
  if (!alerts.length) {
    return (
      <div className="fraud-item">
        <strong>No alerts</strong>
        <span>No high-value bursts match the current filters.</span>
      </div>
    );
  }

  return alerts.map((alert) => (
    <div className="fraud-item" key={alert.id}>
      <strong>{alert.user} - {money.format(alert.amount)}</strong>
      <span>{alert.merchant} after {money.format(alert.previousAmount)} only {alert.minutes} minutes earlier.</span>
      <span>{alert.time.toLocaleString('en-IN')}</span>
    </div>
  ));
}