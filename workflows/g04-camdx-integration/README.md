# G04 - CamDX Integration

## Purpose

Publishes payment intents to Cambodia Digital Exchange (CamDX) for interoperable payment processing. Creates standardized payment records that can be settled via multiple payment rails (Bakong, ABA, Wing, etc.).

## Workflows in This Group

| Workflow Name | Version | Status | File |
|---------------|---------|--------|------|
| [KH.GaaS] 04 - CamDX Integration | v1 | Active | G04.CamDX.Integration.v1.json |

## Integration Points

### Upstream
- **G03 - Intent Builder** - Receives confirmed orders with amount and customer details

### Downstream
- **CamDX API** - Publishes payment intent for routing
- **G05 - KHQR Generation** - Receives CamDX correlation ID for KHQR creation
- **Database (payment_intents)** - Persists intent data
- **G09 - Audit** - Logs payment intent events

## GaaP Compliance Layers

| Layer | Purpose | Implementation |
|-------|---------|----------------|
| **L2 - Interoperability** | CamDX payment routing | Intent publishing, correlation ID tracking |
| **L3 - Payments** | Payment rail abstraction | Multi-provider support (Bakong, ABA, Wing) |
| **L4 - Compliance** | Payment audit trail | Intent creation logged |

## Quick Start Guide

### Prerequisites
- CamDX merchant account
- CamDX API credentials
- Database schema initialized (payment_intents table)

### Configuration Steps

1. **Set up CamDX Credentials**
   ```
   Credentials → Add Credential → HTTP Header Auth
   Name: camdx_api
   Header: X-CamDX-API-Key
   Value: YOUR_CAMDX_API_KEY
   ```

2. **Configure CamDX Merchant Profile**
   ```json
   {
     "merchant_id": "numpang-express-001",
     "merchant_name": "Num Pang Express",
     "settlement_account": "khqr.aba@ababank",
     "callback_url": "https://automation.omnidm.ai/webhook/camdx"
   }
   ```

3. **Import and Activate Workflow**
   - Upload `G04.CamDX.Integration.v1.json`
   - Link CamDX credentials
   - Verify database connection
   - Activate workflow

### CamDX Payment Intent Structure

**Request to CamDX:**
```json
{
  "intent_type": "payment",
  "merchant_id": "numpang-express-001",
  "order_reference": "ORD-20250101-0001",
  "amount": 7.00,
  "currency": "USD",
  "customer": {
    "customer_id": "123456789",
    "identity_level": "anonymous",
    "telegram_user_id": "123456789"
  },
  "policy": {
    "amount_band": "A",
    "verification_required": false
  },
  "settlement": {
    "preferred_rail": "bakong",
    "timeout_minutes": 15
  },
  "metadata": {
    "channel": "telegram",
    "product_id": "P001",
    "quantity": 2
  }
}
```

**Response from CamDX:**
```json
{
  "status": "accepted",
  "correlation_id": "CAMDX-2025-A-001234",
  "intent_id": "PI-20250101-0001",
  "routing": {
    "payment_rail": "bakong",
    "provider": "NBC",
    "method": "KHQR"
  },
  "expires_at": "2025-01-01T10:15:00Z",
  "created_at": "2025-01-01T10:00:00Z"
}
```

### Database Schema

**payment_intents Table:**
```sql
CREATE TABLE payment_intents (
  intent_id VARCHAR(100) PRIMARY KEY,
  order_id VARCHAR(100) REFERENCES orders,
  customer_id INT REFERENCES customers,
  merchant_id VARCHAR(50),
  amount DECIMAL(10, 2),
  currency VARCHAR(3) DEFAULT 'USD',
  payment_status payment_status DEFAULT 'pending',
  identity_level identity_level,
  amount_band amount_band,
  policy_decision VARCHAR(50),
  camdx_correlation_id VARCHAR(100),       -- From CamDX response
  khqr_string TEXT,
  khqr_deeplink TEXT,
  khqr_md5_hash VARCHAR(100),
  created_at TIMESTAMP,
  expires_at TIMESTAMP,
  authorized_at TIMESTAMP,
  settled_at TIMESTAMP
);
```

### Intent ID Format

Pattern: `PI-YYYYMMDD-NNNN`

Examples:
- `PI-20250101-0001` - First payment intent on Jan 1, 2025
- Matches order: `ORD-20250101-0001`

