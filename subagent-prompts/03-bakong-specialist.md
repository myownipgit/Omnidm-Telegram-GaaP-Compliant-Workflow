# Bakong Specialist

## Subagent Role

**Expert in Bakong payment system integration, KHQR generation, and settlement verification.**

This subagent specializes in:
- Bakong API integration (KHQR generation, settlement polling)
- KHQR standard (EMVCo QR code specification)
- Real-time settlement verification
- Multi-bank payment rail support (ABA, Wing, Pi Pay, etc.)
- Payment timeout and retry logic

---

## Invocation Pattern

Copy-paste this prompt to invoke the Bakong Specialist:

```
You are a Bakong Payment Integration Specialist with expertise in Cambodia's
national payment system and KHQR standards. Your role is to design and implement
payment workflows using Bakong APIs and KHQR QR codes.

I need help with: [DESCRIBE YOUR PAYMENT REQUIREMENT]

Current context:
- Payment types: [e.g., one-time, recurring, batch]
- Amount range: [e.g., $1-$1000]
- Settlement requirements: [e.g., instant, T+1]
- Integration platform: [e.g., n8n, custom backend]

Please provide:
1. Bakong API integration design (KHQR generation, settlement)
2. Payment workflow (generation → display → polling → confirmation)
3. Timeout and expiry handling
4. Error scenarios and retry logic
5. Multi-bank compatibility considerations
```

---

## Input Checklist

Before invoking, gather this information:

- [ ] **Payment Requirements**
  - Payment types? (one-time, recurring, installments)
  - Amount range? (min/max)
  - Currency? (USD, KHR, both)
  - Settlement speed? (instant, T+1, T+2)

- [ ] **Merchant Details**
  - Bakong merchant account registered?
  - Merchant KHQR ID (e.g., `khqr.aba@ababank`)
  - Settlement bank account
  - Merchant category code (MCC)

- [ ] **Technical Context**
  - Platform (n8n workflows, API, mobile app)
  - QR display method (image, deeplink, both)
  - Settlement verification approach (webhook, polling)

- [ ] **User Experience**
  - Where does user scan QR? (mobile banking app)
  - Payment timeout acceptable? (15 min, 30 min, 60 min)
  - What happens after payment? (auto-fulfill, manual review)

- [ ] **Compliance**
  - NBC merchant verification complete?
  - Transaction logging requirements
  - Refund policy

---

## Expected Deliverables

The Bakong Specialist will provide:

1. **KHQR Generation Workflow**
   ```javascript
   // Bakong API Request
   POST https://api.bakong.nbc.gov.kh/v1/khqr/generate
   {
     "merchant_id": "khqr.aba@ababank",
     "merchant_name": "Num Pang Express",
     "merchant_city": "Phnom Penh",
     "mcc": "5814",  // Fast food
     "amount": "7.00",
     "currency": "USD",
     "reference": {
       "order_id": "ORD-20250101-0001",
       "intent_id": "PI-20250101-0001"
     },
     "ttl_seconds": 900  // 15 minutes
   }

   // Response
   {
     "qr_string": "00020101021230820016khqr.aba@ababank...",
     "qr_image": "data:image/png;base64,iVBORw0KG...",
     "deeplink": "https://bakong.nbc.gov.kh/qr?data=...",
     "md5_hash": "5f4dcc3b5aa765d61d8327deb882cf99",
     "expires_at": "2025-01-01T10:15:00Z"
   }
   ```

2. **Settlement Polling Workflow**
   - Polling interval (3 seconds)
   - Timeout detection
   - Settlement confirmation handling

3. **n8n Workflow Design**
   - HTTP Request nodes for Bakong API
   - Cron nodes for polling
   - Switch nodes for payment status routing
   - Database nodes for payment_intents updates

4. **QR Code Display Options**
   - Base64 PNG image (Telegram photo)
   - Bakong deeplink (clickable button)
   - Combined approach (both)

5. **Error Handling Guide**
   - Payment timeout
   - Insufficient funds
   - QR expired
   - Duplicate payments
   - Network errors

---

## Skills to Use

When working with the Bakong Specialist, leverage:

- **n8n-node-configuration** - For HTTP Request and Cron nodes
- **n8n-code-javascript** - For MD5 hash calculation, QR validation
- **n8n-workflow-patterns** - For polling and webhook patterns

---

## Common Patterns

### Pattern 1: Dynamic KHQR with Polling

**Scenario:** Generate KHQR for order, poll for settlement every 3 seconds

**Flow:**
```
1. Order confirmed → amount = $7.00
2. Call Bakong API → Generate KHQR
3. Store md5_hash in payment_intents table
4. Send QR to customer via Telegram
5. Start polling (every 3 seconds):
   GET /settlement/check?md5_hash=5f4dcc3b...
6. If status = pending → Continue polling
7. If status = settled → Update order, trigger fulfillment
8. If timeout (15 min) → Mark as expired, notify customer
```

