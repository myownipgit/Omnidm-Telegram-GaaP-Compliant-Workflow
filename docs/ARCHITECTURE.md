# GaaP Architecture - Technical Deep Dive

## Overview

This document details the technical architecture of the OmniDM.ai Telegram commerce platform and its alignment with Cambodia's **8-layer Government-as-a-Platform (GaaP)** framework.

---

## 1. System Architecture

### **High-Level Architecture**

```
┌─────────────────────────────────────────────────────────────────┐
│                     User Interface Layer                         │
│  Telegram │ WhatsApp │ Meta Messenger │ Instagram │ TikTok      │
└────────────────────────┬────────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────────┐
│                   n8n Workflow Orchestration                     │
│                                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │  WF-01   │→ │  WF-02   │→ │  WF-03   │→ │  WF-04   │       │
│  │ Ingress  │  │ Identity │  │  Intent  │  │  Publish │       │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘       │
│       │              │              │              │            │
│       ▼              ▼              ▼              ▼            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │  WF-05   │→ │  WF-06   │  │  WF-07   │→ │  WF-08   │       │
│  │   KHQR   │  │ Deliver  │  │  Verify  │  │ Fulfill  │       │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘       │
│       │              │              │              │            │
│       └──────────────┴──────────────┴──────────────┘            │
│                         │                                        │
│                    ┌────▼─────┐                                 │
│                    │  WF-09   │                                 │
│                    │  Audit   │                                 │
│                    └──────────┘                                 │
└─────────────────────────┬───────────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────────┐
│               Cambodia GaaP Digital Rails (Mocked)               │
│                                                                  │
│  CamDigiKey │ CamDX │ Bakong │ KHQR │ CamDL │ CamInvoice       │
│  (httpbin.org mocks for PoC)                                    │
└──────────────────────────────────────────────────────────────────┘
```

---

## 2. Workflow Architecture by GaaP Layer

### **Layer 0: Legal & Governance**
**Implementation:** Code-level controls

| Law/Regulation | Control Implementation | Workflow |
|----------------|------------------------|----------|
| E-Commerce Law (2019) | Immutable order records | WF-01, WF-09 |
| Consumer Protection | Clear pricing, refund policy | WF-01 |
| PDPL (Draft) | Data minimization | WF-02, WF-09 |
| Law on Cybercrime (Draft) | Audit trails, evidence preservation | WF-09 |

**Technical Controls:**
```javascript
// WF-01: Immutable order record
const orderRecord = {
  request_id: `crq_${timestamp}_${random}`,
  received_at: new Date().toISOString(),
  immutable: true
};
```

---

### **Layer 1: Identity, Trust & Certificates**
**Implementation:** Workflow 02 (Identity & Policy)

#### **CamDigiKey Integration**

```javascript
// Mock CamDigiKey Verification
{
  "service": "CamDigiKey",
  "user_id": "telegram_123456",
  "requested_level": "basic",
  "response": {
    "identity_level": "basic",
    "camdigikey_ref": "cdk_abc123",
    "consent_timestamp": "2025-01-22T10:00:00Z"
  }
}
```

#### **Identity Levels**

| Level | Meaning | Proof Required | Use Case |
|-------|---------|----------------|----------|
| `anonymous` | No verified identity | None | Micro-transactions ≤$10 |
| `basic` | Soft identity | Phone/device | Standard retail $10-100 |
| `verified` | Strong identity | Biometric + ID | High-value $100-1,000 |
| `high_assurance` | Enhanced KYC | Regulated process | Enterprise >$1,000 |

#### **Node Implementation (WF-02)**
```javascript
// Evaluate CamDX Policy Matrix
const policyMatrix = {
  'A': { anonymous: 'allowed' },
  'B': { anonymous: 'limited', basic: 'allowed' },
  'C': { anonymous: 'blocked', basic: 'limited', verified: 'allowed' },
  'D': { anonymous: 'blocked', basic: 'blocked', verified: 'limited', high_assurance: 'allowed' }
};

const decision = policyMatrix[amountBand][identityLevel];
```

