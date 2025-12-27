# Payment Flow Test Scenario

This document provides detailed test scenarios for the payment integration using Cambodia's Bakong (KHQR) system with CamDX interoperability layer.

## Overview

The Telegraph payment flow integrates three Cambodia GaaP layers:
- **Layer 1 (Identity):** CamDigiKey verification
- **Layer 2 (Interoperability):** CamDX policy decisions
- **Layer 3 (Payments):** Bakong KHQR settlement

## Test Scenario 1: Band A Payment (≤ $10) - Anonymous

**Objective:** Test frictionless payment for small purchases without identity verification.

### Prerequisites
- Customer: Anonymous user (no CamDigiKey)
- Product: P001 (Num Pang Sandwich - $3.50)
- Quantity: 2 ($7.00 total)
- Expected Band: A

### Step-by-Step Test

#### 1. Policy Check
**Workflow:** 02 - Identity & Policy
**Input:**
```json
{
  "customer_id": 1,
  "telegram_user_id": 123456789,
  "total_amount": 7.00,
  "currency": "USD"
}
```
**Expected CamDX API Call:**
```
POST https://camdx.gov.kh/api/v1/policy/check
{
  "identity_level": "anonymous",
  "amount": 7.00,
  "currency": "USD",
  "transaction_type": "e-commerce"
}
```
**Expected Response:**
```json
{
  "decision": "allowed",
  "amount_band": "A",
  "identity_required": false,
  "max_transaction_limit": 10.00
}
```
**Database Check:**
- `payment_intents.amount_band` = 'A'
- `payment_intents.identity_level` = 'anonymous'
- `payment_intents.policy_decision` = 'allowed'

#### 2. KHQR Generation
**Workflow:** 04 - CamDX Payment Intent
**Input:**
```json
{
  "order_id": "ORD-20250101-0001",
  "amount": 7.00,
  "currency": "USD",
  "merchant_id": "numpang-express-001"
}
```
**Expected Bakong API Call:**
```
POST https://api.bakong.nbc.gov.kh/v1/khqr/generate
{
  "amount": "7.00",
  "currency": "USD",
  "merchant_id": "khqr.aba@ababank",
  "merchant_name": "Num Pang Express",
  "city": "Phnom Penh",
  "reference": "ORD-20250101-0001"
}
```
**Expected Response:**
```json
{
  "qr_string": "00020101021230820016khqr.aba@ababank520441115802KH5916Num Pang Express6011Phnom Penh62410109ORD-00011708PI-000016304A1B2",
  "qr_image": "data:image/png;base64,iVBORw0KG...",
  "deeplink": "https://bakong.nbc.gov.kh/qr?data=...",
  "md5_hash": "5f4dcc3b5aa765d61d8327deb882cf99"
}
```
**Database Check:**
- `payment_intents.khqr_string` populated
- `payment_intents.khqr_deeplink` populated
- `payment_intents.khqr_md5_hash` populated
- `payment_intents.expires_at` = now + 15 minutes

#### 3. Customer Payment
**Action:** Customer scans KHQR with:
- ABA Mobile app
- Wing app
- Pi Pay app
- Any Bakong-enabled app

**Expected:** Payment submitted to Bakong network

#### 4. Settlement Detection
**Workflow:** 05 - Bakong Settlement (polling every 3 seconds)
**Expected Bakong API Call (polling):**
```
GET https://api.bakong.nbc.gov.kh/v1/settlement/check
{
  "md5_hash": "5f4dcc3b5aa765d61d8327deb882cf99"
}
```
**Expected Response (after payment):**
```json
{
  "status": "settled",
  "transaction_id": "BKG-2025-TXN-789012",
  "amount": 7.00,
  "currency": "USD",
  "settled_at": "2025-01-01T10:05:23Z",
  "settlement_time": 3.2
}
```
**Database Check:**
- `settlements` record created
- `settlements.bakong_tx_id` = "BKG-2025-TXN-789012"
- `settlements.settlement_status` = 'verified'
- `settlements.verified_at` timestamp set
- `payment_intents.payment_status` → 'captured'
- `payment_intents.settled_at` timestamp set

#### 5. Order Status Update
**Workflow:** 06 - Orchestrator
**Database Check:**
- `orders.order_status` → 'paid'

**Expected Telegram Message:**
```
💰 Payment received! ($7.00)

Your order is being prepared.
Order ID: ORD-20250101-0001

Estimated time: 5 minutes
```

