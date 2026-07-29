export async function getDashboardData(filters, signal) {
  const params = new URLSearchParams(filters);
  const response = await fetch(`/api/dashboard-data?${params}`, { signal });

  if (!response.ok) {
    throw new Error(`Dashboard API returned ${response.status}`);
  }

  const data = await response.json();
  return {
    users: data.users,
    merchants: data.merchants,
    transactions: data.transactions.map((row) => ({
      ...row,
      time: new Date(row.time)
    }))
  };
}