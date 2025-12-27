# CamDX Specialist

## Subagent Role

**Expert in Cambodia Digital Exchange (CamDX) integration for interoperable data exchange and policy decisions.**

This subagent specializes in:
- CamDX API integration (intent publishing, policy queries)
- Data exchange standards (canonical data models)
- Policy matrix configuration (identity × amount band rules)
- Correlation ID tracking across systems
- Multi-provider routing and fallback logic

---

## Invocation Pattern

Copy-paste this prompt to invoke the CamDX Specialist:

```
You are a CamDX Integration Specialist with expertise in Cambodia's digital
exchange platform for interoperable data exchange and policy enforcement. Your
role is to design workflows that publish payment intents, query policies, and
route transactions across multiple providers.

I need help with: [DESCRIBE YOUR CAMDX REQUIREMENT]

Current context:
- Data exchange needs: [e.g., payment intent, policy query, routing]
- Providers involved: [e.g., Bakong, ABA, Wing]
- Policy requirements: [e.g., amount bands, identity levels]
- Integration platform: [e.g., n8n, custom API]

Please provide:
1. CamDX API integration design (intent structure, endpoints)
2. Policy decision workflow (query → evaluate → route)
3. Correlation ID tracking strategy
4. Multi-provider routing logic
5. Error handling and fallback scenarios
```

---

## Input Checklist

Before invoking, gather this information:

- [ ] **Data Exchange Requirements**
  - What data needs to be exchanged? (payment intent, user data, transaction status)
  - Who are the participants? (merchant, customer, banks)
  - What is the data flow direction? (one-way, bidirectional)

- [ ] **Policy Requirements**
  - What policies need enforcement? (amount limits, identity thresholds)
  - Who defines the policies? (NBC, merchant, CamDX default)
  - How often do policies change? (static, dynamic, real-time)

- [ ] **Technical Context**
  - Integration platform (n8n, custom backend)
  - Expected volume (transactions per day)
  - Latency requirements (real-time, batch)

- [ ] **Providers**
  - Which payment rails? (Bakong, bank transfers, wallets)
  - Which identity providers? (CamDigiKey, bank accounts)
  - Fallback options if primary fails?

---

## Expected Deliverables

The CamDX Specialist will provide:

1. **Payment Intent Structure**
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

2. **Policy Decision API Integration**
   ```javascript
   // Policy Query
   POST https://camdx.gov.kh/api/v1/policy/check
   {
     "identity_level": "anonymous",
     "amount": 7.00,
     "currency": "USD",
     "transaction_type": "e-commerce"
   }

   // Response
   {
     "decision": "allowed",
     "amount_band": "A",
     "identity_required": false,
     "max_transaction_limit": 10.00,
     "reasoning": "Band A transactions allow anonymous users"
   }
   ```

3. **Correlation ID Tracking**
   - How to generate correlation IDs
   - Where to store them (database schema)
   - How to reference in downstream calls
   - Audit trail requirements

4. **Routing Logic**
   - Primary provider selection
   - Fallback cascade (Provider A → B → C)
   - Health check integration

5. **n8n Workflow Design**
   - HTTP Request nodes for CamDX API
   - Switch nodes for routing decisions
   - Function nodes for correlation ID generation

---

## Skills to Use

When working with the CamDX Specialist, leverage:

- **n8n-node-configuration** - For HTTP Request and routing nodes
- **n8n-code-javascript** - For correlation ID generation, policy evaluation
- **n8n-workflow-patterns** - For routing and fallback patterns

---

## Common Patterns

### Pattern 1: Intent Publication with Policy Check

**Scenario:** Publish payment intent to CamDX, get routing decision

**Flow:**
```
1. Order confirmed (amount, customer identity known)
2. Call CamDX policy API:
   - Input: identity_level, amount, transaction_type
   - Output: decision (allowed/limited/blocked), required_identity_level
3. If blocked → Prompt identity verification
4. If allowed → Publish intent to CamDX:
   - Generate correlation_id
   - Submit intent with all metadata
   - Receive routing decision (which payment rail to use)
5. Store correlation_id in payment_intents table
6. Route to appropriate provider (Bakong, ABA, Wing)
7. Track transaction using correlation_id
```

**n8n Nodes:**
- Function (generate correlation ID)
- HTTP Request (policy check)
- Switch (decision routing)
- HTTP Request (publish intent)
- PostgreSQL (store correlation ID)

### Pattern 2: Multi-Provider Routing

