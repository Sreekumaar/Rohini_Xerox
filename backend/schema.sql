CREATE TABLE IF NOT EXISTS orders (
 id TEXT PRIMARY KEY, user_id TEXT NOT NULL, customer_name TEXT, customer_email TEXT,
 customer_phone TEXT, file_name TEXT NOT NULL, storage_key TEXT NOT NULL,
 page_count INTEGER NOT NULL, copies INTEGER NOT NULL, is_color_print INTEGER NOT NULL DEFAULT 0,
 is_double_sided INTEGER NOT NULL DEFAULT 0, paper_size TEXT NOT NULL DEFAULT 'A4',
 binding_type TEXT NOT NULL DEFAULT 'none', delivery_address TEXT,
 courier_charge_paise INTEGER NOT NULL DEFAULT 0, amount_paise INTEGER NOT NULL,
 status TEXT NOT NULL DEFAULT 'pending_payment', payment_status TEXT NOT NULL DEFAULT 'unpaid',
 razorpay_order_id TEXT UNIQUE, razorpay_payment_id TEXT UNIQUE,
 created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_orders_user ON orders(user_id, created_at);
