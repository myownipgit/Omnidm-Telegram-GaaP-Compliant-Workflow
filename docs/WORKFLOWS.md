# Workflow Documentation

Complete documentation for all 9 GaaP-compliant workflows.

---

## Workflow 01: Channel Ingress

**Name:** `[KH.GaaS] omnidm.ai :: 01 Channel Ingress :: Telegram Num Pang Commerce (v1)`
**Type:** Orchestrator
**GaaP Layer:** 7 (Application)

### Purpose
Receives Telegram messages, normalizes into canonical `commerce.request` format, and routes by intent type.

### Nodes

| Node | Type | Purpose |
|------|------|---------|
| `ING: Telegram Trigger` | Telegram Trigger | Listens for incoming messages |
| `ING: Parse User Message` | Code | Extracts intent, builds commerce.request |
| `ING: Route By Intent` | Switch | Routes to welcome/menu/product selection |
| `ING: Send Welcome` | Telegram | Sends welcome message |
| `ING: Send Menu` | Telegram | Displays 5-item menu |
| `ING: Output to Next Workflow` | NoOp | Passes to WF-02 |

### Input
Telegram message from user

### Output
```json
{
  "commerce": {
    "request": {
      "request_id": "crq_tg_1737555123_abc",
      "channel": "telegram",
      "merchant_id": "numpang-express-001",
      "intent_hint": {
        "type": "select_product",
        "product_id": "P003"
      }
    }
  }
}
```

### Configuration Required
- **Telegram Credentials:** Add bot token in n8n UI
- **Webhook:** Ensure webhook is active

---

## Workflow 02: Identity & Policy

**Name:** `[KH.GaaS] omnidm.ai :: 02 Identity :: CamDX Policy Threshold Evaluator (v1)`
**Type:** Component
**GaaP Layer:** 1 (Identity)

### Purpose
Evaluates CamDX policy threshold matrix based on amount × identity level.

### Nodes

| Node | Type | Purpose |
|------|------|---------|
| `ID: Start` | Manual Trigger | Entry point |
| `ID: Lookup Product Price` | Code | Maps product_id to price/band |
| `ID: Evaluate Policy Matrix` | Code | Applies threshold decision logic |
| `ID: Check If Allowed` | IF | Routes allowed vs. step-up required |
| `ID: Approved` | NoOp | Continue to WF-03 |
| `ID: Requires Identity` | NoOp | Trigger CamDigiKey step-up |

### Product Catalog
```javascript
const catalog = {
  'P001': { name: 'Num Pang', price: 3.50, band: 'A' },
  'P002': { name: 'Coffee Set', price: 5.00, band: 'A' },
  'P003': { name: 'Lunch Set', price: 45.00, band: 'B' },
  'P004': { name: 'Party Catering', price: 250.00, band: 'C' },
  'P005': { name: 'Wedding', price: 2500.00, band: 'D' }
};
```

### Policy Matrix
```javascript
const matrix = {
  'A': { anonymous: 'allowed' },
  'B': { anonymous: 'limited', basic: 'allowed' },
  'C': { anonymous: 'blocked', basic: 'limited', verified: 'allowed' },
  'D': { anonymous: 'blocked', basic: 'blocked', verified: 'limited', high_assurance: 'allowed' }
};
```

### Output
```json
{
  "identity": {
    "assertion": {
      "identity_level": "anonymous",
      "required_level": "basic"
    },
    "policy_decision": {
      "decision": "limited",
      "amount_band": "B"
    }
  }
}
```

---

## Workflow 03: Intent Builder

**Name:** `[KH.GaaS] omnidm.ai :: 03 Intent :: Build CamDX PaymentIntent (v1)`
**Type:** Component
**GaaP Layer:** 2 (Interoperability)

### Purpose
Builds canonical CamDX payment intent with all required fields.

### Nodes

| Node | Type | Purpose |
|------|------|---------|
| `PI: Start` | Manual Trigger | Entry point |
| `PI: Build Canonical PaymentIntent` | Code | Constructs intent object |
| `PI: Output Intent` | NoOp | Passes to WF-04 |

### Intent Schema
```javascript
{
  intent_id: `pi_${timestamp}_${random}`,
  version: '1.0',
  created_at: ISO8601,
  expires_at: ISO8601 + 10 minutes,
  status: 'pending',
  merchant: { merchant_id, name, type },
  customer: { user_handle, identity_level },
  transaction: { amount, currency, description, items[] },
  metadata: { channel, request_id, amount_band }
}
```

---

## Workflow 04: CamDX Publish