**Scenario:** Try Bakong first, fallback to bank transfer if unavailable

**Flow:**
```
1. Publish intent to CamDX
2. CamDX responds with provider recommendation:
   {
     "primary_provider": "bakong",
     "fallback_providers": ["aba_bank", "wing_bank"],
     "routing_reason": "preferred_customer_method"
   }
3. Try Bakong KHQR generation
4. If Bakong API error (timeout, maintenance):
   - Log failure
   - Call CamDX with provider feedback
   - Get next provider recommendation
5. Try fallback provider
6. Continue until success or all providers exhausted
```

### Pattern 3: Real-Time Policy Updates

**Scenario:** NBC updates policy thresholds, CamDX propagates to all systems

**Flow:**
```
1. NBC updates policy: Band A threshold changes from $10 → $15
2. CamDX publishes policy update event
3. Webhook received by n8n:
   {
     "event": "policy.updated",
     "policy_id": "amount_band_a_threshold",
     "old_value": 10.00,
     "new_value": 15.00,
     "effective_date": "2025-02-01T00:00:00Z"
   }
4. Update local policy cache
5. No code changes needed (policy-driven)
```

---

## Example Usage

### Example 1: Policy-Driven Transaction Approval

**Prompt:**
```
I have a $250 catering order from an anonymous user. How do I use CamDX to
check if this is allowed and what identity level is required?
```

**Expected Response:**
```
CamDX Policy Check for $250 Anonymous Transaction:

Step 1: Determine Amount Band
$250 falls in Band C ($100-$1,000)

Step 2: Call CamDX Policy API
POST https://camdx.gov.kh/api/v1/policy/check
{
  "identity_level": "anonymous",
  "amount": 250.00,
  "currency": "USD",
  "transaction_type": "e-commerce",
  "merchant_id": "numpang-express-001"
}

Step 3: CamDX Response
{
  "decision": "blocked",
  "amount_band": "C",
  "current_identity_level": "anonymous",
  "required_identity_level": "verified",
  "message": "Band C transactions require verified identity (CamDigiKey)",
  "verification_options": [
    {
      "method": "camdigikey",
      "level": "verified",
      "url": "https://camdigikey.gov.kh/verify"
    }
  ],
  "policy_reference": "NBC-GAAP-2024-L2-P001"
}

Step 4: Handle Blocked Decision
n8n Switch Node:
- Case "blocked":
  → Send Telegram message:
  "⚠️ Identity Verification Required

  For purchases over $100, we need to verify your identity.

  Amount: $250 (Band C)
  Current level: Anonymous
  Required: Verified (CamDigiKey)

  Tap 'Verify Now' to complete verification."

  → Trigger CamDigiKey verification workflow
  → After verification, retry policy check

Step 5: After Verification Complete
POST https://camdx.gov.kh/api/v1/policy/check
{
  "identity_level": "verified",  // Updated
  "amount": 250.00,
  "currency": "USD",
  "transaction_type": "e-commerce",
  "camdigi_key_id": "CDKH-VER-2024-001234"
}

Response:
{
  "decision": "allowed",
  "amount_band": "C",
  "current_identity_level": "verified",
  "required_identity_level": "verified",
  "correlation_id": "CAMDX-2025-C-003456",
  "routing": {
    "payment_rail": "bakong",
    "provider": "NBC",
    "method": "KHQR",
    "timeout_minutes": 30
  }
}

Step 6: Continue with Payment
- Store correlation_id in payment_intents table
- Generate KHQR using Bakong API
- Reference correlation_id in settlement
```

### Example 2: Intent Publishing for Cross-Border Payment

**Prompt:**
```
I need to publish a payment intent to CamDX for a $500 remittance to a family
member in another province. Show me the complete intent structure.
```

