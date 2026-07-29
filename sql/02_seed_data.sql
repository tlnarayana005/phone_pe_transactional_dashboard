-- Seed data for demo analytics workbook

INSERT INTO users (user_id, full_name, phone, email, city, is_upi_active, created_at) VALUES
(1, 'Aarav Sharma', '9000010001', 'aarav@example.com', 'Delhi', 1, '2024-01-10 09:15:00'),
(2, 'Priya Nair', '9000010002', 'priya@example.com', 'Bengaluru', 1, '2024-01-12 10:20:00'),
(3, 'Rohan Verma', '9000010003', 'rohan@example.com', 'Mumbai', 1, '2024-02-01 08:05:00'),
(4, 'Sneha Iyer', '9000010004', 'sneha@example.com', 'Chennai', 0, '2024-02-11 12:10:00'),
(5, 'Karan Singh', '9000010005', 'karan@example.com', 'Hyderabad', 1, '2024-03-04 14:40:00');

INSERT INTO merchants (merchant_id, merchant_name, category, city, created_at) VALUES
(101, 'Airtel Recharge', 'Telecom', 'Delhi', '2023-12-01 08:00:00'),
(102, 'Zomato', 'Food Delivery', 'Mumbai', '2023-12-08 09:30:00'),
(103, 'BookMyShow', 'Entertainment', 'Bengaluru', '2023-12-18 10:00:00'),
(104, 'BigBasket', 'Grocery', 'Hyderabad', '2024-01-03 11:20:00'),
(105, 'Uber', 'Transport', 'Chennai', '2024-01-12 13:00:00');

INSERT INTO wallets (wallet_id, user_id, wallet_type, wallet_balance, updated_at) VALUES
(201, 1, 'UPI', 1250.00, '2024-06-30 18:00:00'),
(202, 2, 'UPI', 940.50, '2024-06-30 18:00:00'),
(203, 3, 'CARD', 3100.00, '2024-06-30 18:00:00'),
(204, 4, 'UPI', 650.00, '2024-06-30 18:00:00'),
(205, 5, 'UPI', 1420.00, '2024-06-30 18:00:00');

INSERT INTO transactions (transaction_id, user_id, merchant_id, wallet_id, amount, status, payment_method, channel, transaction_type, cashback_amount, transaction_datetime, location, device_id) VALUES
(1001, 1, 101, 201, 399.00, 'SUCCESS', 'UPI', 'APP', 'PAYMENT', 20.00, '2024-06-01 09:45:00', 'Delhi', 'D-1001'),
(1002, 2, 102, 202, 520.00, 'SUCCESS', 'UPI', 'APP', 'PAYMENT', 15.00, '2024-06-01 12:20:00', 'Mumbai', 'D-1002'),
(1003, 1, 103, 201, 850.00, 'FAILED', 'UPI', 'APP', 'PAYMENT', 0.00, '2024-06-02 18:10:00', 'Delhi', 'D-1001'),
(1004, 3, 104, 203, 1250.00, 'SUCCESS', 'CARD', 'POS', 'PAYMENT', 40.00, '2024-06-03 16:55:00', 'Hyderabad', 'D-1003'),
(1005, 4, 105, 204, 310.00, 'SUCCESS', 'UPI', 'APP', 'PAYMENT', 10.00, '2024-06-04 08:40:00', 'Chennai', 'D-1004'),
(1006, 5, 101, 205, 450.00, 'SUCCESS', 'UPI', 'APP', 'PAYMENT', 12.00, '2024-06-04 10:20:00', 'Delhi', 'D-1005'),
(1007, 2, 103, 202, 640.00, 'SUCCESS', 'UPI', 'APP', 'PAYMENT', 18.00, '2024-06-05 21:15:00', 'Bengaluru', 'D-1002'),
(1008, 3, 102, 203, 760.00, 'SUCCESS', 'CARD', 'APP', 'PAYMENT', 25.00, '2024-06-06 19:00:00', 'Mumbai', 'D-1003'),
(1009, 1, 105, 201, 290.00, 'SUCCESS', 'UPI', 'APP', 'PAYMENT', 9.00, '2024-06-06 12:00:00', 'Chennai', 'D-1001'),
(1010, 5, 104, 205, 570.00, 'FAILED', 'UPI', 'APP', 'PAYMENT', 0.00, '2024-06-07 14:30:00', 'Hyderabad', 'D-1005'),
(1011, 5, 103, 205, 1120.00, 'SUCCESS', 'UPI', 'APP', 'PAYMENT', 35.00, '2024-06-08 10:25:00', 'Bengaluru', 'D-1005'),
(1012, 2, 101, 202, 410.00, 'SUCCESS', 'UPI', 'APP', 'PAYMENT', 13.00, '2024-06-08 15:50:00', 'Delhi', 'D-1002'),
(1013, 4, 104, 204, 390.00, 'SUCCESS', 'UPI', 'POS', 'PAYMENT', 14.00, '2024-06-09 09:05:00', 'Hyderabad', 'D-1004'),
(1014, 1, 102, 201, 870.00, 'SUCCESS', 'UPI', 'APP', 'PAYMENT', 28.00, '2024-06-09 13:45:00', 'Mumbai', 'D-1001'),
(1015, 3, 105, 203, 460.00, 'SUCCESS', 'CARD', 'APP', 'PAYMENT', 16.00, '2024-06-10 11:50:00', 'Chennai', 'D-1003'),
(1016, 3, 103, 203, 1500.00, 'SUCCESS', 'CARD', 'APP', 'PAYMENT', 0.00, '2024-06-10 12:05:00', 'Bengaluru', 'D-1003'),
(1017, 3, 104, 203, 1750.00, 'SUCCESS', 'CARD', 'APP', 'PAYMENT', 0.00, '2024-06-10 12:22:00', 'Hyderabad', 'D-1003');

INSERT INTO transaction_audit (audit_id, transaction_id, user_id, amount, status, audit_note, created_at) VALUES
(9001, 1001, 1, 399.00, 'SUCCESS', 'Initial insert audit', '2024-06-01 09:45:00'),
(9002, 1003, 1, 850.00, 'FAILED', 'Payment gateway timeout', '2024-06-02 18:10:00'),
(9003, 1010, 5, 570.00, 'FAILED', 'Insufficient authentication', '2024-06-07 14:30:00');

