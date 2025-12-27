# G05 - KHQR Generation

## Purpose

Generates Khmer QR (KHQR) payment codes via Bakong API for instant payment collection. Creates scannable QR codes and deeplinks that customers can use with any Bakong-enabled mobile banking app in Cambodia.

## Workflows in This Group

| Workflow Name | Version | Status | File |
|---------------|---------|--------|------|
| [KH.GaaS] 05 - KHQR Generator | v1 | Active | G05.KHQR.Generator.v1.json |

## Integration Points

### Upstream
- **G04 - CamDX Integration** - Receives payment intent with CamDX correlation ID

### Downstream
- **Bakong API (NBC)** - Generates KHQR codes
- **G06 - Telegram Delivery** - Sends QR code and payment link to customer
- **Database (payment_intents)** - Updates with KHQR data
- **G09 - Audit** - Logs KHQR generation events

## GaaP Compliance Layers

| Layer | Purpose | Implementation |
|-------|---------|----------------|
| **L3 - Payments** | Bakong KHQR standard | QR code generation per NBC spec |
| **L2 - Interoperability** | Multi-bank support | Works with all Bakong-enabled banks |
| **L4 - Compliance** | Payment traceability | KHQR hash for settlement matching |

## Quick Start Guide

### Prerequisites
- Bakong merchant account (via National Bank of Cambodia)
- Bakong API credentials
- Merchant KHQR account ID (format: `khqr.{bank}@{bankname}`)

### Configuration Steps

1. **Register Bakong Merchant Account**
   - Contact National Bank of Cambodia
   - Provide business registration
   - Receive merchant KHQR ID (e.g., `khqr.aba@ababank`)

2. **Set up Bakong API Credentials in n8n**
   ```
   Credentials → Add Credential → HTTP Header Auth
   Name: bakong_api
   Header: X-Bakong-API-Key
   Value: YOUR_BAKONG_API_KEY
   ```

3. **Configure Merchant Info**
   ```json
   {
     "merchant_khqr_id": "khqr.aba@ababank",
     "merchant_name": "Num Pang Express",
     "merchant_city": "Phnom Penh",
     "mcc": "5814",  // Fast food restaurants
     "currency": "USD"
   }
   ```

4. **Import and Activate Workflow**
   - Upload `G05.KHQR.Generator.v1.json`
   - Link Bakong credentials
   - Test KHQR generation
   - Activate workflow

### KHQR Standard (EMVCo)

KHQR follows the EMVCo QR Code Specification for Payment Systems. Structure:

```
00 - Payload Format Indicator (always "01")
01 - Point of Initiation Method (11=static, 12=dynamic)
30-51 - Merchant Account Information
52 - Merchant Category Code
53 - Transaction Currency (840=USD, 116=KHR)
54 - Transaction Amount
58 - Country Code (KH)
59 - Merchant Name
60 - Merchant City
62 - Additional Data (order reference)
63 - CRC (checksum)
```

**Example KHQR String:**
```
00020101021230820016khqr.aba@ababank520441115802KH5916Num Pang Express6011Phnom Penh62410109ORD-00011708PI-000016304A1B2
```

### Bakong API Request

**Endpoint:** `POST https://api.bakong.nbc.gov.kh/v1/khqr/generate`

**Request Body:**
```json
{
  "merchant_id": "khqr.aba@ababank",
  "merchant_name": "Num Pang Express",
  "merchant_city": "Phnom Penh",
  "mcc": "5814",
  "amount": "7.00",
  "currency": "USD",
  "reference": {
    "order_id": "ORD-20250101-0001",
    "intent_id": "PI-20250101-0001"
  },
  "bill_number": "ORD-20250101-0001",
  "terminal_id": "TG-001",
  "ttl_seconds": 900  // 15 minutes for Band A
}
```

**Response:**
```json
{
  "status": "success",
  "data": {
    "qr_string": "00020101021230820016khqr.aba@ababank...",
    "qr_image": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...",
    "deeplink": "https://bakong.nbc.gov.kh/qr?data=00020101...",
    "md5_hash": "5f4dcc3b5aa765d61d8327deb882cf99",
    "expires_at": "2025-01-01T10:15:00Z",
    "created_at": "2025-01-01T10:00:00Z"
  }
}
```

### KHQR MD5 Hash

The MD5 hash is critical for settlement verification:

**Purpose:**
- Uniquely identifies this specific KHQR
- Used in settlement polling to match payments
- Prevents duplicate processing

**Calculation:**
```javascript
const crypto = require('crypto');
const md5Hash = crypto.createHash('md5')
  .update(qr_string)
  .digest('hex');
```