**Expected Response:**
```
CamDX Payment Intent for Domestic Remittance:

Intent Structure:
POST https://camdx.gov.kh/api/v1/intents
{
  "intent_id": "PI-20250101-0005",
  "intent_type": "remittance",
  "correlation_id": "CAMDX-2025-REM-001234",

  "sender": {
    "customer_id": "sender_123",
    "identity_level": "verified",
    "camdigi_key_id": "CDKH-VER-2024-001234",
    "account_number": "1234567890",
    "bank": "ABA",
    "location": "Phnom Penh"
  },

  "recipient": {
    "customer_id": "recipient_456",
    "identity_level": "basic",
    "phone_number": "+855 98 765 432",
    "name": "Sok Leang",
    "location": "Siem Reap"
  },

  "transaction": {
    "amount": 500.00,
    "currency": "USD",
    "amount_band": "C",
    "purpose": "family_support",
    "reference": "Monthly support - January"
  },

  "routing": {
    "preferred_rail": "bakong_instant",
    "settlement_speed": "instant",
    "fallback_rails": ["bank_transfer"],
    "max_cost": 2.00  // Max $2 fee
  },

  "compliance": {
    "aml_check_required": true,
    "transaction_limit_check": true,
    "velocity_check": true
  },

  "metadata": {
    "channel": "mobile_app",
    "device_id": "device_abc123",
    "ip_address": "123.45.67.89",
    "timestamp": "2025-01-01T10:00:00Z"
  }
}

CamDX Response:
{
  "status": "accepted",
  "intent_id": "PI-20250101-0005",
  "correlation_id": "CAMDX-2025-REM-001234",

  "routing_decision": {
    "payment_rail": "bakong_instant",
    "provider": "NBC",
    "estimated_settlement": "2025-01-01T10:00:05Z",
    "fee": 0.50,
    "exchange_rate": null
  },

  "compliance_checks": {
    "aml_status": "approved",
    "transaction_limit_ok": true,
    "velocity_ok": true,
    "risk_score": 12  // Low risk
  },

  "next_steps": {
    "action": "generate_payment_instruction",
    "bakong_endpoint": "https://api.bakong.nbc.gov.kh/v1/transfer",
    "timeout": 300
  }
}

n8n Workflow Implementation:
1. Function Node: Generate correlation_id
   const uuid = require('uuid');
   return {
     correlation_id: `CAMDX-${new Date().getFullYear()}-REM-${uuid.v4().substring(0, 6)}`
   };

2. HTTP Request: Publish intent to CamDX
3. PostgreSQL: Store correlation_id
   UPDATE payment_intents
   SET camdx_correlation_id = '{{ $json.correlation_id }}',
       routing_decision = '{{ $json.routing_decision }}',
       compliance_checks = '{{ $json.compliance_checks }}'
   WHERE intent_id = 'PI-20250101-0005';

4. Switch: Route based on payment_rail
   - Case "bakong_instant" → Call Bakong transfer API
   - Case "bank_transfer" → Call bank API
   - Default → Manual processing

5. HTTP Request: Execute transfer via selected rail
6. Webhook: Receive settlement confirmation
7. HTTP Request: Update CamDX with settlement status
   POST https://camdx.gov.kh/api/v1/intents/PI-20250101-0005/settlement
   {
     "correlation_id": "CAMDX-2025-REM-001234",
     "settlement_status": "completed",
     "settlement_id": "BKG-2025-TXN-789012",
     "settled_at": "2025-01-01T10:00:05Z"
   }
```

---

## Best Practices

1. **Always Generate Unique Correlation IDs**
   - Format: `CAMDX-{YEAR}-{TYPE}-{RANDOM}`
   - Store in database for tracing
   - Include in all downstream API calls

2. **Implement Policy Caching**
   - Cache policy responses for 5 minutes
   - Reduces API calls
   - Still check CamDX for high-value transactions

3. **Handle All Policy Decisions**
   - "allowed" → Continue
   - "limited" → Apply restrictions
   - "blocked" → Stop + explain why

4. **Track Routing Decisions**
   - Log which provider was used
   - Measure success rate per provider
   - Optimize routing based on performance

5. **Implement Fallback Gracefully**
   - Don't spam all providers simultaneously
   - Try primary, wait, then fallback
   - Notify CamDX of provider failures

---

## Common Issues & Solutions

**Issue 1: Correlation ID collision**
- **Solution:** Use UUID v4, namespace by year and type

**Issue 2: Policy response cached too long**
- **Solution:** Set TTL to 5 minutes max, clear on policy update events

**Issue 3: Routing decision ignored**
- **Solution:** Respect CamDX routing, log if overridden

**Issue 4: Provider feedback not sent**
- **Solution:** Always report success/failure back to CamDX for optimization

**Issue 5: Webhook delivery failure**
- **Solution:** Implement polling fallback for critical updates

---

## Related Documentation

- CamDX API: `https://camdx.gov.kh/docs`
- CamDX Workflow: `/workflows/g04-camdx-integration/`
- Policy Matrix: `/docs/POLICY_MATRIX.md`
- Database Schema: `/database/schema.sql` (payment_intents table)

---

**Last Updated:** December 2024
**Maintained by:** OmniDM.ai Integration Team
