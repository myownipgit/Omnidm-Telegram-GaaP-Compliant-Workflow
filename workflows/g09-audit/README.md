# G09 - Audit Trail & Compliance

## Purpose

Creates an immutable audit trail of all transactions and events by anchoring them to Cambodia Digital Ledger (CamDL) blockchain. Ensures compliance with Cambodia GaaP Layer 4 requirements for transparency and non-repudiation.

## Workflows in This Group

| Workflow Name | Version | Status | File |
|---------------|---------|--------|------|
| [KH.GaaS] 09 - Audit CamDL | v1 | Active | G09.Audit.CamDL.v1.json |

## Integration Points

### Upstream
- **All Workflows (G01-G08)** - Receives events from every workflow

### Downstream
- **CamDL API** - Anchors audit logs to blockchain
- **Database (audit_logs)** - Persists all events
- **(No further downstream)** - Terminal workflow in the chain

## GaaP Compliance Layers

| Layer | Purpose | Implementation |
|-------|---------|----------------|
| **L4 - Compliance & Audit** | Immutable audit trail | Blockchain anchoring, SHA256 hashing |
| **L0 - Legal & Governance** | Regulatory compliance | Event logging per NBC requirements |

## Quick Start Guide

### Prerequisites
- CamDL node access (or public CamDL endpoint)
- CamDL API credentials
- Database schema initialized (audit_logs table)

### Configuration Steps

1. **Register CamDL Account**
   - Contact Cambodia Digital Economy Agency
   - Complete KYC for audit trail service
   - Receive CamDL API credentials

2. **Set up CamDL API Credentials in n8n**
   ```
   Credentials → Add Credential → HTTP Header Auth
   Name: camdl_api
   Header: X-CamDL-API-Key
   Value: YOUR_CAMDL_API_KEY
   ```

3. **Configure Audit Settings**
   ```json
   {
     "merchant_id": "numpang-express-001",
     "audit_level": "comprehensive",  // minimal, standard, comprehensive
     "anchoring_interval": "realtime",  // realtime, batched
     "retention_years": 7  // NBC requirement
   }
   ```

4. **Import and Activate Workflow**
   - Upload `G09.Audit.CamDL.v1.json`
   - Link CamDL credentials
   - Configure database connection
   - Activate workflow

### Audit Event Flow

```
Event occurs in any workflow
    ↓
Create audit log entry
    ↓
Generate SHA256 hash of event data
    ↓
Store in database (audit_logs table)
    ↓
Submit to CamDL for blockchain anchoring
    ↓
Receive CamDL block reference
    ↓
Update audit log with blockchain proof
```

### Event Types

| Event Type | Source | Example |
|------------|--------|---------|
| `customer.created` | G01 | New user starts conversation |
| `customer.verified` | G02 | CamDigiKey verification complete |
| `order.created` | G03 | Order intent created |
| `order.confirmed` | G03 | Customer confirmed order |
| `payment.initiated` | G04 | CamDX intent published |
| `payment.authorized` | G07 | Customer scanned KHQR |
| `payment.captured` | G07 | Settlement verified |
| `delivery.assigned` | G08 | Grab driver assigned |
| `order.completed` | G08 | Delivery confirmed |
| `order.cancelled` | Any | Order cancelled |
| `policy.decision` | G02 | CamDX policy check result |

### Database Schema

**audit_logs Table:**
```sql
CREATE TABLE audit_logs (
  log_id SERIAL PRIMARY KEY,
  event_type VARCHAR(100) NOT NULL,
  event_data JSONB NOT NULL,
  event_hash VARCHAR(64) NOT NULL,       -- SHA256 hash
  camdl_block VARCHAR(255),              -- Blockchain block reference
  camdl_tx_hash VARCHAR(255),            -- Blockchain transaction hash
  order_id VARCHAR(100),
  intent_id VARCHAR(100),
  customer_id INT,
  merchant_id VARCHAR(50),
  anchored_at TIMESTAMP,                 -- When anchored to blockchain
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_logs_event_type ON audit_logs(event_type);
CREATE INDEX idx_audit_logs_order ON audit_logs(order_id);
CREATE INDEX idx_audit_logs_created ON audit_logs(created_at DESC);
```

### Event Hash Calculation