---

### **Layer 2: Interoperability & Data Exchange**
**Implementation:** Workflows 03, 04 (Intent Builder, CamDX Publish)

#### **CamDX Canonical Payment Intent**

```json
{
  "camdx": {
    "payment_intent": {
      "intent_id": "pi_1737555123_abc123",
      "version": "1.0",
      "created_at": "2025-01-22T10:00:00Z",
      "expires_at": "2025-01-22T10:10:00Z",
      "status": "pending",
      "merchant": {
        "merchant_id": "numpang-express-001",
        "merchant_name": "Num Pang Express",
        "merchant_type": "sme_food_vendor"
      },
      "customer": {
        "user_handle": "telegram_user_123",
        "platform_user_id": "123456",
        "identity_level": "basic"
      },
      "transaction": {
        "amount": 45.00,
        "currency": "USD",
        "description": "Lunch Set (4 people)",
        "items": [{
          "item_id": "P003",
          "name": "Lunch Set",
          "quantity": 1,
          "unit_price": 45.00,
          "total": 45.00
        }]
      },
      "metadata": {
        "channel": "telegram",
        "request_id": "crq_tg_1737555123_xyz",
        "amount_band": "B"
      }
    }
  }
}
```

#### **"Once-Only" Principle**
Data is captured once and shared via CamDX:
- **Merchant registration:** Ministry of Commerce → CamDX
- **Tax status:** GDT → CamDX
- **Identity assertion:** CamDigiKey → CamDX

**No duplicate data collection required.**

---

### **Layer 3: Payments Infrastructure**
**Implementation:** Workflows 05, 07 (KHQR, Settlement)

#### **KHQR Generation (WF-05)**

```javascript
// Generate KHQR compliant QR code
const qrString = `khqr:${merchantId}:${amount}:USD:${intentId}`;
const md5Hash = crypto.createHash('md5')
  .update(`${intentId}_${amount}_${timestamp}`)
  .digest('hex');

const deeplink = `bakong://pay?qr=${encodeURIComponent(qrString)}&ref=${intentId}`;
```

**Output:**
```json
{
  "rail": {
    "payload": {
      "khqr": {
        "qr_string": "khqr:numpang-express-001:45.00:USD:pi_123",
        "deeplink": "bakong://pay?qr=...",
        "md5_hash": "a1b2c3d4e5f6...",
        "generated_at": "2025-01-22T10:00:00Z",
        "expires_at": "2025-01-22T10:10:00Z"
      }
    }
  }
}
```

#### **Bakong Settlement Verification (WF-07)**

**Polling Workflow (Daemon):**
```javascript
// Every 30 seconds
1. Query pending payment intents
2. For each intent:
   - POST to Bakong verify endpoint with MD5 hash
   - Check response: verified = true/false
3. If verified:
   - Update intent status: pending → completed
   - Trigger WF-08 (Fulfillment)
4. If timeout (>10 minutes):
   - Update status: pending → expired
```

---

### **Layer 4: Compliance, Audit & Tax**
**Implementation:** Workflow 09 (Audit Logger)

#### **CamDL Blockchain Audit Trail**

```javascript
// Build audit event
const eventData = {
  event_type: 'payment_intent_created',
  intent_id: 'pi_123',
  merchant_id: 'numpang-express-001',
  amount: 45.00,
  identity_level: 'basic',
  policy_decision: 'allowed',
  timestamp: '2025-01-22T10:00:00Z'
};

// Hash for immutability
const eventHash = crypto.createHash('sha256')
  .update(JSON.stringify(eventData))
  .digest('hex');

