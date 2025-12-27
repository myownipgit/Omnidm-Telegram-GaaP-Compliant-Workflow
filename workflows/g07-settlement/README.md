# G07 - Settlement Verification

## Purpose

Monitors and verifies Bakong payment settlements in real-time. Polls Bakong API for payment confirmations using KHQR MD5 hashes, updates order status upon settlement, and triggers fulfillment workflow.

## Workflows in This Group

| Workflow Name | Version | Status | File |
|---------------|---------|--------|------|
| [KH.GaaS] 07 - Settlement Verify | v1 | Active | G07.Settlement.Verify.v1.json |

## Integration Points

### Upstream
- **G05 - KHQR Generation** - Receives KHQR MD5 hash for settlement tracking
- **Bakong API Webhook** - Receives payment notifications (optional)

### Downstream
- **Bakong API** - Polls for settlement status
- **G08 - Fulfillment** - Triggers delivery when payment confirmed
- **G06 - Telegram Delivery** - Sends payment confirmation to customer
- **Database (settlements, payment_intents, orders)** - Updates payment status
- **G09 - Audit** - Logs settlement events

## GaaP Compliance Layers

| Layer | Purpose | Implementation |
|-------|---------|----------------|
| **L3 - Payments** | Bakong settlement verification | Real-time payment confirmation |
| **L4 - Compliance** | Payment audit trail | Settlement records with transaction IDs |
| **L2 - Interoperability** | Multi-bank settlement | Works across all Bakong banks |

## Quick Start Guide

### Prerequisites
- Bakong API credentials
- KHQR generated (G05)
- Database schema initialized (settlements table)

### Configuration Steps

1. **Verify Bakong API Credentials**
   ```
   Credentials → bakong_api
   - Ensure API key is valid for settlement queries
   ```

2. **Configure Polling Schedule**
   ```javascript
   // Poll every 3 seconds for pending payments
   {
     "cron": "*/3 * * * * *",  // Every 3 seconds
     "enabled": true
   }
   ```

3. **Import and Activate Workflow**
   - Upload `G07.Settlement.Verify.v1.json`
   - Link Bakong credentials
   - Configure database connection
   - Activate workflow

### Settlement Verification Flow

```
KHQR generated (G05)
    ↓
Store MD5 hash in database
    ↓
Start polling Bakong API (every 3s)
    ↓
Check settlement status by MD5 hash
    ↓
    ├─ Pending → Continue polling
    ├─ Settled → Update order → Trigger G08
    ├─ Failed → Mark failed → Notify customer
    └─ Expired → Mark expired → Cancel order
```

### Polling Strategy

**Active Polling:**
- Frequency: Every 3 seconds
- Duration: Until payment received or timeout
- Timeout: Based on amount band (15-60 min)

**Query:**
```sql
SELECT
  pi.intent_id,
  pi.khqr_md5_hash,
  pi.amount,
  pi.expires_at,
  EXTRACT(EPOCH FROM (pi.expires_at - CURRENT_TIMESTAMP)) AS seconds_remaining
FROM payment_intents pi
WHERE pi.payment_status = 'pending'
  AND pi.expires_at > CURRENT_TIMESTAMP
ORDER BY pi.created_at ASC
LIMIT 100;
```

### Bakong Settlement API

**Endpoint:** `GET https://api.bakong.nbc.gov.kh/v1/settlement/check`

**Request:**
```json
{
  "md5_hash": "5f4dcc3b5aa765d61d8327deb882cf99",
  "merchant_id": "khqr.aba@ababank"
}
```

**Response (Pending):**
```json
{
  "status": "pending",
  "md5_hash": "5f4dcc3b5aa765d61d8327deb882cf99",
  "message": "Payment not yet received",
  "expires_at": "2025-01-01T10:15:00Z"
}
```

**Response (Settled):**
```json
{
  "status": "settled",
  "md5_hash": "5f4dcc3b5aa765d61d8327deb882cf99",
  "transaction_id": "BKG-2025-TXN-789012",
  "amount": 7.00,
  "currency": "USD",
  "payer_bank": "ABA",
  "payer_account": "***1234",
  "settled_at": "2025-01-01T10:05:23Z",
  "settlement_time_seconds": 3.2
}
```

**Response (Failed):**
```json
{
  "status": "failed",
  "md5_hash": "5f4dcc3b5aa765d61d8327deb882cf99",
  "error_code": "INSUFFICIENT_FUNDS",
  "error_message": "Payer account balance too low",
  "failed_at": "2025-01-01T10:02:15Z"
}
```

### Database Updates

**On Settlement Success:**
```sql
-- 1. Insert settlement record
INSERT INTO settlements (
  intent_id,
  order_id,
  amount,
  currency,
  bakong_tx_id,
  settlement_ref,
  settlement_status,
  verified_at
) VALUES (
  'PI-20250101-0001',
  'ORD-20250101-0001',
  7.00,
  'USD',
  'BKG-2025-TXN-789012',
  'SETTLE-20250101-0001',
  'verified',
  CURRENT_TIMESTAMP
);

-- 2. Update payment intent
UPDATE payment_intents
SET payment_status = 'captured',
    settled_at = CURRENT_TIMESTAMP
WHERE intent_id = 'PI-20250101-0001';

-- 3. Update order
UPDATE orders
SET order_status = 'paid'
WHERE order_id = 'ORD-20250101-0001';
```

**On Timeout/Expiry:**
```sql
-- 1. Update payment intent
UPDATE payment_intents
SET payment_status = 'expired'
WHERE intent_id = 'PI-20250101-0001';

-- 2. Update order
UPDATE orders
SET order_status = 'cancelled'
WHERE order_id = 'ORD-20250101-0001';
```