**Database Storage:**
```sql
UPDATE payment_intents
SET khqr_string = '00020101...',
    khqr_deeplink = 'https://bakong.nbc.gov.kh/qr?data=...',
    khqr_md5_hash = '5f4dcc3b5aa765d61d8327deb882cf99'
WHERE intent_id = 'PI-20250101-0001';
```

### QR Code Image Generation

Bakong returns QR as Base64-encoded PNG:

**Telegram Display:**
```javascript
// Send to customer via Telegram
{
  "chat_id": 123456789,
  "photo": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...",
  "caption": "Scan to pay $7.00\n⏰ Expires in 15 minutes"
}
```

**Alternative: Deeplink**
```
Open in Bakong app:
https://bakong.nbc.gov.kh/qr?data=00020101021230820016khqr.aba@ababank...
```

### TTL (Time to Live) by Amount Band

| Band | Base TTL | Notes |
|------|----------|-------|
| A | 900s (15 min) | Quick purchases |
| B | 1200s (20 min) | Regular orders |
| C | 1800s (30 min) | High-value, needs review |
| D | 3600s (60 min) | Large transactions |

After TTL expires:
- QR becomes invalid
- Customer must request new KHQR
- Intent marked as `expired`

### Supported Mobile Banking Apps

KHQR works with all Bakong-enabled apps in Cambodia:
- **ABA Mobile** (ABA Bank)
- **Wing Money** (Wing Bank)
- **Pi Pay** (ACLEDA Bank)
- **Chip Mong Pay** (Chip Mong Bank)
- **Vattanac Pay** (Vattanac Bank)
- **Bakong App** (NBC official app)
- 50+ other banks

### Currency Support

| Currency Code | Name | Symbol |
|---------------|------|--------|
| **840** (USD) | US Dollar | $ |
| **116** (KHR) | Khmer Riel | ៛ |

Most transactions use USD, but KHR is fully supported.

### Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `BAKONG_API_URL` | Bakong API endpoint | https://api.bakong.nbc.gov.kh/v1 |
| `BAKONG_MERCHANT_ID` | Your KHQR merchant ID | khqr.aba@ababank |
| `BAKONG_MERCHANT_NAME` | Business name | Num Pang Express |
| `BAKONG_MCC` | Merchant category code | 5814 |

### Monitoring

**Key Metrics:**
- KHQR generation success rate
- Average generation time
- QR scans (if analytics enabled)
- Expired QR rate

**Alerts:**
- Bakong API errors > 1%
- Generation time > 3 seconds
- MD5 hash collision (critical)
- Expiry rate > 30%

### Troubleshooting

**Issue: "Invalid merchant ID"**
- Verify Bakong merchant account active
- Check merchant_khqr_id format
- Confirm API credentials valid

**Issue: QR code not displaying in Telegram**
- Check Base64 encoding intact
- Verify image data format (PNG)
- Try deeplink as fallback

**Issue: "Amount exceeds limit"**
- Check merchant transaction limits
- Verify amount band restrictions
- May need higher verification level

**Issue: QR expires too quickly**
- Review TTL calculation logic
- Check amount band → TTL mapping
- Consider product prep time

**Issue: Duplicate MD5 hash**
- Check QR string uniqueness
- Verify reference IDs included
- Add timestamp to ensure uniqueness

### Testing

Use mock data from `tests/mock-data/khqr-responses.json`:

**Test Scenario 1: Generate Band A KHQR**
```bash
POST https://api.bakong.nbc.gov.kh/v1/khqr/generate
{
  "amount": "7.00",
  "currency": "USD",
  "reference": {
    "order_id": "ORD-20250101-0001"
  },
  "ttl_seconds": 900
}

Expected Response:
- qr_string length: 100-200 characters
- qr_image: Base64 PNG
- deeplink: Valid URL
- md5_hash: 32 character hex string
```

**Test Scenario 2: Scan QR with Mobile App**
1. Generate KHQR for $3.50
2. Open ABA Mobile / Wing / Pi Pay
3. Tap "Scan QR"
4. Scan generated QR code
5. Verify amount displays correctly
6. Complete payment

### Security Considerations

- **QR String Integrity:** Never modify QR string (breaks CRC)
- **Hash Storage:** Store MD5 hash for settlement matching
- **Expiry Enforcement:** Reject payments after TTL
- **Amount Validation:** Verify payment amount matches intent
- **Merchant Verification:** Ensure funds go to correct account

### Related Documentation

- [Bakong KHQR Specification](https://bakong.nbc.gov.kh/docs/khqr)
- [EMVCo QR Standard](https://www.emvco.com/emv-technologies/qrcodes/)
- [NBC Merchant Guidelines](https://nbc.gov.kh/bakong/merchants)
- G06 - Telegram Delivery (QR delivery to customer)
- G07 - Settlement Verification (payment confirmation)