// Anchor to CamDL
POST https://camdl-api/anchor {
  event_hash: eventHash,
  event_type: 'payment_intent_created'
}
```

**CamDL Response:**
```json
{
  "audit_receipt": {
    "event_id": "audit_1737555123",
    "anchored_at": "2025-01-22T10:00:01Z",
    "camdl_block": "block_98765",
    "tx_hash": "0xa1b2c3d4e5f6...",
    "immutable": true,
    "compliance_ready": true
  }
}
```

#### **CamInvoice Readiness (Future)**

When CamInvoice mandate goes live (May 2025):
```javascript
// WF-09 extended for e-invoice
POST https://caminvoice-api/validate {
  invoice: {
    merchant_tin: "K001-123456789",
    amount: 45.00,
    items: [...],
    timestamp: "2025-01-22T10:00:00Z"
  }
}

// GDT signs and returns
{
  invoice_hash: "gdt_signed_hash",
  qr_code: "gdt_validation_qr",
  valid_for_tax_deduction: true
}
```

---

### **Layer 5: Credit, Risk & Financial Data**
**Implementation:** Future Integration

**Planned Integration Points:**
- Credit Bureau Cambodia API
- K-Score credit scoring
- Transaction history for underwriting

**Current State:** Mock placeholder in WF-02

---

### **Layer 6: Sectoral APIs**
**Implementation:** Workflow 08 (Fulfillment - Grab Integration)

#### **Grab Express API**

```javascript
// Create delivery request
POST https://partner-api.grab.com/deliveries {
  "service_type": "INSTANT",
  "merchant_order_id": "pi_123",
  "sender": {
    "name": "Num Pang Express",
    "phone": "+855 12 345 678",
    "address": "Street 240, Phnom Penh"
  },
  "recipient": {
    "name": "Customer Name",
    "phone": "+855 98 765 432",
    "address": "User provided address"
  },
  "packages": [{
    "name": "Lunch Set (4 people)",
    "quantity": 1,
    "price": 45.00
  }]
}
```

**Response:**
```json
{
  "delivery_id": "grab_20250122_abc123",
  "status": "dispatched",
  "driver": {
    "name": "Driver Name",
    "phone": "+855 11 222 333",
    "vehicle": "Moto"
  },
  "estimated_delivery": "2025-01-22T10:30:00Z"
}
```

---

### **Layer 7: Application Layer**
**Implementation:** Workflows 01, 06 (Telegram Interface)

#### **WF-01: Channel Ingress (Orchestrator)**

**Message Parsing:**
```javascript
// Normalize Telegram message to commerce.request
{
  "commerce": {
    "request": {
      "request_id": "crq_tg_123_abc",
      "channel": "telegram",
      "tenant_id": "omnidm-ai",
      "merchant_id": "numpang-express-001",
      "actor": {
        "user_handle": "telegram_user",
        "platform_user_id": "123456"
      },
      "message": {
        "text": "3",
        "chat_id": 789012
      },
      "intent_hint": {
        "type": "select_product",
        "product_id": "P003"
      }
    }
  }
}
```

#### **WF-06: Delivery (Response to User)**

**Formatted Message:**
```
✅ Order Confirmed!

🍽️ Lunch Set (4 people)
💰 Amount: $45.00 USD
📋 Order ID: pi_1737555123_abc123

Pay with KHQR:
`khqr:numpang-express-001:45.00:USD:pi_123`

