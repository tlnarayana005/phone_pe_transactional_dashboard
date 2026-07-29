import { useEffect, useMemo, useState } from 'react';
import { getDashboardData } from './api.js';
import { buildDashboard, money, toCsv } from './analytics.js';
import { BarList, Filters, FraudList, Header, MerchantTable, Panel, StatGrid } from './components.jsx';

const blankData = { users: [], merchants: [], transactions: [] };

function downloadCsv(csv) {
  const blob = new Blob([csv], { type: 'text/csv' });
  const link = document.createElement('a');
  link.href = URL.createObjectURL(blob);
  link.download = 'phonepe_transactions.csv';
  link.click();
  URL.revokeObjectURL(link.href);
}

export default function App() {
  const [method, setMethod] = useState('ALL');
  const [status, setStatus] = useState('ALL');
  const [refreshKey, setRefreshKey] = useState(0);
  const [data, setData] = useState(blankData);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    const controller = new AbortController();
    setIsLoading(true);
    setError('');

    getDashboardData({ method, status }, controller.signal)
      .then(setData)
      .catch((apiError) => {
        if (apiError.name !== 'AbortError') setError('Unable to load dashboard data from Express.');
      })
      .finally(() => {
        if (!controller.signal.aborted) setIsLoading(false);
      });

    return () => controller.abort();
  }, [method, status, refreshKey]);

  const dashboard = useMemo(
    () => buildDashboard(data.transactions, data.users, data.merchants),
    [data]
  );

  const exportCurrentRows = () => {
    downloadCsv(toCsv(data.transactions, dashboard.userById, dashboard.merchantById));
  };

  return (
    <>
      <Header
        disabled={isLoading || !!error}
        onExport={exportCurrentRows}
        onRefresh={() => setRefreshKey((key) => key + 1)}
      />

      <main className="dashboard-shell">
        <Filters
          method={method}
          status={status}
          onMethodChange={setMethod}
          onStatusChange={setStatus}
        />

        <section className="main-panel">
          {error && <div className="status-banner error">{error}</div>}
          {isLoading && <div className="status-banner">Loading dashboard data from Express...</div>}

          <StatGrid stats={dashboard.stats} />

          <section className="chart-grid">
            <Panel title="Daily Volume Trend" subtitle="Successful revenue by date" className="wide">
              <BarList rows={dashboard.dailyRevenue} format={money.format} />
            </Panel>

            <Panel title="Success Mix" subtitle="Attempt status split">
              <BarList rows={dashboard.statusMix} />
            </Panel>

            <Panel title="Payment Methods" subtitle="UPI vs card volume">
              <BarList rows={dashboard.paymentMix} format={money.format} />
            </Panel>
          </section>

          <section className="table-grid">
            <Panel title="Top Merchants" subtitle="Ranked by gross volume">
              <MerchantTable rows={dashboard.merchants} />
            </Panel>

            <Panel title="Fraud Review" subtitle="High-value burst detection" className="alert-panel">
              <div className="fraud-list"><FraudList alerts={dashboard.fraudAlerts} /></div>
            </Panel>
          </section>
        </section>
      </main>
    </>
  );
}