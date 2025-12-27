# G03 - Intent Builder

## Purpose

Creates order and payment intents from customer requests. Manages order lifecycle from initial product selection through confirmation, building structured order data for downstream payment processing.

## Workflows in This Group

| Workflow Name | Version | Status | File |
|---------------|---------|--------|------|
| [KH.GaaS] 03 - Intent Builder | v1 | Active | G03.Intent.Builder.v1.json |

## Integration Points

### Upstream
- **G01 - Channel Ingress** - Receives product selections and order requests
- **G02 - Identity & Policy** - Receives policy decisions (allowed/blocked)

### Downstream
- **G04 - CamDX Integration** - Publishes payment intent to CamDX
- **G06 - Telegram Delivery** - Sends order confirmations and summaries
- **Database (orders, order_items)** - Persists order data
- **G09 - Audit** - Logs order events

## GaaP Compliance Layers

| Layer | Purpose | Implementation |
|-------|---------|----------------|
| **L7 - Applications** | Order management | Order creation, validation, confirmation |
| **L2 - Interoperability** | Intent publishing | CamDX-compatible intent structure |
| **L4 - Compliance** | Order audit trail | All order events logged |

## Quick Start Guide

### Prerequisites
- Database schema initialized (orders, order_items, products tables)
- Product catalog configured in database
- PostgreSQL credentials in n8n

### Configuration Steps

1. **Verify Database Tables**
   ```sql
   -- Check products exist
   SELECT * FROM products;

   -- Should show P001-P005 from schema.sql
   ```

2. **Import Workflow**
   - Upload `G03.Intent.Builder.v1.json`
   - Link PostgreSQL credentials
   - Activate workflow

3. **Test Order Creation**
   - Send product code (e.g., "P001") via Telegram
   - Specify quantity (e.g., "2")
   - Confirm order ("Yes")

### Order Lifecycle

```
Customer selects product (P001)
    ↓
Lookup product details from database
    ↓
Customer specifies quantity (2)
    ↓
Calculate total amount ($7.00)
    ↓
Determine amount band (A)
    ↓
Create pending order record
    ↓
Display order summary
    ↓
Customer confirms (Yes/No)
    ↓
    ├─ Yes → Update to 'confirmed' → G04 (Payment)
    └─ No → Update to 'cancelled'
```

### Database Schema

**orders Table:**
```sql
CREATE TABLE orders (
  order_id VARCHAR(100) PRIMARY KEY,      -- ORD-YYYYMMDD-NNNN
  customer_id INT REFERENCES customers,
  merchant_id VARCHAR(50),
  order_status order_status,              -- pending, confirmed, paid, etc.
  total_amount DECIMAL(10, 2),
  currency VARCHAR(3) DEFAULT 'USD',
  amount_band amount_band,                -- A, B, C, D
  telegram_chat_id BIGINT,
  created_at TIMESTAMP,
  expires_at TIMESTAMP,                   -- 15-60 min based on band
  completed_at TIMESTAMP
);
```

**order_items Table:**
```sql
CREATE TABLE order_items (
  item_id SERIAL PRIMARY KEY,
  order_id VARCHAR(100) REFERENCES orders,
  product_id VARCHAR(10) REFERENCES products,
  quantity INT NOT NULL,
  unit_price DECIMAL(10, 2),
  total_price DECIMAL(10, 2)
);
```

### Order ID Format

Pattern: `ORD-YYYYMMDD-NNNN`

Examples:
- `ORD-20250101-0001` - First order on Jan 1, 2025
- `ORD-20250101-0042` - 42nd order on same day

### Order Status States

| Status | Description | Next States |
|--------|-------------|-------------|
| `pending` | Order created, awaiting confirmation | confirmed, cancelled |
| `confirmed` | Customer confirmed, ready for payment | paid, expired |
| `paid` | Payment received | fulfilled |
| `fulfilled` | Delivered to customer | completed |
| `completed` | Transaction finished | - |
| `cancelled` | User cancelled | - |
| `refunded` | Payment returned | - |

### Amount Band Calculation

```javascript
function calculateBand(amount) {
  if (amount <= 10) return 'A';
  if (amount <= 100) return 'B';
  if (amount <= 1000) return 'C';
  return 'D';
}
```

### Expiry Time Calculation

| Band | Base Timeout | + Prep Time |
|------|--------------|-------------|
| A | 15 min | + product prep |
| B | 20 min | + product prep |
| C | 30 min | + product prep |
| D | 60 min | + product prep |

Example:
- Product P001: prep_time = 5 minutes
- Band A order: expires_at = now + 15 + 5 = 20 minutes

### Product Catalog Integration

**Sample Product Query:**
```sql
SELECT
  product_id,
  product_name,
  price,
  amount_band,
  preparation_time_minutes,
  available
FROM products
WHERE product_id = 'P001'
  AND available = TRUE;
```

**Response:**
```json
{
  "product_id": "P001",
  "product_name": "Num Pang Sandwich",
  "price": 3.50,
  "amount_band": "A",
  "preparation_time_minutes": 5,
  "available": true
}
```

### Multi-Item Orders

Currently supports single product per order. For multi-item support:

1. Collect multiple product selections
2. Calculate combined total
3. Use highest amount band among items
4. Create multiple order_items records

Future enhancement tracked in roadmap.

### Environment Variables

None required (uses database credentials).

### Monitoring

**Key Metrics:**
- Orders created per hour
- Order confirmation rate
- Average order value
- Order cancellation rate
- Band distribution (A/B/C/D)

**Alerts:**
- Order creation failure > 1%
- Confirmation rate < 70%
- Database connection errors

### Troubleshooting

**Issue: Product not found**
- Verify product exists: `SELECT * FROM products WHERE product_id = 'P001';`
- Check product is available: `available = TRUE`
- Review product catalog configuration

**Issue: Order ID collision**
- Check order ID generation logic
- Verify unique constraint on orders.order_id
- May need to add random suffix

**Issue: Amount band incorrect**
- Review band calculation logic
- Check product price in database
- Verify quantity multiplication

**Issue: Order timeout too short**
- Check prep_time_minutes in products table
- Review band-based timeout logic
- Consider product type (catering needs more time)

### Testing

Use mock data from `tests/mock-data/orders.json`:

**Test Scenario 1: Simple order (Band A)**
1. Select product: `P001`
2. Quantity: `2`
3. Expected total: $7.00
4. Expected band: A
5. Expected expiry: now + 20 min (15 + 5 prep)

**Test Scenario 2: High-value order (Band D)**
1. Select product: `P005`
2. Quantity: `1`
3. Expected total: $2,500.00
4. Expected band: D
5. Expected expiry: now + 540 min (60 + 480 prep)

### Related Documentation

- Product Catalog: `config/product-catalog.json`
- Database Schema: `database/schema.sql`
- Order Flow Test: `tests/test-scenarios/order-flow.md`
- G04 - CamDX Integration (payment intent)