🔗 Open Bakong (bakong://pay?qr=...)

⏰ Expires: 22/01/2025 10:10 AM

🇰🇭 Powered by Cambodia GaaP
```

---

## 3. Data Schema Standards

### **commerce.request** (Canonical Input)
```typescript
interface CommerceRequest {
  request_id: string;
  channel: 'telegram' | 'whatsapp' | 'meta' | 'instagram' | 'tiktok';
  received_at: string; // ISO 8601
  tenant_id: string;
  merchant_id: string;
  actor: {
    user_handle: string;
    platform_user_id: string;
    first_name?: string;
    last_name?: string;
    phone?: string;
  };
  message: {
    text: string;
    chat_id: number;
  };
  intent_hint: {
    type: 'greeting' | 'browse_menu' | 'select_product' | 'purchase' | 'order_status';
    product_id?: string;
    amount?: number;
    currency?: string;
  };
}
```

### **camdx.payment_intent** (Canonical Payment)
```typescript
interface PaymentIntent {
  intent_id: string;
  version: string;
  created_at: string;
  expires_at: string;
  status: 'pending' | 'completed' | 'expired' | 'failed';
  merchant: MerchantInfo;
  customer: CustomerInfo;
  transaction: TransactionInfo;
  metadata: Record<string, any>;
}
```

### **identity.assertion** (Identity Result)
```typescript
interface IdentityAssertion {
  camdigikey_ref: string | null;
  identity_level: 'anonymous' | 'basic' | 'verified' | 'high_assurance';
  required_level: string;
  consent_timestamp: string;
}
```

---

## 4. Security Architecture

### **Credential Isolation**

All sensitive credentials stored in n8n vault:
- Telegram Bot Token
- Grab API Keys
- CamDX mTLS Certificates
- Bakong API Keys

**Never hardcoded in workflows.**

### **Data Minimization (PDPL)**

```javascript
// Good: Store reference only
{
  "camdigikey_ref": "cdk_abc123",
  "identity_level": "verified"
}

// Bad: Store raw PII
{
  "id_card_number": "123456789",
  "photo": "base64..."
}
```

### **Immutable Audit Trail**

All state changes logged to CamDL:
- Payment intent created
- Policy decision made
- Settlement verified
- Order fulfilled

**Tamper-evident blockchain storage.**

---

## 5. Compliance Dashboard Integration

### **Real-Time Metrics**

```javascript
// Dashboard KPIs (from WF-09 audit logs)
{
  "identity": {
    "verified_merchants_pct": 87.5,
    "anonymous_transactions_pct": 45.2
  },
  "payments": {
    "khqr_usage_pct": 100.0,
    "bakong_settlement_pct": 98.3
  },
  "tax": {
    "invoice_coverage_pct": 92.1
  },
  "security": {
    "incident_mttr_seconds": 120,
    "log_completeness_pct": 100.0
  },
  "policy": {
    "threshold_enforcement_accuracy_pct": 99.8
  }
}
```

---

## 6. Scalability Considerations

### **Multi-Tenant Architecture**

Each tenant gets isolated:
- Workflow instances
- Credential sets
- Audit logs
- Compliance dashboards

**Current tenants:**
- `omnidm-ai` (prototype)
- `camfintech.com` (production)
- `mysticmandela.com` (partner)

### **Horizontal Scaling**

n8n can scale via:
- Queue mode (Redis/RabbitMQ)
- Multiple worker nodes
- Database replication (PostgreSQL)

---

## 7. Future Enhancements

### **Phase 2 Features**

- [ ] Real CamDX/Bakong API integration
- [ ] WhatsApp Business API channel
- [ ] CamInvoice integration (May 2025)
- [ ] Credit Bureau Cambodia scoring
- [ ] Multi-currency support (KHR, THB)
- [ ] Voice commerce (Telegram voice messages)

### **Phase 3 Features**

- [ ] Cross-border payments (PromptPay, NAPAS)
- [ ] InsurTech embedding
- [ ] Supply chain finance
- [ ] AI-powered fraud detection

---

## 8. Deployment Architecture

### **Production Deployment**

```
┌─────────────────────────────────────────────────────────────────┐
│                     Load Balancer (nginx)                        │
└────────────────────────┬────────────────────────────────────────┘
                         │
        ┌────────────────┴────────────────┐
        │                                 │
┌───────▼────────┐              ┌────────▼───────┐
│  n8n Worker 1  │              │  n8n Worker 2  │
│  (Workflows)   │              │  (Workflows)   │
└───────┬────────┘              └────────┬───────┘
        │                                 │
        └────────────────┬────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────────┐
│                PostgreSQL (Workflow State)                       │
└──────────────────────────────────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────────┐
│                   Redis (Queue Mode)                             │
└──────────────────────────────────────────────────────────────────┘
```

---

**For implementation details on each workflow, see [WORKFLOWS.md](./WORKFLOWS.md).**
