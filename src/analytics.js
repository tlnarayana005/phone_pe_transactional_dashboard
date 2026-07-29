export const money = new Intl.NumberFormat('en-IN', {
  style: 'currency',
  currency: 'INR',
  maximumFractionDigits: 0
});

const sum = (rows, pick) => rows.reduce((total, row) => total + pick(row), 0);
const dateKey = (date) => date.toISOString().slice(0, 10);

export function buildDashboard(rows, users, merchants) {
  const userById = new Map(users.map((user) => [user.id, user]));
  const merchantById = new Map(merchants.map((merchant) => [merchant.id, merchant]));
  const successRows = rows.filter((row) => row.status === 'SUCCESS');
  const failedRows = rows.filter((row) => row.status === 'FAILED');
  const revenue = sum(successRows, (row) => row.amount);

  return {
    userById,
    merchantById,
    stats: [
      ['Transactions', rows.length, 'Total attempts'],
      ['Success Rate', `${rows.length ? Math.round((successRows.length / rows.length) * 1000) / 10 : 0}%`, `${successRows.length} successful`],
      ['Failed', failedRows.length, 'Payment issues'],
      ['Revenue', money.format(revenue), 'Successful volume'],
      ['Cashback', money.format(sum(rows, (row) => row.cashback)), 'Total rewards']
    ],
    dailyRevenue: dailyRevenue(successRows),
    paymentMix: paymentMix(rows),
    statusMix: statusMix(rows),
    merchants: topMerchants(rows, merchantById),
    fraudAlerts: fraudAlerts(rows, userById, merchantById)
  };
}

function dailyRevenue(rows) {
  const totals = rows.reduce((days, row) => {
    const key = dateKey(row.time);
    days[key] = (days[key] || 0) + row.amount;
    return days;
  }, {});

  return Object.entries(totals).sort().map(([date, value]) => ({
    label: new Date(`${date}T00:00:00`).toLocaleDateString('en-IN', { day: '2-digit', month: 'short' }),
    value
  }));
}

function paymentMix(rows) {
  return totalBy(rows, (row) => row.method, (row) => row.amount);
}

function statusMix(rows) {
  return totalBy(rows, (row) => row.status);
}

function totalBy(rows, keyOf, valueOf = () => 1) {
  const totals = rows.reduce((result, row) => {
    const key = keyOf(row);
    result[key] = (result[key] || 0) + valueOf(row);
    return result;
  }, {});

  return Object.entries(totals).map(([label, value]) => ({ label, value }));
}

function topMerchants(rows, merchantById) {
  const totals = rows.reduce((result, row) => {
    const merchant = merchantById.get(row.merchantId);
    if (!merchant) return result;

    result[merchant.id] ||= { name: merchant.name, category: merchant.category, count: 0, volume: 0 };
    result[merchant.id].count += 1;
    result[merchant.id].volume += row.amount;
    return result;
  }, {});

  return Object.values(totals).sort((a, b) => b.volume - a.volume);
}

function fraudAlerts(rows, userById, merchantById) {
  const byUser = rows
    .filter((row) => row.status === 'SUCCESS')
    .sort((a, b) => a.time - b.time)
    .reduce((result, row) => {
      result[row.userId] ||= [];
      result[row.userId].push(row);
      return result;
    }, {});

  return Object.values(byUser).flatMap((userRows) => userRows.flatMap((row, index) => {
    const previous = userRows[index - 1];
    if (!previous) return [];

    const minutes = (row.time - previous.time) / 60000;
    const isBurst = row.amount >= 1000 && previous.amount >= 1000 && minutes <= 30;

    return isBurst ? [{
      id: row.id,
      amount: row.amount,
      previousAmount: previous.amount,
      minutes,
      time: row.time,
      user: userById.get(row.userId)?.name || 'Unknown user',
      merchant: merchantById.get(row.merchantId)?.name || 'Unknown merchant'
    }] : [];
  }));
}

export function toCsv(rows, userById, merchantById) {
  const header = ['transaction_id', 'user', 'merchant', 'amount', 'status', 'payment_method', 'channel', 'cashback', 'transaction_datetime'];
  const body = rows.map((row) => [
    row.id,
    userById.get(row.userId)?.name || 'Unknown',
    merchantById.get(row.merchantId)?.name || 'Unknown',
    row.amount,
    row.status,
    row.method,
    row.channel,
    row.cashback,
    row.time.toISOString()
  ]);

  return [header, ...body]
    .map((line) => line.map((value) => `"${String(value).replaceAll('"', '""')}"`).join(','))
    .join('\n');
}