**SHA256 Hash:**
```javascript
const crypto = require('crypto');

function hashEvent(eventData) {
  const canonical = JSON.stringify(eventData, Object.keys(eventData).sort());
  return crypto.createHash('sha256').update(canonical).digest('hex');
}

// Example
const event = {
  event_type: "order.created",
  order_id: "ORD-20250101-0001",
  customer_id: 1,
  amount: 7.00,
  timestamp: "2025-01-01T10:00:00Z"
};

const hash = hashEvent(event);
// => "a3f5e7d9c1b2a4f6e8d0c2b4a6f8e0d2c4b6a8f0e2d4c6b8a0f2e4d6c8b0a2f4"
```

**Purpose of Hash:**
- **Integrity** - Detect tampering
- **Non-repudiation** - Prove event occurred
- **Deduplication** - Prevent duplicate logging

### CamDL API - Anchor Event

**Endpoint:** `POST https://camdl.gov.kh/api/v1/anchor`

**Request:**
```json
{
  "merchant_id": "numpang-express-001",
  "event_hash": "a3f5e7d9c1b2a4f6e8d0c2b4a6f8e0d2c4b6a8f0e2d4c6b8a0f2e4d6c8b0a2f4",
  "event_type": "order.created",
  "metadata": {
    "order_id": "ORD-20250101-0001",
    "timestamp": "2025-01-01T10:00:00Z"
  }
}
```

**Response:**
```json
{
  "status": "anchored",
  "block_number": 1234567,
  "block_hash": "0x9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08",
  "transaction_hash": "0x2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae",
  "anchored_at": "2025-01-01T10:00:15Z",
  "proof_url": "https://camdl.gov.kh/proof/1234567/0x2c26b46b...",
  "merkle_root": "0x8c7e...",
  "merkle_path": ["0xa3f5...", "0xb2c4..."]
}
```

**Database Update:**
```sql
UPDATE audit_logs
SET camdl_block = '1234567',
    camdl_tx_hash = '0x2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae',
    anchored_at = '2025-01-01T10:00:15Z'
WHERE event_hash = 'a3f5e7d9c1b2a4f6e8d0c2b4a6f8e0d2c4b6a8f0e2d4c6b8a0f2e4d6c8b0a2f4';
```

### Audit Event Example (Order Created)

```json
{
  "event_type": "order.created",
  "event_data": {
    "order_id": "ORD-20250101-0001",
    "customer": {
      "customer_id": 1,
      "telegram_user_id": 123456789,
      "identity_level": "anonymous"
    },
    "merchant_id": "numpang-express-001",
    "items": [
      {
        "product_id": "P001",
        "quantity": 2,
        "unit_price": 3.50,
        "total": 7.00
      }
    ],
    "total_amount": 7.00,
    "currency": "USD",
    "amount_band": "A",
    "channel": "telegram",
    "timestamp": "2025-01-01T10:00:00Z"
  },
  "event_hash": "a3f5e7d9c1b2a4f6e8d0c2b4a6f8e0d2c4b6a8f0e2d4c6b8a0f2e4d6c8b0a2f4"
}
```

### Audit Proof Verification

Anyone can verify an audit log against the blockchain:

**Verification Steps:**
1. Retrieve event data from database
2. Recalculate SHA256 hash
3. Query CamDL blockchain for transaction
4. Compare stored hash with blockchain record
5. Verify Merkle path inclusion proof

**Verification API:**
```bash
GET https://camdl.gov.kh/api/v1/verify
{
  "event_hash": "a3f5e7d9c1b2a4f6e8d0c2b4a6f8e0d2c4b6a8f0e2d4c6b8a0f2e4d6c8b0a2f4",
  "block_number": 1234567
}
```

**Response:**
```json
{
  "verified": true,
  "block_number": 1234567,
  "timestamp": "2025-01-01T10:00:15Z",
  "merkle_proof": {
    "valid": true,
    "path": ["0xa3f5...", "0xb2c4..."],
    "root": "0x8c7e..."
  }
}
```

### Batched vs Real-time Anchoring

**Real-time (Default):**
- Each event anchored immediately
- Higher cost (gas fees per transaction)
- Instant proof availability

**Batched:**
- Events grouped (e.g., every 100 events or every 10 minutes)
- Lower cost (single transaction for multiple events)
- Slight delay in proof availability

**Configuration:**
```json
{
  "anchoring_mode": "batched",
  "batch_size": 100,
  "batch_interval_minutes": 10
}
```

### Compliance Reports

Generate audit reports for regulatory compliance:

**Daily Transaction Report:**
```sql
SELECT
  event_type,
  COUNT(*) as event_count,
  COUNT(CASE WHEN camdl_block IS NOT NULL THEN 1 END) as anchored_count,
  MIN(created_at) as first_event,
  MAX(created_at) as last_event
FROM audit_logs
WHERE created_at >= CURRENT_DATE
  AND created_at < CURRENT_DATE + INTERVAL '1 day'
GROUP BY event_type
ORDER BY event_count DESC;
```