---

## Test Scenario 2: Band B Payment ($10-100) - Basic Verification

**Objective:** Test payment with basic identity verification.

### Prerequisites
- Customer: Basic verified user
- Product: P003 (Lunch Set - $45)
- Quantity: 1
- Expected Band: B

### Step-by-Step Test

#### 1. Policy Check
**Expected CamDX Response:**
```json
{
  "decision": "allowed",
  "amount_band": "B",
  "identity_required": true,
  "required_level": "basic",
  "max_transaction_limit": 100.00
}
```

#### 2. Identity Verification (if not already verified)
**Workflow:** 02 - Identity & Policy
**Telegram Message:**
```
⚠️ Basic verification required for this purchase.

Please verify your phone number:
[Send OTP Button]
```

**Action:** Customer verifies phone via OTP
**Database Check:**
- `customers.identity_level` → 'basic'
- `customers.phone` recorded

#### 3-5. Same as Scenario 1
Follow KHQR generation and settlement flow, but:
- `expires_at` = now + 20 minutes (longer for Band B)
- `payment_intents.identity_level` = 'basic'

---

## Test Scenario 3: Band C Payment ($100-1K) - Full Verification

**Objective:** Test payment requiring CamDigiKey verification.

### Prerequisites
- Customer: Initially anonymous
- Product: P004 (Party Catering - $250)
- Quantity: 1
- Expected Band: C

### Step-by-Step Test

#### 1. Policy Check - BLOCKED
**Expected CamDX Response:**
```json
{
  "decision": "blocked",
  "amount_band": "C",
  "identity_required": true,
  "required_level": "verified",
  "current_level": "anonymous",
  "message": "CamDigiKey verification required for amount band C"
}
```

**Telegram Message:**
```
⚠️ Identity Verification Required

Amount: $250 (Band C)
Current level: Anonymous
Required: Verified (CamDigiKey)

You must verify your identity with CamDigiKey to complete this purchase.

[Verify with CamDigiKey Button]
```

#### 2. CamDigiKey Verification
**Workflow:** 02 - Identity & Policy
**Action:** Customer taps "Verify with CamDigiKey"

**Expected CamDigiKey API Call:**
```
POST https://camdigikey.gov.kh/api/v1/verify/initiate
{
  "user_id": "telegram:123456789",
  "verification_level": "verified",
  "purpose": "e-commerce_transaction",
  "return_url": "https://automation.omnidm.ai/webhook/camdigi"
}
```

**Expected Response:**
```json
{
  "verification_id": "VER-20250101-001",
  "verification_url": "https://camdigikey.gov.kh/verify?id=VER-20250101-001",
  "qr_code": "data:image/png;base64,iVBORw0...",
  "expires_at": "2025-01-01T10:20:00Z"
}
```

**Telegram Message:**
```
🔐 CamDigiKey Verification

Scan this QR with your CamDigiKey app:
[QR Code]

Or tap: [Open CamDigiKey]

⏰ Verification link expires in 10 minutes
```

#### 3. Verification Callback
**Workflow:** 02 - Identity & Policy (webhook)
**Expected Webhook:**
```
POST https://automation.omnidm.ai/webhook/camdigi
{
  "verification_id": "VER-20250101-001",
  "status": "verified",
  "identity_level": "verified",
  "camdigi_key_id": "CDKH-VER-2024-001234",
  "attributes": {
    "name": "Dara Rath",
    "verified_at": "2025-01-01T10:15:00Z"
  }
}
```

**Database Check:**
- `customers.identity_level` → 'verified'
- `customers.camdigi_key_id` = "CDKH-VER-2024-001234"

**Telegram Message:**
```
✅ Identity Verified!

Name: Dara Rath
Level: Verified
CamDigiKey ID: CDKH-VER-2024-001234

You can now complete your order.
```

#### 4. Retry Policy Check
**Expected CamDX Response:**
```json
{
  "decision": "allowed",
  "amount_band": "C",
  "identity_required": true,
  "required_level": "verified",
  "current_level": "verified"
}
```

#### 5-7. Continue Payment Flow
Follow KHQR generation and settlement, with:
- `expires_at` = now + 30 minutes (Band C)
- `payment_intents.identity_level` = 'verified'

---

## Test Scenario 4: Band D Payment (> $1K) - High Assurance

**Objective:** Test highest security level for large transactions.