**n8n Nodes:**
- HTTP Request (KHQR generation)
- PostgreSQL (store md5_hash)
- Telegram Send Photo
- Cron (polling every 3s)
- Switch (status routing)
- Webhook (Bakong callback, optional)

### Pattern 2: KHQR with Webhook

**Scenario:** Use webhook instead of polling for instant notification

**Flow:**
```
1. Register webhook with Bakong:
   POST /webhooks/register
   {
     "url": "https://automation.omnidm.ai/webhook/bakong",
     "events": ["settlement.completed"]
   }

2. Generate KHQR (same as Pattern 1)

3. Customer pays → Bakong sends webhook:
   POST https://automation.omnidm.ai/webhook/bakong
   {
     "event": "settlement.completed",
     "md5_hash": "5f4dcc3b...",
     "transaction_id": "BKG-2025-TXN-789012",
     "amount": 7.00,
     "settled_at": "2025-01-01T10:05:23Z",
     "signature": "sha256=abc123..."
   }

4. Verify HMAC signature
5. Update payment_intents → payment_status = captured
6. Trigger fulfillment
```

### Pattern 3: Batch KHQR for Invoices

**Scenario:** Generate multiple QR codes for monthly invoices

**Flow:**
```
1. Generate batch of invoices
2. For each invoice:
   - Create payment_intent record
   - Generate unique KHQR (include invoice_id in reference)
   - Set TTL = 30 days (longer for invoices)
3. Send invoices via email/SMS with embedded QR
4. Poll settlements in background
5. Mark invoice as paid when settled
```

---

## Example Usage

### Example 1: Simple One-Time Payment

**Prompt:**
```
I need to generate a KHQR code for a $3.50 sandwich order. Customer will pay
via their mobile banking app. Show me the complete n8n workflow.
```

**Expected Response:**
```
KHQR Generation for $3.50 Payment:

Step 1: Generate KHQR via Bakong API

n8n HTTP Request Node:
- Method: POST
- URL: https://api.bakong.nbc.gov.kh/v1/khqr/generate
- Authentication: API Key (from credentials)
- Body:
{
  "merchant_id": "{{ $('Config').item.json.merchant_khqr_id }}",
  "merchant_name": "Num Pang Express",
  "merchant_city": "Phnom Penh",
  "mcc": "5814",
  "amount": "3.50",
  "currency": "USD",
  "reference": {
    "order_id": "{{ $json.order_id }}",
    "intent_id": "{{ $json.intent_id }}"
  },
  "bill_number": "{{ $json.order_id }}",
  "ttl_seconds": 900
}

Step 2: Store MD5 Hash in Database

PostgreSQL Node:
UPDATE payment_intents
SET khqr_string = '{{ $json.qr_string }}',
    khqr_deeplink = '{{ $json.deeplink }}',
    khqr_md5_hash = '{{ $json.md5_hash }}',
    expires_at = '{{ $json.expires_at }}'
WHERE intent_id = '{{ $('Intent Builder').item.json.intent_id }}';

Step 3: Send QR to Customer

Telegram Send Photo Node:
- Chat ID: {{ $json.telegram_chat_id }}
- Photo: {{ $json.qr_image }}
- Caption:
"💰 Pay $3.50

Scan this QR code with your mobile banking app:
✅ ABA Mobile
✅ Wing Money
✅ Pi Pay
✅ Any Bakong app

Or tap: [Bakong deeplink button]

⏰ Payment expires in 15 minutes"

- Inline Keyboard:
[
  [{ "text": "Open Bakong", "url": "{{ $json.deeplink }}" }]
]

Step 4: Start Settlement Polling

Cron Node:
- Trigger: Every 3 seconds
- Condition: Only while payment_status = pending AND expires_at > now()

Step 5: Check Settlement Status

HTTP Request Node:
- Method: GET
- URL: https://api.bakong.nbc.gov.kh/v1/settlement/check
- Query: md5_hash={{ $('Database').item.json.khqr_md5_hash }}

Step 6: Handle Settlement Response

Switch Node:
- Case 1: status = "settled"
  → Update payment_intents.payment_status = captured
  → Update orders.order_status = paid
  → Send Telegram: "Payment received!"
  → Trigger fulfillment workflow

- Case 2: status = "pending"
  → Continue polling

- Case 3: status = "failed"
  → Update payment_intents.payment_status = failed
  → Send Telegram: "Payment failed. Please try again."

- Case 4: Timeout (15 min elapsed)
  → Update payment_intents.payment_status = expired
  → Send Telegram: "Payment expired. Start a new order."

Database Schema:
CREATE TABLE payment_intents (
  intent_id VARCHAR(100) PRIMARY KEY,
  order_id VARCHAR(100),
  khqr_string TEXT,
  khqr_deeplink TEXT,
  khqr_md5_hash VARCHAR(100),
  payment_status payment_status DEFAULT 'pending',
  expires_at TIMESTAMP,
  created_at TIMESTAMP,
  settled_at TIMESTAMP
);
```

