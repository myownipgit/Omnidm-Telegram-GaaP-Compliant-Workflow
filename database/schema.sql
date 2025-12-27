-- Telegraph E-Commerce Database Schema
-- Cambodia GaaP-Compliant E-Commerce Platform
-- Version: 1.0.0

-- ============================================
-- Drop existing tables (for clean reinstall)
-- ============================================

DROP TABLE IF EXISTS audit_logs CASCADE;
DROP TABLE IF EXISTS fulfillments CASCADE;
DROP TABLE IF EXISTS settlements CASCADE;
DROP TABLE IF EXISTS payment_intents CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS merchants CASCADE;
DROP TYPE IF EXISTS order_status;
DROP TYPE IF EXISTS payment_status;
DROP TYPE IF EXISTS identity_level;
DROP TYPE IF EXISTS amount_band;

-- ============================================
-- Custom Types
-- ============================================

CREATE TYPE order_status AS ENUM (
  'pending',
  'confirmed',
  'paid',
  'fulfilled',
  'completed',
  'cancelled',
  'refunded'
);

CREATE TYPE payment_status AS ENUM (
  'pending',
  'authorized',
  'captured',
  'settled',
  'failed',
  'expired',
  'refunded'
);

CREATE TYPE identity_level AS ENUM (
  'anonymous',
  'basic',
  'verified',
  'high_assurance'
);

CREATE TYPE amount_band AS ENUM (
  'A',  -- ≤ $10
  'B',  -- $10-100
  'C',  -- $100-1,000
  'D'   -- > $1,000
);

-- ============================================
-- Merchants Table
-- ============================================

CREATE TABLE merchants (
  merchant_id VARCHAR(50) PRIMARY KEY,
  merchant_name VARCHAR(255) NOT NULL,
  merchant_type VARCHAR(50) NOT NULL,
  email VARCHAR(255),
  phone VARCHAR(20),
  address TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  active BOOLEAN DEFAULT TRUE
);

-- ============================================
-- Customers Table
-- ============================================