**Order Audit Trail:**
```sql
SELECT
  log_id,
  event_type,
  event_data->>'timestamp' as timestamp,
  event_hash,
  camdl_block,
  camdl_tx_hash,
  anchored_at
FROM audit_logs
WHERE order_id = 'ORD-20250101-0001'
ORDER BY created_at ASC;
```

**Example Output:**
```
1. order.created       - Block: 1234567
2. order.confirmed     - Block: 1234568
3. payment.initiated   - Block: 1234569
4. payment.captured    - Block: 1234571
5. delivery.assigned   - Block: 1234575
6. order.completed     - Block: 1234580
```

### Data Retention

NBC requirement: **7 years minimum**

```sql
-- Archive old logs (after 7 years)
INSERT INTO audit_logs_archive
SELECT * FROM audit_logs
WHERE created_at < CURRENT_DATE - INTERVAL '7 years';

-- Delete from main table (if needed for performance)
DELETE FROM audit_logs
WHERE created_at < CURRENT_DATE - INTERVAL '7 years';
```

### Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `CAMDL_API_URL` | CamDL API endpoint | https://camdl.gov.kh/api/v1 |
| `CAMDL_NETWORK` | Blockchain network | mainnet, testnet |
| `ANCHORING_MODE` | Anchoring strategy | realtime, batched |
| `BATCH_SIZE` | Events per batch | 100 |

### Monitoring

**Key Metrics:**
- Events logged per hour
- Anchoring success rate
- Time to anchor (seconds)
- Blockchain gas costs
- Verification requests

**Alerts:**
- Anchoring failure rate > 1%
- Unanchored events > 1000
- CamDL API errors
- Hash collision detected (critical)

### Troubleshooting

**Issue: Event not anchored to blockchain**
- Check CamDL API credentials
- Verify network connectivity
- Review gas balance (if applicable)
- Check event hash format

**Issue: Hash collision**
- Review hash calculation logic
- Ensure timestamp uniqueness
- Add nonce to event data

**Issue: Verification failed**
- Recalculate hash from event data
- Check blockchain block exists
- Verify Merkle path validity

**Issue: Slow anchoring**
- Check CamDL network status
- Consider batching mode
- Review API rate limits

### Testing

**Test Scenario 1: Log and anchor event**
```bash
# 1. Create audit log
INSERT INTO audit_logs (event_type, event_data, event_hash)
VALUES (
  'order.created',
  '{"order_id": "ORD-TEST-001", ...}',
  'a3f5e7d9c1b2a4f6e8d0c2b4a6f8e0d2c4b6a8f0e2d4c6b8a0f2e4d6c8b0a2f4'
);

# 2. Call CamDL anchor API
POST https://camdl.gov.kh/api/v1/anchor
{
  "event_hash": "a3f5e7d9...",
  "event_type": "order.created"
}

# 3. Verify anchored
SELECT camdl_block, camdl_tx_hash
FROM audit_logs
WHERE event_hash = 'a3f5e7d9...';

Expected:
- camdl_block populated
- camdl_tx_hash populated
- anchored_at timestamp set
```

**Test Scenario 2: Verify audit proof**
```bash
GET https://camdl.gov.kh/api/v1/verify
{
  "event_hash": "a3f5e7d9...",
  "block_number": 1234567
}

Expected Response:
{
  "verified": true,
  "merkle_proof": {"valid": true}
}
```

### Privacy Considerations

**What is logged:**
- Event type
- Order ID, Intent ID, Customer ID (references)
- Amounts, timestamps, status changes

**What is NOT logged:**
- Customer PII (names, addresses, phone numbers)
- Payment credentials
- Telegram messages content
- Driver personal information

**GDPR/Privacy Compliance:**
- Log pseudonymous identifiers only
- Link to external systems via IDs
- Blockchain contains hashes only (not raw data)
- Support "right to be forgotten" via data purging (while keeping hash on chain)

### Related Documentation

- [CamDL Documentation](https://camdl.gov.kh/docs)
- [Cambodia GaaP Layer 4 Specification](https://gaap.gov.kh/layer4)
- [NBC Audit Trail Requirements](https://nbc.gov.kh/audit-requirements)
- [Blockchain Verification Guide](https://camdl.gov.kh/docs/verification)
- Database Schema: `database/schema.sql`
