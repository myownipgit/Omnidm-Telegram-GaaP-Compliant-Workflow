# G02 - Identity & Policy

## Purpose

Manages customer identity verification via CamDigiKey and enforces GaaP policy decisions via CamDX. Determines transaction limits and verification requirements based on amount bands (A-D) and customer identity levels.

## Workflows in This Group

| Workflow Name | Version | Status | File |
|---------------|---------|--------|------|
| [KH.GaaS] 02 - Identity & Policy | v1 | Active | G02.Identity.Policy.v1.json |

## Integration Points

### Upstream
- **G01 - Channel Ingress** - Receives new user registration and verification requests
- **G03 - Intent Builder** - Receives payment amount for policy decision

### Downstream
- **CamDigiKey API** - Identity verification service
- **CamDX API** - Policy decision engine
- **G04 - CamDX Integration** - Publishes policy decisions
- **G06 - Telegram Delivery** - Sends verification prompts and results
- **G09 - Audit** - Logs identity events

## GaaP Compliance Layers

| Layer | Purpose | Implementation |
|-------|---------|----------------|
| **L1 - Identity** | CamDigiKey verification | Identity level assignment (anonymous → high_assurance) |
| **L2 - Interoperability** | CamDX policy decisions | Amount band enforcement, transaction limits |
| **L4 - Compliance** | Identity audit trail | All verification events logged |

## Quick Start Guide

### Prerequisites
- CamDigiKey merchant account
- CamDX API credentials
- Database schema initialized (customers table)
- PostgreSQL node configured in n8n

### Configuration Steps

1. **Set up CamDigiKey Credentials**
   ```
   Credentials → Add Credential → HTTP Header Auth
   Name: camdigi_api
   Header: Authorization
   Value: Bearer YOUR_CAMDIGI_API_KEY
   ```

2. **Set up CamDX Credentials**
   ```
   Credentials → Add Credential → HTTP Header Auth
   Name: camdx_api
   Header: X-API-Key
   Value: YOUR_CAMDX_API_KEY
   ```

3. **Configure Database Connection**
   ```
   Credentials → Add Credential → Postgres
   Name: telegraph_db
   Host: localhost
   Database: telegraph_commerce
   User: postgres
   Password: YOUR_DB_PASSWORD
   ```

4. **Import and Activate Workflow**
   - Upload `G02.Identity.Policy.v1.json`
   - Verify all credentials are linked
   - Activate workflow

### Identity Levels

| Level | Requirements | Transaction Limit | Use Cases |
|-------|--------------|-------------------|-----------|
| **Anonymous** | None | ≤ $10 (Band A) | Quick purchases, samples |
| **Basic** | Phone verification (OTP) | ≤ $100 (Band B) | Regular purchases |
| **Verified** | CamDigiKey verification | ≤ $1,000 (Band C) | Catering, events |
| **High Assurance** | CamDigiKey + biometrics | > $1,000 (Band D) | Wedding catering, bulk |

### Amount Bands

| Band | Amount Range | Identity Required | Timeout |
|------|--------------|-------------------|---------|
| **A** | ≤ $10 | Anonymous | 15 min |
| **B** | $10 - $100 | Basic | 20 min |
| **C** | $100 - $1,000 | Verified | 30 min |
| **D** | > $1,000 | High Assurance | 60 min |

### Policy Decision Flow

```
Transaction Request
    ↓
Lookup customer identity level
    ↓
Calculate amount band
    ↓
Call CamDX policy API
    ↓
    ├─ ALLOWED → Continue to payment
    ├─ LIMITED → Prompt for verification
    └─ BLOCKED → Reject + verification required
```

### CamDigiKey Verification Flow

1. **Initiate Verification**
   - Generate verification request
   - Create QR code / deeplink
   - Send to customer via Telegram

2. **Customer Scans QR**
   - Opens CamDigiKey app
   - Authenticates (PIN/biometric)
   - Approves verification request

3. **Webhook Callback**
   - CamDigiKey sends verified attributes
   - Update customer identity level
   - Continue transaction

4. **Database Update**
   ```sql
   UPDATE customers
   SET identity_level = 'verified',
       camdigi_key_id = 'CDKH-VER-2024-001234'
   WHERE customer_id = 123;
   ```

### Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `CAMDIGI_API_URL` | CamDigiKey API endpoint | https://camdigikey.gov.kh/api/v1 |
| `CAMDX_API_URL` | CamDX API endpoint | https://camdx.gov.kh/api/v1 |
| `CAMDIGI_WEBHOOK_URL` | Callback for verification | https://automation.omnidm.ai/webhook/camdigi |

### Monitoring

**Key Metrics:**
- Verification success rate
- Time to verify (seconds)
- Policy decision distribution (allowed/limited/blocked)
- Identity level distribution

**Alerts:**
- CamDigiKey API errors > 1%
- CamDX API timeout > 5 seconds
- Verification abandonment > 20%

### Troubleshooting

**Issue: "Verification required" for Band A transactions**
- Check amount band calculation logic
- Verify product catalog has correct `amount_band` values
- Check CamDX policy configuration

**Issue: CamDigiKey QR code not displaying**
- Verify CamDigiKey API credentials
- Check QR generation endpoint
- Review n8n logs for API errors

**Issue: Verification webhook not received**
- Confirm webhook URL registered with CamDigiKey
- Check webhook URL is publicly accessible
- Verify n8n webhook trigger is active

**Issue: Policy decision always "blocked"**
- Check CamDX API credentials
- Verify customer identity level in database
- Review CamDX policy rules configuration

### Testing

Use mock data from `tests/mock-data/orders.json`:

**Test Scenario 1: Anonymous user, Band A ($7)**
```json
{
  "customer_id": 1,
  "amount": 7.00,
  "identity_level": "anonymous"
}
Expected: "allowed"
```

**Test Scenario 2: Anonymous user, Band C ($250)**
```json
{
  "customer_id": 1,
  "amount": 250.00,
  "identity_level": "anonymous"
}
Expected: "blocked" + verification prompt
```

### Related Documentation

- [CamDigiKey Integration Guide](https://camdigikey.gov.kh/docs)
- [CamDX Policy API](https://camdx.gov.kh/api-docs)
- [Cambodia GaaP Framework](https://gaap.gov.kh)
- G04 - CamDX Integration (policy publishing)