### Prerequisites
- Customer: High assurance verified
- Product: P005 (Wedding Catering - $2,500)
- Expected Band: D

### Requirements
- **Identity Level:** high_assurance (biometric verification)
- **Additional Checks:** Enhanced due diligence
- **Payment Timeout:** 60 minutes
- **Settlement:** Manual review may apply

### Key Differences from Band C
- Requires biometric verification in CamDigiKey
- May trigger additional fraud checks
- Merchant receives funds after T+1 settlement (not immediate)

---

## Test Scenario 5: Payment Failure Handling

### 5a. Payment Timeout
**Action:** Customer doesn't pay within expiry window
**Expected:** After 15 minutes (Band A)

**Workflow:** 05 - Bakong Settlement (timeout)
**Database Check:**
- `payment_intents.payment_status` → 'expired'
- `orders.order_status` → 'cancelled'

**Telegram Message:**
```
⏰ Payment Expired

Order ID: ORD-20250101-0001
Status: Cancelled

The payment window has closed. Start a new order with /order
```

### 5b. Insufficient Funds
**Scenario:** Customer's Bakong wallet has insufficient balance
**Expected Bakong Response:**
```json
{
  "status": "failed",
  "error_code": "INSUFFICIENT_FUNDS",
  "message": "Account balance too low"
}
```

**Telegram Message:**
```
❌ Payment Failed

Reason: Insufficient funds

Please add funds to your Bakong wallet and try again.
The QR code is still valid for 10 more minutes.
```

### 5c. Network Error
**Scenario:** Bakong API temporarily unavailable
**Expected Behavior:**
- Settlement polling continues
- Exponential backoff (3s → 6s → 12s)
- Max retries: 20 times
- After max retries: Manual verification required

---

## Verification Checklist

For each payment test:

- [ ] Correct amount_band assigned based on total
- [ ] Identity verification enforced per band requirements
- [ ] KHQR generated successfully and is scannable
- [ ] KHQR string follows EMV standard format
- [ ] MD5 hash matches KHQR string
- [ ] Deeplink opens in Bakong apps
- [ ] Settlement detected within 10 seconds of payment
- [ ] Settlement amount matches order total exactly
- [ ] Bakong transaction ID recorded
- [ ] All timestamps accurate (created_at, expires_at, settled_at)
- [ ] Audit logs created for each step
- [ ] Error messages clear and actionable
- [ ] Retry logic works for transient failures

## Performance Benchmarks

| Metric | Target | Measured |
|--------|--------|----------|
| KHQR Generation | < 2s | ___ |
| Settlement Detection | < 10s | ___ |
| Policy Check | < 500ms | ___ |
| CamDigiKey Verification | < 5s | ___ |
| End-to-end (order to settlement) | < 30s | ___ |

## Security Verification

- [ ] No API keys exposed in logs
- [ ] KHQR strings expire properly
- [ ] Identity verification cannot be bypassed
- [ ] Amount band enforcement cannot be circumvented
- [ ] Settlement verification cryptographically secure
- [ ] Webhook callbacks authenticated
- [ ] All sensitive data encrypted in transit

## Common Issues

### Issue 1: "KHQR generation failed"
**Cause:** Invalid Bakong API credentials
**Fix:** Check n8n credentials for Bakong API key

### Issue 2: "Settlement never detected"
**Cause:** Webhook not configured or polling stopped
**Fix:**
1. Check Workflow 05 is active
2. Verify webhook URL registered with Bakong
3. Check polling schedule (should be every 3s)

### Issue 3: "Policy check returns 'blocked' for Band A"
**Cause:** CamDX API configuration error
**Fix:** Verify CamDX endpoint and credentials

### Issue 4: "CamDigiKey verification times out"
**Cause:** Return URL incorrect
**Fix:** Update webhook URL in CamDigiKey portal

## Mock Testing

Use the provided mock data in `tests/mock-data/khqr-responses.json` to test without actual Bakong API calls:

1. Enable "mock mode" in Workflow 04
2. Replace Bakong API calls with mock responses
3. Verify all workflows handle responses correctly

## Production Readiness

Before going live:
- [ ] All test scenarios pass
- [ ] Performance benchmarks met
- [ ] Security verification complete
- [ ] Bakong merchant account verified
- [ ] CamDX integration certified
- [ ] CamDigiKey integration approved
- [ ] Error handling tested
- [ ] Monitoring and alerts configured