CREATE TABLE customers (
  customer_id SERIAL PRIMARY KEY,
  telegram_user_id BIGINT UNIQUE,
  username VARCHAR(255),
  first_name VARCHAR(255),
  last_name VARCHAR(255),
  phone VARCHAR(20),
  email VARCHAR(255),
  identity_level identity_level DEFAULT 'anonymous',
  camdigi_key_id VARCHAR(255),  -- CamDigiKey identifier
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_active_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_customers_telegram ON customers(telegram_user_id);
CREATE INDEX idx_customers_identity_level ON customers(identity_level);

-- ============================================
-- Products Table
-- ============================================

CREATE TABLE products (
  product_id VARCHAR(10) PRIMARY KEY,
  merchant_id VARCHAR(50) REFERENCES merchants(merchant_id),
  product_name VARCHAR(255) NOT NULL,
  description TEXT,
  price DECIMAL(10, 2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'USD',
  amount_band amount_band NOT NULL,
  category VARCHAR(100),
  preparation_time_minutes INT DEFAULT 0,
  available BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_products_merchant ON products(merchant_id);
CREATE INDEX idx_products_band ON products(amount_band);
CREATE INDEX idx_products_available ON products(available);

-- ============================================
-- Orders Table
-- ============================================

CREATE TABLE orders (
  order_id VARCHAR(100) PRIMARY KEY,
  customer_id INT REFERENCES customers(customer_id),
  merchant_id VARCHAR(50) REFERENCES merchants(merchant_id),
  order_status order_status DEFAULT 'pending',
  total_amount DECIMAL(10, 2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'USD',
  amount_band amount_band NOT NULL,
  channel VARCHAR(50) DEFAULT 'telegram',
  telegram_chat_id BIGINT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP,
  completed_at TIMESTAMP
);

CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_merchant ON orders(merchant_id);
CREATE INDEX idx_orders_status ON orders(order_status);
CREATE INDEX idx_orders_created ON orders(created_at DESC);

-- ============================================
-- Order Items Table
-- ============================================

CREATE TABLE order_items (
  item_id SERIAL PRIMARY KEY,
  order_id VARCHAR(100) REFERENCES orders(order_id) ON DELETE CASCADE,
  product_id VARCHAR(10) REFERENCES products(product_id),
  quantity INT NOT NULL DEFAULT 1,
  unit_price DECIMAL(10, 2) NOT NULL,
  total_price DECIMAL(10, 2) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_order_items_order ON order_items(order_id);

-- ============================================
-- Payment Intents Table (CamDX Integration)
-- ============================================

CREATE TABLE payment_intents (
  intent_id VARCHAR(100) PRIMARY KEY,
  order_id VARCHAR(100) REFERENCES orders(order_id),
  customer_id INT REFERENCES customers(customer_id),
  merchant_id VARCHAR(50) REFERENCES merchants(merchant_id),
  amount DECIMAL(10, 2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'USD',
  payment_status payment_status DEFAULT 'pending',
  identity_level identity_level NOT NULL,
  amount_band amount_band NOT NULL,
  policy_decision VARCHAR(50),  -- 'allowed', 'limited', 'blocked'
  camdx_correlation_id VARCHAR(100),
  khqr_string TEXT,
  khqr_deeplink TEXT,
  khqr_md5_hash VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP NOT NULL,
  authorized_at TIMESTAMP,
  settled_at TIMESTAMP
);

CREATE INDEX idx_payment_intents_order ON payment_intents(order_id);
CREATE INDEX idx_payment_intents_customer ON payment_intents(customer_id);
CREATE INDEX idx_payment_intents_status ON payment_intents(payment_status);
CREATE INDEX idx_payment_intents_expires ON payment_intents(expires_at);

-- ============================================
-- Settlements Table (Bakong Integration)
-- ============================================

CREATE TABLE settlements (
  settlement_id SERIAL PRIMARY KEY,
  intent_id VARCHAR(100) REFERENCES payment_intents(intent_id),
  order_id VARCHAR(100) REFERENCES orders(order_id),
  amount DECIMAL(10, 2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'USD',
  bakong_tx_id VARCHAR(255),
  settlement_ref VARCHAR(255),
  settlement_status VARCHAR(50) DEFAULT 'pending',
  verified_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_settlements_intent ON settlements(intent_id);
CREATE INDEX idx_settlements_order ON settlements(order_id);
CREATE INDEX idx_settlements_status ON settlements(settlement_status);

-- ============================================
-- Fulfillments Table (Grab Integration)
-- ============================================

CREATE TABLE fulfillments (
  fulfillment_id SERIAL PRIMARY KEY,
  order_id VARCHAR(100) REFERENCES orders(order_id),
  delivery_method VARCHAR(50) DEFAULT 'grab_express',
  grab_delivery_id VARCHAR(255),
  driver_assigned BOOLEAN DEFAULT FALSE,
  pickup_address TEXT,
  delivery_address TEXT,
  estimated_delivery TIMESTAMP,
  actual_delivery TIMESTAMP,
  fulfillment_status VARCHAR(50) DEFAULT 'preparing',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_fulfillments_order ON fulfillments(order_id);
CREATE INDEX idx_fulfillments_status ON fulfillments(fulfillment_status);

-- ============================================
-- Audit Logs Table (CamDL Integration)
-- ============================================

CREATE TABLE audit_logs (
  log_id SERIAL PRIMARY KEY,
  event_type VARCHAR(100) NOT NULL,
  event_data JSONB NOT NULL,
  event_hash VARCHAR(64) NOT NULL,  -- SHA256 hash
  camdl_block VARCHAR(255),
  camdl_tx_hash VARCHAR(255),
  order_id VARCHAR(100),
  intent_id VARCHAR(100),
  customer_id INT,
  merchant_id VARCHAR(50),
  anchored_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_logs_event_type ON audit_logs(event_type);
CREATE INDEX idx_audit_logs_order ON audit_logs(order_id);
CREATE INDEX idx_audit_logs_created ON audit_logs(created_at DESC);

-- ============================================
-- Default Data
-- ============================================

-- Insert default merchant
INSERT INTO merchants (merchant_id, merchant_name, merchant_type, email, phone)
VALUES (
  'numpang-express-001',
  'Num Pang Express',
  'sme_food_vendor',
  'contact@numpangexpress.com',
  '+855 12 345 678'
);

-- Insert default products (from product catalog)
INSERT INTO products (product_id, merchant_id, product_name, description, price, currency, amount_band, category, preparation_time_minutes, available)
VALUES
  ('P001', 'numpang-express-001', 'Num Pang Sandwich', 'Classic Cambodian baguette', 3.50, 'USD', 'A', 'individual', 5, TRUE),
  ('P002', 'numpang-express-001', 'Coffee + Pastry Set', 'Perfect breakfast combo', 5.00, 'USD', 'A', 'breakfast', 3, TRUE),
  ('P003', 'numpang-express-001', 'Lunch Set (4 people)', 'Family meal deal', 45.00, 'USD', 'B', 'family', 15, TRUE),
  ('P004', 'numpang-express-001', 'Party Catering', '20-person event package', 250.00, 'USD', 'C', 'catering', 120, TRUE),
  ('P005', 'numpang-express-001', 'Wedding Catering', 'Full wedding service (100+ guests)', 2500.00, 'USD', 'D', 'premium_catering', 480, TRUE);

-- ============================================
-- Views
-- ============================================

-- Active Orders View
CREATE OR REPLACE VIEW active_orders AS
SELECT
  o.order_id,
  o.customer_id,
  c.first_name,
  c.last_name,
  o.total_amount,
  o.order_status,
  pi.payment_status,
  o.created_at
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN payment_intents pi ON o.order_id = pi.order_id
WHERE o.order_status NOT IN ('completed', 'cancelled', 'refunded')
ORDER BY o.created_at DESC;

-- Pending Settlements View
CREATE OR REPLACE VIEW pending_settlements AS
SELECT
  pi.intent_id,
  pi.order_id,
  pi.amount,
  pi.khqr_md5_hash,
  pi.created_at,
  pi.expires_at,
  EXTRACT(EPOCH FROM (pi.expires_at - CURRENT_TIMESTAMP))/60 AS minutes_until_expiry
FROM payment_intents pi
WHERE pi.payment_status = 'pending'
  AND pi.expires_at > CURRENT_TIMESTAMP
ORDER BY pi.created_at ASC;

-- ============================================
-- Functions
-- ============================================

-- Update timestamps automatically
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update_timestamp trigger to relevant tables
CREATE TRIGGER update_merchants_timestamp
  BEFORE UPDATE ON merchants
  FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_customers_timestamp
  BEFORE UPDATE ON customers
  FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_products_timestamp
  BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_orders_timestamp
  BEFORE UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_fulfillments_timestamp
  BEFORE UPDATE ON fulfillments
  FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- ============================================
-- Permissions
-- ============================================

-- Create read-only user (for reporting/analytics)
-- CREATE USER telegraph_readonly WITH PASSWORD 'your_password_here';
-- GRANT CONNECT ON DATABASE telegraph_commerce TO telegraph_readonly;
-- GRANT USAGE ON SCHEMA public TO telegraph_readonly;
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO telegraph_readonly;

-- ============================================
-- Comments
-- ============================================

COMMENT ON TABLE merchants IS 'Merchant/vendor information';
COMMENT ON TABLE customers IS 'Customer profiles with CamDigiKey integration';
COMMENT ON TABLE products IS 'Product catalog with GaaP amount bands';
COMMENT ON TABLE orders IS 'Customer orders from Telegram';
COMMENT ON TABLE payment_intents IS 'CamDX payment intents with KHQR';
COMMENT ON TABLE settlements IS 'Bakong settlement verification';
COMMENT ON TABLE fulfillments IS 'Grab delivery fulfillment';
COMMENT ON TABLE audit_logs IS 'CamDL blockchain audit trail';
