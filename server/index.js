import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import { merchants, transactions, users } from './data.js';

const app = express();
const port = Number(process.env.PORT || 3001);
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(__dirname, '..');

app.use(express.json());

app.get('/api/health', (_request, response) => {
  response.json({ status: 'ok', service: 'phonepe-analytics-api' });
});

app.get('/api/dashboard-data', (request, response) => {
  const method = request.query.method || 'ALL';
  const status = request.query.status || 'ALL';
  const filteredTransactions = transactions.filter((transaction) =>
    (method === 'ALL' || transaction.method === method) &&
    (status === 'ALL' || transaction.status === status)
  );

  response.json({
    users,
    merchants,
    transactions: filteredTransactions,
    filters: { method, status }
  });
});

app.use(express.static(path.join(projectRoot, 'dist')));

app.use((request, response, next) => {
  if (request.path.startsWith('/api')) return next();
  return response.sendFile(path.join(projectRoot, 'dist', 'index.html'));
});

app.listen(port, () => {
  console.log(`Express API running at http://127.0.0.1:${port}`);
});