### Example 2: Recurring Payment (Monthly Subscription)

**Prompt:**
```
I need to set up recurring $10/month payments for a subscription service.
How do I use Bakong for this?
```

**Expected Response:**
```
Recurring Payment with Bakong (Standing Order):

Note: Bakong supports standing orders (KHQR recurring payments)

Setup Flow:

Step 1: Create Standing Order Request
POST https://api.bakong.nbc.gov.kh/v1/standing-orders
{
  "merchant_id": "khqr.aba@ababank",
  "payer_phone": "+855 12 345 678",
  "amount": "10.00",
  "currency": "USD",
  "frequency": "monthly",
  "start_date": "2025-01-01",
  "end_date": "2026-01-01",  // 1 year
  "reference": "SUB-20250101-001"
}

Response:
{
  "standing_order_id": "SO-20250101-001",
  "authorization_qr": "data:image/png...",
  "status": "pending_authorization"
}

Step 2: Customer Authorizes Standing Order
- Send authorization QR to customer
- Customer scans with banking app
- Customer approves recurring payment

Webhook when authorized:
{
  "event": "standing_order.authorized",
  "standing_order_id": "SO-20250101-001",
  "status": "active"
}

Step 3: Monthly Automatic Charges
Bakong automatically charges customer each month
Webhooks sent for each charge:
{
  "event": "standing_order.charged",
  "standing_order_id": "SO-20250101-001",
  "charge_date": "2025-02-01",
  "amount": 10.00,
  "status": "settled"
}

Step 4: Handle Charge Webhooks
n8n Webhook Trigger receives charge notification
→ Update subscription record
→ Send invoice/receipt to customer
→ Extend service for another month

Cancellation:
DELETE https://api.bakong.nbc.gov.kh/v1/standing-orders/SO-20250101-001

Alternative (if standing orders not available):
1. Generate new KHQR each month
2. Send payment reminder via Telegram
3. Customer manually scans and pays
4. Verify settlement before extending service
```

---

## Best Practices

1. **Always Include Reference IDs**
   - order_id in KHQR reference
   - Helps reconcile payments
   - Critical for dispute resolution

2. **Set Appropriate TTL**
   - Band A: 900s (15 min)
   - Band B: 1200s (20 min)
   - Band C/D: 1800s-3600s (30-60 min)
   - Invoices: 2592000s (30 days)

3. **Store MD5 Hash Securely**
   - Primary key for settlement matching
   - Index this field for fast lookups
   - Never expose in public APIs

4. **Handle Duplicate Payments**
   - Check if already settled before processing
   - Implement idempotency with settlement_id
   - Auto-refund duplicates

5. **Test with All Banks**
   - ABA, Wing, Pi Pay, Vattanac, Chip Mong
   - Different apps may display QR differently
   - Verify deeplink works across all

6. **Monitor Settlement Speed**
   - Typical: 3-5 seconds
   - SLA: < 10 seconds
   - Alert if > 30 seconds

---

## Common Issues & Solutions

**Issue 1: QR code not scannable**
- **Cause:** Invalid QR string format, size too small
- **Solution:** Verify EMVCo compliance, minimum 200x200px

**Issue 2: Settlement never detected**
- **Cause:** MD5 hash mismatch, polling stopped
- **Solution:** Verify hash calculation, check cron active

**Issue 3: Duplicate payment**
- **Cause:** User scans QR twice
- **Solution:** Check settlement_id, auto-refund if duplicate

**Issue 4: Amount mismatch**
- **Cause:** User paid different amount
- **Solution:** Accept partial payments or reject and refund

**Issue 5: Expired QR still accepting payments**
- **Cause:** TTL not enforced by Bakong
- **Solution:** Server-side expiry check, reject late payments

---

## KHQR Format Reference

```
EMVCo QR Code Specification:
00 - Payload Format Indicator: "01"
01 - Point of Initiation: "12" (dynamic)
30 - Merchant Account: khqr.aba@ababank
52 - MCC: "5814" (fast food)
53 - Currency: "840" (USD) or "116" (KHR)
54 - Amount: "7.00"
58 - Country: "KH"
59 - Merchant Name: "Num Pang Express"
60 - City: "Phnom Penh"
62 - Additional Data: order reference
63 - CRC: checksum

Example:
00020101021230820016khqr.aba@ababank520441115802KH5916Num Pang Express6011Phnom Penh62410109ORD-00011708PI-000016304A1B2
```

---

## Related Documentation

- Bakong API: `https://bakong.nbc.gov.kh/docs`
- KHQR Workflow: `/workflows/g05-khqr-generation/`
- Settlement Workflow: `/workflows/g07-settlement/`
- Testing Guide: `/tests/test-scenarios/payment-flow.md`

---

**Last Updated:** December 2024
**Maintained by:** OmniDM.ai Payments Team
