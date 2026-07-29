export const users = [
  { id: 1, name: 'Aarav Sharma', city: 'Delhi' },
  { id: 2, name: 'Priya Nair', city: 'Bengaluru' },
  { id: 3, name: 'Rohan Verma', city: 'Mumbai' },
  { id: 4, name: 'Sneha Iyer', city: 'Chennai' },
  { id: 5, name: 'Karan Singh', city: 'Hyderabad' }
];

export const merchants = [
  { id: 101, name: 'Airtel Recharge', category: 'Telecom' },
  { id: 102, name: 'Zomato', category: 'Food Delivery' },
  { id: 103, name: 'BookMyShow', category: 'Entertainment' },
  { id: 104, name: 'BigBasket', category: 'Grocery' },
  { id: 105, name: 'Uber', category: 'Transport' }
];

export const transactions = [
  [1001, 1, 101, 399, 'SUCCESS', 'UPI', 'APP', 20, '2024-06-01T09:45:00'],
  [1002, 2, 102, 520, 'SUCCESS', 'UPI', 'APP', 15, '2024-06-01T12:20:00'],
  [1003, 1, 103, 850, 'FAILED', 'UPI', 'APP', 0, '2024-06-02T18:10:00'],
  [1004, 3, 104, 1250, 'SUCCESS', 'CARD', 'POS', 40, '2024-06-03T16:55:00'],
  [1005, 4, 105, 310, 'SUCCESS', 'UPI', 'APP', 10, '2024-06-04T08:40:00'],
  [1006, 5, 101, 450, 'SUCCESS', 'UPI', 'APP', 12, '2024-06-04T10:20:00'],
  [1007, 2, 103, 640, 'SUCCESS', 'UPI', 'APP', 18, '2024-06-05T21:15:00'],
  [1008, 3, 102, 760, 'SUCCESS', 'CARD', 'APP', 25, '2024-06-06T19:00:00'],
  [1009, 1, 105, 290, 'SUCCESS', 'UPI', 'APP', 9, '2024-06-06T12:00:00'],
  [1010, 5, 104, 570, 'FAILED', 'UPI', 'APP', 0, '2024-06-07T14:30:00'],
  [1011, 5, 103, 1120, 'SUCCESS', 'UPI', 'APP', 35, '2024-06-08T10:25:00'],
  [1012, 2, 101, 410, 'SUCCESS', 'UPI', 'APP', 13, '2024-06-08T15:50:00'],
  [1013, 4, 104, 390, 'SUCCESS', 'UPI', 'POS', 14, '2024-06-09T09:05:00'],
  [1014, 1, 102, 870, 'SUCCESS', 'UPI', 'APP', 28, '2024-06-09T13:45:00'],
  [1015, 3, 105, 460, 'SUCCESS', 'CARD', 'APP', 16, '2024-06-10T11:50:00'],
  [1016, 3, 103, 1500, 'SUCCESS', 'CARD', 'APP', 0, '2024-06-10T12:05:00'],
  [1017, 3, 104, 1750, 'SUCCESS', 'CARD', 'APP', 0, '2024-06-10T12:22:00']
].map(([id, userId, merchantId, amount, status, method, channel, cashback, time]) => ({
  id,
  userId,
  merchantId,
  amount,
  status,
  method,
  channel,
  cashback,
  time
}));