**Name:** `[KH.GaaS] omnidm.ai :: 04 CamDX Publish :: Publish PaymentIntent (v1)`
**Type:** Component
**GaaP Layer:** 2 (Interoperability)

### Purpose
Publishes payment intent to CamDX, receives correlation ID.

### Nodes

| Node | Type | Purpose |
|------|------|---------|
| `DX: Start` | Manual Trigger | Entry point |
| `DX: Mock CamDX Publish` | HTTP Request | POST to httpbin (mock CamDX) |
| `DX: Parse Publish Receipt` | Code | Extracts correlation_id |
| `DX: Output` | NoOp | Passes to WF-05 |

### API Call (Production)
```javascript
POST https://camdx-api.tsc.gov.kh/publish {
  headers: {
    'X-CamDX-Operation': 'publish-intent',
    'Authorization': 'Bearer {mTLS_token}'
  },
  body: { payment_intent }
}
```

### Output
```json
{
  "camdx": {
    "publish_receipt": {
      "correlation_id": "corr_1737555123",
      "published_at": "2025-01-22T10:00:00Z",
      "policy_outcome": "approved",
      "camdx_ref": "cdx_abc123_xyz"
    }
  }
}
```

---

## Workflow 05: KHQR Generator

**Name:** `[KH.GaaS] omnidm.ai :: 05 KHQR :: Generate KHQR + Deeplink (v1)`
**Type:** Component
**GaaP Layer:** 3 (Payments)

### Purpose
Generates KHQR-compliant QR code and Bakong deeplink.

### Nodes

| Node | Type | Purpose |
|------|------|---------|
| `QR: Start` | Manual Trigger | Entry point |
| `QR: Mock KHQR Generator` | HTTP Request | POST to httpbin (mock Bakong) |
| `QR: Build KHQR Payload` | Code | Constructs QR string + deeplink |
| `QR: Output` | NoOp | Passes to WF-06 |

### KHQR Format
```javascript
const qrString = `khqr:${merchantId}:${amount}:USD:${intentId}`;
const md5Hash = crypto.createHash('md5').update(qrString).digest('hex');
const deeplink = `bakong://pay?qr=${encodeURIComponent(qrString)}&ref=${intentId}`;
```

### Output
```json
{
  "rail": {
    "payload": {
      "khqr": {
        "qr_string": "khqr:numpang-express-001:45.00:USD:pi_123",
        "deeplink": "bakong://pay?qr=...",
        "md5_hash": "a1b2c3d4e5f6",
        "generated_at": "2025-01-22T10:00:00Z",
        "expires_at": "2025-01-22T10:10:00Z"
      }
    }
  }
}
```

---

## Workflow 06: Deliver to Telegram

**Name:** `[KH.GaaS] omnidm.ai :: 06 Deliver :: Send KHQR to Telegram (v1)`
**Type:** Component
**GaaP Layer:** 7 (Application)

### Purpose
Sends formatted payment message with KHQR to customer via Telegram.

### Nodes

| Node | Type | Purpose |
|------|------|---------|
| `DEL: Start` | Manual Trigger | Entry point |
| `DEL: Format Payment Message` | Code | Builds user-friendly message |
| `DEL: Send to Telegram` | Telegram | Sends message |
| `DEL: Output` | NoOp | Completion |

### Message Template
```
✅ Order Confirmed!

🍽️ {{ product_name }}
💰 Amount: ${{ amount }} USD
📋 Order ID: {{ intent_id }}

Pay with KHQR:
`{{ qr_string }}`

🔗 [Open Bakong]({{ deeplink }})

⏰ Expires: {{ expires_at }}

🇰🇭 Powered by Cambodia GaaP
```

---

## Workflow 07: Settlement Verification

**Name:** `[KH.GaaS] omnidm.ai :: 07 Verify :: Poll Bakong Settlement (v1)`
**Type:** Daemon
**GaaP Layer:** 3 (Payments)

### Purpose
Polls Bakong every 30 seconds to verify payment settlements.

### Nodes

| Node | Type | Purpose |
|------|------|---------|
| `SETTLE: Every 30 Seconds` | Schedule Trigger | Runs every 30s |
| `SETTLE: Mock Get Pending Intents` | Code | Queries pending payments |
| `SETTLE: Check Bakong MD5` | HTTP Request | Verifies MD5 hash with Bakong |
| `SETTLE: Update Intent Status` | Code | Changes pending → completed |
| `SETTLE: Trigger Fulfillment` | NoOp | Calls WF-08 |

### Verification Logic
```javascript
// Query pending intents (from database)
const pending = getPendingIntents();

