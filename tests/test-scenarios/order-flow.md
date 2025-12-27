# Order Flow Test Scenario

This document provides step-by-step test scenarios for the complete order flow in the Telegraph E-Commerce platform.

## Test Scenario 1: Simple Order (Band A - Anonymous User)

**Objective:** Test basic order creation for small purchases by anonymous users.

**Prerequisites:**
- All workflows deployed to automation.omnidm.ai
- Database initialized with schema.sql
- Telegram bot active and responding

### Step-by-Step Test

#### 1. Start Conversation
**Action:** Send `/start` to the Telegram bot
**Expected Workflow:** 01 - Channel Ingress
**Expected Response:**
```
Welcome to Num Pang Express! 🥖

What would you like to do?
- /menu - View our menu
- /order - Start an order
- /help - Get help
```

#### 2. View Menu
**Action:** Send `/menu` or `Show menu`
**Expected Workflow:** 01 - Channel Ingress → Product Catalog Lookup
**Expected Response:**
```
🍴 Menu

A. Individual Items
P001 - Num Pang Sandwich - $3.50
P002 - Coffee + Pastry Set - $5.00

B. Family Meals
P003 - Lunch Set (4 people) - $45.00

C. Catering
P004 - Party Catering - $250.00

D. Premium Catering
P005 - Wedding Catering - $2,500.00

Reply with product code to order (e.g., P001)
```

#### 3. Select Product
**Action:** Send `P001`
**Expected Workflow:** 02 - Identity & Policy (identity check)
**Expected Database:**
- Customer record created in `customers` table
- `identity_level` = 'anonymous'
- `telegram_user_id` recorded

#### 4. Specify Quantity
**Action:** Send `2`
**Expected Workflow:** 03 - Intent Builder
**Expected Response:**
```
Order Summary:
- 2x Num Pang Sandwich @ $3.50 = $7.00

Total: $7.00

Confirm order? (Yes/No)
```
**Expected Database:**
- Order created in `orders` table
- `order_status` = 'pending'
- `amount_band` = 'A'
- Record in `order_items` table

#### 5. Confirm Order
**Action:** Send `Yes` or tap "Confirm" button
**Expected Workflow:** 04 - CamDX Payment Intent
**Expected Response:**
```
✅ Order confirmed!
Order ID: ORD-20250101-0001

Please scan QR code to pay $7.00:
[KHQR QR Code Image]

Or use this link: [Bakong Deeplink]

⏰ Payment expires in 15 minutes
```
**Expected Database:**
- `orders.order_status` → 'confirmed'
- Payment intent created in `payment_intents` table
- `payment_status` = 'pending'
- `khqr_string`, `khqr_deeplink`, `khqr_md5_hash` populated
- `expires_at` = now + 15 minutes

#### 6. Customer Scans and Pays
**Action:** Customer scans KHQR with Bakong app and completes payment
**Expected Workflow:** 05 - Bakong Settlement (polling for payment)
**Expected Timeline:** Settlement detected within 5-10 seconds
**Expected Response:**
```
💰 Payment received!

Your order is being prepared.
Estimated time: 5 minutes

We'll notify you when it's ready.
```
**Expected Database:**
- `payment_intents.payment_status` → 'captured'
- Settlement record created in `settlements` table
- `settlement_status` = 'verified'
- `bakong_tx_id` recorded
- `orders.order_status` → 'paid'

#### 7. Order Fulfillment
**Action:** (Automatic) Merchant marks order as ready
**Expected Workflow:** 07 - Grab Fulfillment
**Expected Response:**
```
🚗 Your order is ready for delivery!

Driver assigned: Sopheak
ETA: 15 minutes

Track delivery: [Link]
```
**Expected Database:**
- Fulfillment record created in `fulfillments` table
- `grab_delivery_id` recorded
- `driver_assigned` = true
- `orders.order_status` → 'fulfilled'

#### 8. Delivery Complete
**Action:** Driver delivers order
**Expected Workflow:** 07 - Grab Fulfillment (webhook callback)
**Expected Response:**
```
✅ Order delivered!

Thank you for your order.
Rate your experience: ⭐⭐⭐⭐⭐
```
**Expected Database:**
- `orders.order_status` → 'completed'
- `completed_at` timestamp set
- `fulfillments.actual_delivery` timestamp set

#### 9. Audit Trail
**Action:** (Automatic throughout flow)
**Expected Workflow:** 08 - CamDL Audit
**Expected Database:**
- Multiple entries in `audit_logs` table:
  - `order.created`
  - `order.confirmed`
  - `payment.initiated`
  - `payment.captured`
  - `order.fulfilled`
  - `order.completed`
- Each with `event_hash` (SHA256)
- `camdl_block` and `camdl_tx_hash` when anchored to blockchain

---