### Settlement Performance SLA

| Metric | Target | Typical |
|--------|--------|---------|
| Settlement detection | < 10 seconds | 3-5 seconds |
| Database update | < 1 second | 200-500ms |
| Customer notification | < 15 seconds total | 5-8 seconds |
| Fulfillment trigger | < 20 seconds total | 8-12 seconds |

### Webhook Alternative

Instead of polling, configure Bakong webhook for instant notifications:

**Webhook Registration:**
```bash
POST https://api.bakong.nbc.gov.kh/v1/webhooks/register
{
  "merchant_id": "khqr.aba@ababank",
  "webhook_url": "https://automation.omnidm.ai/webhook/bakong",
  "events": ["settlement.completed", "settlement.failed"],
  "secret": "YOUR_WEBHOOK_SECRET"
}
```

**Webhook Payload:**
```json
{
  "event": "settlement.completed",
  "timestamp": "2025-01-01T10:05:23Z",
  "data": {
    "md5_hash": "5f4dcc3b5aa765d61d8327deb882cf99",
    "transaction_id": "BKG-2025-TXN-789012",
    "amount": 7.00,
    "currency": "USD",
    "settled_at": "2025-01-01T10:05:23Z"
  },
  "signature": "sha256=abc123..."  // HMAC signature for verification
}
```

**Webhook Security:**
```javascript
// Verify HMAC signature
const crypto = require('crypto');
const signature = req.headers['x-bakong-signature'];
const payload = JSON.stringify(req.body);
const expected = crypto
  .createHmac('sha256', WEBHOOK_SECRET)
  .update(payload)
  .digest('hex');

if (`sha256=${expected}` !== signature) {
  throw new Error('Invalid webhook signature');
}
```

### Duplicate Settlement Prevention

**Risk:** Customer pays twice (rare but possible)

**Prevention:**
```sql
-- Check if settlement already exists
SELECT COUNT(*) FROM settlements
WHERE intent_id = 'PI-20250101-0001'
  AND settlement_status = 'verified';

-- If count > 0, this is a duplicate
-- Log for refund processing
-- Do not update order status again
```

### Partial Settlements

**Scenario:** Customer pays less than required amount

**Bakong Response:**
```json
{
  "status": "partial",
  "md5_hash": "5f4dcc3b5aa765d61d8327deb882cf99",
  "amount_expected": 7.00,
  "amount_received": 5.00,
  "amount_remaining": 2.00
}
```

**Handling:**
1. Mark as partial payment
2. Notify customer of shortfall
3. Generate new KHQR for remaining amount
4. Wait for second payment

### Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `BAKONG_API_URL` | Bakong API endpoint | https://api.bakong.nbc.gov.kh/v1 |
| `POLLING_INTERVAL_MS` | Polling frequency | 3000 (3 seconds) |
| `SETTLEMENT_TIMEOUT_MULTIPLIER` | Safety buffer | 1.1 (10% extra) |

### Monitoring

**Key Metrics:**
- Average settlement time
- Settlement success rate
- Polling efficiency (API calls per settlement)
- Timeout rate
- Duplicate detection rate

**Alerts:**
- Settlement detection > 10 seconds
- Bakong API errors > 1%
- Timeout rate > 20%
- Duplicate settlements detected

### Troubleshooting

**Issue: Settlement never detected**
- Verify customer actually paid
- Check KHQR MD5 hash matches
- Confirm Bakong API credentials valid
- Review polling is active

**Issue: False "payment received" detection**
- Verify MD5 hash uniqueness
- Check for hash collisions
- Review settlement verification logic

**Issue: Duplicate settlement records**
- Implement idempotency checks
- Add unique constraint on (intent_id, bakong_tx_id)
- Review webhook vs polling conflicts

**Issue: Slow settlement detection**
- Check polling interval (should be 3s)
- Review Bakong API response time
- Verify network connectivity
- Consider webhook instead of polling

### Testing

Use mock data from `tests/mock-data/khqr-responses.json`:

**Test Scenario 1: Successful settlement**
```bash
# 1. Generate KHQR (G05)
# 2. Customer pays via mobile app
# 3. Poll Bakong API
GET https://api.bakong.nbc.gov.kh/v1/settlement/check?md5_hash=5f4dcc3b...

Expected Response (after ~3 seconds):
{
  "status": "settled",
  "transaction_id": "BKG-2025-TXN-789012"
}

Expected Database Updates:
- settlements record created
- payment_intents.payment_status = 'captured'
- orders.order_status = 'paid'
```

**Test Scenario 2: Payment timeout**
```bash
# 1. Generate KHQR (G05)
# 2. Wait 15+ minutes without payment
# 3. Polling detects expiry

Expected Database Updates:
- payment_intents.payment_status = 'expired'
- orders.order_status = 'cancelled'
```

**Test Scenario 3: Failed payment**
```bash
# Customer attempts payment with insufficient funds

Expected Bakong Response:
{
  "status": "failed",
  "error_code": "INSUFFICIENT_FUNDS"
}

Expected Action:
- Notify customer
- Keep QR active (customer can retry)
```

### Related Documentation

- [Bakong Settlement API](https://bakong.nbc.gov.kh/docs/settlement)
- [Bakong Webhooks](https://bakong.nbc.gov.kh/docs/webhooks)
- G05 - KHQR Generation (provides MD5 hash)
- G08 - Fulfillment (triggered on settlement)
- Payment Flow Test: `tests/test-scenarios/payment-flow.md`