for (const intent of pending) {
  // Check with Bakong
  const verified = await checkBakongMD5(intent.md5_hash);

  if (verified) {
    // Update status
    updateIntent(intent.id, 'completed');
    // Trigger fulfillment
    triggerWorkflow('WF-08', intent);
  } else {
    // Check timeout
    if (isExpired(intent.created_at, 10)) {
      updateIntent(intent.id, 'expired');
    }
  }
}
```

---

## Workflow 08: Fulfillment

**Name:** `[KH.GaaS] omnidm.ai :: 08 Fulfill :: Deliver Order (Grab Integration Ready) (v1)`
**Type:** Component
**GaaP Layer:** 6 (Sectoral APIs)

### Purpose
Creates Grab delivery request and notifies customer.

### Nodes

| Node | Type | Purpose |
|------|------|---------|
| `FUL: Start` | Manual Trigger | Entry point |
| `FUL: Prepare Order Fulfillment` | Code | Builds fulfillment object |
| `FUL: Mock Grab API (Create Delivery)` | HTTP Request | POST to Grab API |
| `FUL: Update Fulfillment Status` | Code | Parses Grab response |
| `FUL: Send Delivery Confirmation` | Telegram | Notifies customer |
| `FUL: Output` | NoOp | Completion |

### Grab API Request
```javascript
POST https://partner-api.grab.com/deliveries {
  "service_type": "INSTANT",
  "merchant_order_id": "pi_123",
  "sender": {
    "name": "Num Pang Express",
    "phone": "+855 12 345 678",
    "address": "Street 240, Phnom Penh"
  },
  "packages": [{
    "name": "Lunch Set (4 people)",
    "quantity": 1
  }]
}
```

### Customer Notification
```
🎉 Order confirmed and dispatched!

🛵 Grab driver assigned
⏰ ETA: 30 minutes

📦 Track: grab_20250122_abc123
```

---

## Workflow 09: Audit Logger

**Name:** `[KH.GaaS] omnidm.ai :: 09 Audit :: CamDL Compliance Log (v1)`
**Type:** Component
**GaaP Layer:** 4 (Compliance & Tax)

### Purpose
Logs all events to CamDL blockchain for immutable audit trail.

### Nodes

| Node | Type | Purpose |
|------|------|---------|
| `AUD: Start` | Manual Trigger | Entry point |
| `AUD: Build Audit Event` | Code | Creates event + SHA256 hash |
| `AUD: Mock CamDL Hash Anchor` | HTTP Request | POST to CamDL |
| `AUD: Store Audit Receipt` | Code | Saves blockchain receipt |
| `AUD: Output Receipt` | NoOp | Completion |

### Audit Event Structure
```javascript
const eventData = {
  event_type: 'payment_intent_created',
  intent_id: 'pi_123',
  merchant_id: 'numpang-express-001',
  amount: 45.00,
  identity_level: 'basic',
  policy_decision: 'allowed',
  timestamp: '2025-01-22T10:00:00Z'
};

const eventHash = crypto.createHash('sha256')
  .update(JSON.stringify(eventData))
  .digest('hex');
```

### CamDL Anchor
```javascript
POST https://camdl-api.tsc.gov.kh/anchor {
  event_hash: 'sha256_hash',
  event_type: 'payment_intent_created'
}

// Response
{
  "camdl_block": "block_98765",
  "tx_hash": "0xa1b2c3d4e5f6...",
  "anchored_at": "2025-01-22T10:00:01Z",
  "immutable": true
}
```

---

## Workflow Execution Flow

```
User → WF-01 (Telegram)
         ↓
      WF-02 (Policy Check)
         ↓
      WF-03 (Build Intent)
         ↓
      WF-04 (Publish to CamDX)
         ↓
      WF-05 (Generate KHQR)
         ↓
      WF-06 (Send to User)
         ↓
      WF-07 (Poll Settlement) [Background Daemon]
         ↓
      WF-08 (Grab Delivery)
         ↓
      WF-09 (Audit Log) [Called by all workflows]
```

---

## Testing Workflows Individually

Each workflow can be tested standalone in n8n:

1. **Open workflow in n8n UI**
2. **Click "Execute Workflow"**
3. **Provide test input JSON**
4. **Verify output matches expected schema**

### Example Test Input (WF-02)
```json
{
  "commerce": {
    "request": {
      "intent_hint": {
        "product_id": "P003"
      }
    }
  }
}
```

---

For production deployment, see [ARCHITECTURE.md](./ARCHITECTURE.md).