## Test Scenario 2: High-Value Order (Band C - Requires Verification)

**Objective:** Test identity verification requirement for Band C purchases.

### Step-by-Step Test

#### 1-3. Same as Scenario 1
Follow steps 1-3 from Scenario 1.

#### 4. Select High-Value Product
**Action:** Send `P004` (Party Catering - $250)
**Expected Workflow:** 02 - Identity & Policy
**Expected Response:**
```
⚠️ Identity Verification Required

This purchase requires identity verification.

Amount: $250 (Band C)
Current identity: Anonymous
Required: Verified

Verify with CamDigiKey? (Yes/No)
```

#### 5. Initiate Verification
**Action:** Send `Yes` or `/verify`
**Expected Workflow:** 02 - Identity & Policy → CamDigiKey Integration
**Expected Response:**
```
🔐 Identity Verification

Click to verify with CamDigiKey:
[Verification Link]

This will securely verify your identity using Cambodia's national digital identity system.
```

#### 6. Complete CamDigiKey Verification
**Action:** Customer completes verification in CamDigiKey app
**Expected Workflow:** 02 - Identity & Policy (webhook callback)
**Expected Response:**
```
✅ Identity verified!

You can now proceed with high-value purchases.
Verification level: Verified

Let's continue with your order...
```
**Expected Database:**
- `customers.identity_level` → 'verified'
- `customers.camdigi_key_id` populated

#### 7-9. Continue Order
Follow steps 4-9 from Scenario 1, but with:
- `amount_band` = 'C'
- Longer `expires_at` (30 minutes for Band C)

---

## Test Scenario 3: Order Cancellation

**Objective:** Test order cancellation before payment.

### Steps

#### 1-4. Create Order
Follow Scenario 1 steps 1-4.

#### 5. Cancel Order
**Action:** Send `/cancel` or `Cancel order`
**Expected Workflow:** 01 - Channel Ingress → Order Management
**Expected Response:**
```
❌ Order cancelled

Order ID: ORD-20250101-0001
Status: Cancelled

Start a new order anytime with /order
```
**Expected Database:**
- `orders.order_status` → 'cancelled'
- `payment_intents.payment_status` → 'expired' (if created)
- Audit log entry: `order.cancelled`

---

## Test Scenario 4: Payment Timeout

**Objective:** Test automatic expiry of unpaid orders.

### Steps

#### 1-5. Create Order with Payment Intent
Follow Scenario 1 steps 1-5.

#### 6. Wait for Timeout
**Action:** Wait 15+ minutes without paying
**Expected Workflow:** 05 - Bakong Settlement (timeout handler)
**Expected Response:**
```
⏰ Payment expired

Order ID: ORD-20250101-0001
Status: Expired

Start a new order with /order
```
**Expected Database:**
- `payment_intents.payment_status` → 'expired'
- `orders.order_status` → 'cancelled'
- Audit log entry: `payment.expired`

---

## Test Scenario 5: Delivery Address Update

**Objective:** Test delivery address modification after order confirmation.

### Steps

#### 1-6. Create and Pay for Order
Follow Scenario 1 steps 1-6.

#### 7. Update Delivery Address
**Action:** Send `Update address: #123, St 240, Phnom Penh`
**Expected Workflow:** 07 - Grab Fulfillment
**Expected Response:**
```
📍 Delivery address updated

New address: #123, St 240, Phnom Penh

Updated ETA: 20 minutes
```
**Expected Database:**
- `fulfillments.delivery_address` updated
- `fulfillments.estimated_delivery` recalculated

---

## Verification Checklist

For each test scenario, verify:

- [ ] All expected workflows triggered in correct order
- [ ] All database tables updated correctly
- [ ] Telegram bot responds with expected messages
- [ ] Audit logs created for all events
- [ ] No errors in n8n execution logs
- [ ] Proper error handling for edge cases
- [ ] KHQR codes valid and scannable
- [ ] Settlement detection working within SLA (< 10 seconds)
- [ ] GaaP policy decisions enforced correctly
- [ ] Identity verification gates working

## Performance Benchmarks

Expected response times:
- Message processing: < 500ms
- KHQR generation: < 2 seconds
- Settlement detection: < 10 seconds
- Delivery assignment: < 30 seconds

## Common Issues and Fixes

### Issue 1: "Identity verification required" for Band A
**Cause:** Incorrect amount_band classification
**Fix:** Check product catalog `amount_band` values

### Issue 2: KHQR not displaying
**Cause:** CamDX integration error
**Fix:** Check n8n credentials for CamDX API

### Issue 3: Settlement not detected
**Cause:** Polling stopped or webhook not configured
**Fix:** Check Workflow 05 active status and webhook URL

### Issue 4: Delivery not assigned
**Cause:** Grab API credentials invalid
**Fix:** Regenerate Grab API key in n8n credentials