### Payment Status States

| Status | Description | Next States |
|--------|-------------|-------------|
| `pending` | Intent created, awaiting payment | authorized, expired, failed |
| `authorized` | Customer approved payment | captured |
| `captured` | Funds reserved | settled |
| `settled` | Merchant received funds | - |
| `failed` | Payment processing error | - |
| `expired` | Timeout exceeded | - |
| `refunded` | Funds returned to customer | - |

### CamDX Routing Logic

CamDX automatically selects the optimal payment rail based on:

1. **Amount Band**
   - Band A/B: KHQR (instant)
   - Band C: KHQR or bank transfer
   - Band D: Bank transfer or escrow

2. **Customer Preference**
   - Stored payment method
   - Previous transaction history

3. **Merchant Configuration**
   - Supported payment rails
   - Settlement preferences

4. **Network Availability**
   - Real-time rail status
   - Fallback options

### Correlation ID Tracking

The `camdx_correlation_id` is critical for:
- **Settlement verification** - Match payment to intent
- **Dispute resolution** - Track transaction across systems
- **Audit trail** - Link CamDX logs to internal records
- **Interoperability** - Reference in other GaaP layers

Always store and include in subsequent API calls.

### Webhook Configuration

CamDX sends status updates to your callback URL:

**Webhook Payload:**
```json
{
  "event": "payment.authorized",
  "correlation_id": "CAMDX-2025-A-001234",
  "intent_id": "PI-20250101-0001",
  "timestamp": "2025-01-01T10:05:23Z",
  "payment": {
    "status": "authorized",
    "amount": 7.00,
    "currency": "USD",
    "payment_rail": "bakong",
    "transaction_id": "BKG-2025-TXN-789012"
  }
}
```

**Webhook Security:**
- HMAC signature verification required
- IP whitelist: CamDX gateway IPs only
- HTTPS required

### Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `CAMDX_API_URL` | CamDX API endpoint | https://camdx.gov.kh/api/v1 |
| `CAMDX_WEBHOOK_SECRET` | Webhook signature key | Your HMAC secret |
| `CAMDX_WEBHOOK_URL` | Callback endpoint | https://automation.omnidm.ai/webhook/camdx |

### Monitoring

**Key Metrics:**
- Intent acceptance rate
- Average routing time
- Payment rail distribution
- CamDX API response time

**Alerts:**
- CamDX API errors > 1%
- Intent acceptance rate < 95%
- Correlation ID missing
- Webhook signature failures

### Troubleshooting

**Issue: "Intent rejected by CamDX"**
- Check merchant account status
- Verify API credentials
- Review intent structure (required fields)
- Check amount/currency validity

**Issue: Correlation ID not returned**
- Verify CamDX API response parsing
- Check for API errors in response
- Review n8n execution logs

**Issue: Webhook not received**
- Confirm webhook URL registered with CamDX
- Check HTTPS certificate validity
- Verify URL is publicly accessible
- Review webhook signature verification logic

**Issue: Wrong payment rail selected**
- Check merchant rail configuration in CamDX
- Verify amount band logic
- Review customer payment preferences

### Testing

Use mock data from `tests/mock-data/orders.json`:

**Test Scenario 1: Band A intent**
```bash
POST https://camdx.gov.kh/api/v1/intents
{
  "order_id": "ORD-20250101-0001",
  "amount": 7.00,
  "amount_band": "A",
  "identity_level": "anonymous"
}

Expected Response:
- correlation_id: "CAMDX-2025-A-XXXXXX"
- routing.payment_rail: "bakong"
- routing.method: "KHQR"
```

**Test Scenario 2: Band D intent (high-value)**
```bash
POST https://camdx.gov.kh/api/v1/intents
{
  "order_id": "ORD-20250101-0004",
  "amount": 2500.00,
  "amount_band": "D",
  "identity_level": "high_assurance"
}

Expected Response:
- correlation_id: "CAMDX-2025-D-XXXXXX"
- routing.payment_rail: "bank_transfer"
- additional verification steps
```

### Related Documentation

- [CamDX Integration Guide](https://camdx.gov.kh/docs/integration)
- [CamDX API Reference](https://camdx.gov.kh/api-docs)
- [Payment Rails Overview](https://camdx.gov.kh/docs/rails)
- G05 - KHQR Generation (next step)
- G07 - Settlement Verification (payment confirmation)
