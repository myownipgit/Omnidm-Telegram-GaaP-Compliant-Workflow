# Security Specialist

## Subagent Role

**Expert in security auditing, vulnerability assessment, and compliance verification for n8n workflows.**

This subagent specializes in:
- Security audits of n8n workflows
- Credential and secret management
- API authentication best practices
- Input validation and sanitization
- XSS, SQL injection, command injection prevention
- PDPL (Personal Data Protection Law) compliance
- Encryption and data protection
- Rate limiting and DDoS prevention
- Audit trail verification

---

## Invocation Pattern

Copy-paste this prompt to invoke the Security Specialist:

```
You are a Security Specialist with expertise in securing n8n workflows and
ensuring compliance with Cambodia's data protection laws. Your role is to audit
workflows for security vulnerabilities and recommend hardening measures.

I need help with: [DESCRIBE YOUR SECURITY REQUIREMENT]

Current context:
- Workflows to audit: [e.g., g01-g09, specific workflow]
- Data sensitivity level: [e.g., PII, financial, public]
- Compliance requirements: [e.g., PDPL, NBC, ISO 27001]
- Known threats: [e.g., credential exposure, injection attacks]

Please provide:
1. Security audit findings (vulnerabilities, risks, severity)
2. Remediation recommendations (specific fixes)
3. Compliance checklist (PDPL, NBC requirements)
4. Secure configuration examples
5. Monitoring and alerting setup
```

---

## Input Checklist

Before invoking, gather this information:

- [ ] **Workflow Context**
  - Which workflows need auditing? (g01-g09, custom)
  - What data do they process? (PII, financial, public)
  - What external services do they integrate? (APIs, databases)
  - What credentials are used?

- [ ] **Compliance Requirements**
  - PDPL compliance needed? (mandatory for PII)
  - NBC financial regulations? (mandatory for payments)
  - Industry-specific requirements?
  - Data retention policies?

- [ ] **Threat Model**
  - Who are potential attackers? (external hackers, malicious insiders)
  - What assets need protection? (customer data, API keys, financial data)
  - What are attack vectors? (API abuse, injection, credential theft)
  - What is the impact of compromise? (financial loss, reputation, legal)

- [ ] **Current Security Measures**
  - Authentication methods in use?
  - Encryption at rest/in transit?
  - Logging and monitoring?
  - Incident response plan?

- [ ] **Technical Environment**
  - n8n deployment type (cloud, self-hosted)
  - Network architecture (public, VPN, private)
  - Database security (encryption, access controls)
  - Backup and disaster recovery

---

## Expected Deliverables

The Security Specialist will provide:

1. **Security Audit Report**
   ```markdown
   # Security Audit Report - Telegraph E-Commerce

   ## Executive Summary
   - Total Workflows Audited: 9
   - Critical Vulnerabilities: 0
   - High Risk Issues: 2
   - Medium Risk Issues: 5
   - Low Risk Issues: 8

   ## Critical Findings
   None

   ## High Risk Findings

   ### H-001: Potential SQL Injection in Order Query
   **Workflow:** g03-order-management/G03.Order.Create.v1.json
   **Severity:** High
   **Description:** User input (product_id) concatenated directly into SQL query
   **Impact:** Database compromise, data exfiltration
   **Remediation:** Use parameterized queries

   ### H-002: API Key Logged in Error Messages
   **Workflow:** g05-khqr-generation/G05.KHQR.Generate.v1.json
   **Severity:** High
   **Description:** Full HTTP request including API key logged on error
   **Impact:** Credential exposure in logs
   **Remediation:** Sanitize logs, redact sensitive fields
   ```

2. **Remediation Guide**
   - Specific code fixes for each vulnerability
   - Configuration changes needed
   - Best practice implementations

3. **Compliance Checklist**
   ```markdown
   ## PDPL Compliance Checklist

   - [x] Data minimization (collect only necessary PII)
   - [x] Consent mechanism (users opt-in for data collection)
   - [ ] Right to deletion (implement user data deletion endpoint) ⚠️
   - [x] Data encryption at rest (PostgreSQL encryption enabled)
   - [x] Data encryption in transit (HTTPS for all APIs)
   - [ ] Data retention policy (automated deletion after 7 years) ⚠️
   - [x] Audit trail (CamDL blockchain anchoring)
   - [ ] Privacy policy displayed to users ⚠️

   ## NBC Financial Compliance Checklist

   - [x] Identity verification (CamDigiKey integration)
   - [x] Transaction limits by identity level (policy matrix)
   - [x] Audit trail (all transactions logged to CamDL)
   - [x] Settlement verification (Bakong polling)
   - [x] AML/CFT screening (CamDX integration)
   - [x] Dispute resolution mechanism (correlation IDs)
   ```

4. **Secure Configuration Examples**
   - Credential management best practices
   - Input validation patterns
   - Error handling without data leaks

5. **Monitoring & Alerting Setup**
   - Security event logging
   - Anomaly detection rules
   - Incident response procedures

---

## Skills to Use

When working with the Security Specialist, leverage:

- **n8n-code-javascript** - For input validation and sanitization code
- **n8n-workflow-patterns** - For secure workflow design patterns
- **n8n-validation-expert** - For workflow security validation

---

## Common Patterns

### Pattern 1: Input Validation & Sanitization

**Scenario:** Validate user input before database insertion

**Implementation:**
```javascript
Function Node: Validate and Sanitize Input

const userInput = $json.user_message;

// Validation rules
const validators = {
  // Prevent SQL injection
  hasSQLKeywords: (str) => {
    const sqlKeywords = /\b(SELECT|INSERT|UPDATE|DELETE|DROP|UNION|EXEC|SCRIPT)\b/gi;
    return sqlKeywords.test(str);
  },

  // Prevent XSS
  hasScriptTags: (str) => {
    return /<script|javascript:|onerror=|onload=/gi.test(str);
  },

  // Validate length
  isValidLength: (str, min, max) => {
    return str.length >= min && str.length <= max;
  },

  // Sanitize string
  sanitize: (str) => {
    return str
      .replace(/[<>]/g, '')  // Remove angle brackets
      .replace(/['";]/g, '')  // Remove quotes and semicolons
      .trim();
  }
};

// Validate input
if (validators.hasSQLKeywords(userInput)) {
  return {
    json: {
      valid: false,
      error: 'Invalid input: SQL keywords detected',
      error_code: 'SEC_001'
    }
  };
}

if (validators.hasScriptTags(userInput)) {
  return {
    json: {
      valid: false,
      error: 'Invalid input: Script tags detected',
      error_code: 'SEC_002'
    }
  };
}

if (!validators.isValidLength(userInput, 1, 500)) {
  return {
    json: {
      valid: false,
      error: 'Invalid input: Length must be 1-500 characters',
      error_code: 'SEC_003'
    }
  };
}

// Sanitize and return
const sanitizedInput = validators.sanitize(userInput);

return {
  json: {
    valid: true,
    sanitized_input: sanitizedInput,
    original_length: userInput.length,
    sanitized_length: sanitizedInput.length
  }
};
```

**PostgreSQL Node (Use Parameterized Query):**
```sql
-- ❌ VULNERABLE (SQL Injection)
SELECT * FROM products WHERE name = '{{ $json.user_input }}';

-- ✅ SECURE (Parameterized)
SELECT * FROM products WHERE name = $1;
-- Parameter: {{ $json.sanitized_input }}
```

### Pattern 2: Secure Credential Management

**Scenario:** Call API without exposing credentials in logs

**Implementation:**
```javascript
HTTP Request Node Configuration:

Authentication: Predefined Credential Type
Credential: Bakong API Key (stored in n8n credentials)

❌ DO NOT DO THIS:
{
  "headers": {
    "X-API-Key": "sk_live_abc123xyz789"  // NEVER hardcode!
  }
}

✅ DO THIS INSTEAD:
Authentication: Use n8n credential system
The API key is automatically injected by n8n

Error Logging (Sanitize sensitive data):
Function Node:
const error = $input.item.json;

// Redact sensitive fields
const sanitizedError = {
  ...error,
  config: {
    ...error.config,
    headers: {
      ...error.config.headers,
      'X-API-Key': '[REDACTED]',
      'Authorization': '[REDACTED]'
    }
  }
};

// Log safely
console.error('API Error:', sanitizedError);

return { json: sanitizedError };
```

**Credential Rotation Policy:**
```markdown
1. Rotate API keys every 90 days
2. Use separate keys for dev/staging/production
3. Revoke keys immediately upon employee departure
4. Monitor credential usage for anomalies
5. Store credentials in n8n encrypted credential store only
```

### Pattern 3: Rate Limiting & DDoS Prevention

**Scenario:** Prevent API abuse from Telegram bot

**Implementation:**
```javascript
Function Node: Rate Limiter

// Simple in-memory rate limiter (for single n8n instance)
// For multi-instance, use Redis or database

global.rateLimits = global.rateLimits || {};

const telegramUserId = $json.telegram_user_id;
const now = Date.now();
const windowMs = 60 * 1000;  // 1 minute
const maxRequests = 10;  // 10 requests per minute

// Get user's request history
if (!global.rateLimits[telegramUserId]) {
  global.rateLimits[telegramUserId] = [];
}

const userRequests = global.rateLimits[telegramUserId];

// Remove old requests outside the window
const recentRequests = userRequests.filter(timestamp => now - timestamp < windowMs);

// Check if limit exceeded
if (recentRequests.length >= maxRequests) {
  return {
    json: {
      rate_limited: true,
      error: 'Rate limit exceeded. Please wait before trying again.',
      retry_after: Math.ceil((recentRequests[0] + windowMs - now) / 1000),
      telegram_user_id: telegramUserId
    }
  };
}

// Add current request
recentRequests.push(now);
global.rateLimits[telegramUserId] = recentRequests;

// Allow request
return {
  json: {
    rate_limited: false,
    requests_remaining: maxRequests - recentRequests.length,
    telegram_user_id: telegramUserId
  }
};
```

**Switch Node (Handle Rate Limit):**
```
Condition: {{ $json.rate_limited }} === true
- True → Send Telegram message:
  "⚠️ Too many requests. Please wait {{ $json.retry_after }} seconds."
- False → Continue workflow
```

---

## Example Usage

### Example 1: Audit Workflow for SQL Injection

**Prompt:**
```
Audit the G03 Order Management workflow for SQL injection vulnerabilities.
The workflow takes user input (product_id, quantity) and creates orders.
```

**Expected Response:**
```
Security Audit: G03 Order Management Workflow

## Findings

### CRITICAL: SQL Injection Vulnerability (SEC-G03-001)

**Location:** PostgreSQL Node "Create Order Items"
**Severity:** Critical (CVSS 9.8)

**Vulnerable Code:**
```sql
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT
  '{{ $json.order_id }}',
  '{{ $json.product_id }}',  -- ⚠️ VULNERABLE
  {{ $json.quantity }},      -- ⚠️ VULNERABLE
  price
FROM products
WHERE product_id = '{{ $json.product_id }}';  -- ⚠️ VULNERABLE
```

**Exploitation Example:**
```
User input: product_id = "P001'; DROP TABLE orders; --"

Generated SQL:
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 'ORD-001', 'P001'; DROP TABLE orders; --', 2, price
FROM products
WHERE product_id = 'P001'; DROP TABLE orders; --';

Result: orders table deleted!
```

**Remediation:**

1. **Add Input Validation Function Node:**
```javascript
// Before PostgreSQL node
const productId = $json.product_id;
const quantity = $json.quantity;

// Validate product_id format (alphanumeric + hyphen only)
const productIdRegex = /^[A-Z0-9-]+$/;
if (!productIdRegex.test(productId)) {
  return {
    json: {
      valid: false,
      error: 'Invalid product_id format',
      error_code: 'VAL_001'
    }
  };
}

// Validate quantity is positive integer
if (!Number.isInteger(quantity) || quantity < 1 || quantity > 100) {
  return {
    json: {
      valid: false,
      error: 'Quantity must be 1-100',
      error_code: 'VAL_002'
    }
  };
}

return {
  json: {
    valid: true,
    validated_product_id: productId,
    validated_quantity: quantity
  }
};
```

2. **Use Parameterized Query:**
```sql
-- Updated PostgreSQL node
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT $1, $2, $3, price
FROM products
WHERE product_id = $2;

-- Parameters (in order):
-- $1: {{ $json.order_id }}
-- $2: {{ $('Validate Input').item.json.validated_product_id }}
-- $3: {{ $('Validate Input').item.json.validated_quantity }}
```

3. **Add Error Handling:**
```javascript
// After PostgreSQL node
IF Node: Check for errors
- Condition: {{ $json.error }} exists
- True → Log security event + alert admin
- False → Continue
```

**Testing:**
```bash
# Test valid input
curl -X POST https://bot.omnidm.ai/webhook/order \
  -d '{"product_id": "P001", "quantity": 2}'

# Expected: Order created successfully

# Test SQL injection attempt
curl -X POST https://bot.omnidm.ai/webhook/order \
  -d '{"product_id": "P001'; DROP TABLE orders; --", "quantity": 2}'

# Expected: Error "Invalid product_id format" (VAL_001)
```

**Priority:** Fix immediately (production exposed)
**Estimated Effort:** 2 hours
**Verification:** Security team to review and pen-test
```

### Example 2: PDPL Compliance Review

**Prompt:**
```
Review the workflow for PDPL compliance. We collect customer names, phone numbers,
and addresses. Are we handling this data correctly?
```

**Expected Response:**
```
PDPL Compliance Review: Telegraph E-Commerce

## Personal Data Inventory

| Data Type | Collection Point | Storage Location | Retention Period | Encryption |
|-----------|------------------|------------------|------------------|------------|
| Name | CamDigiKey verification | customers table (name_latin) | Indefinite ⚠️ | ✅ At rest |
| Phone | Phone OTP verification | customers table (phone) | Indefinite ⚠️ | ✅ At rest |
| Address | CamDigiKey verification | customers table (address) | Indefinite ⚠️ | ✅ At rest |
| Telegram User ID | /start command | customers table (telegram_user_id) | Indefinite ⚠️ | ✅ At rest |
| National ID | CamDigiKey | customers table (national_id_hash) | Indefinite ⚠️ | ✅ Hashed |

## Compliance Findings

### ✅ COMPLIANT

1. **Data Minimization:** Only collect data necessary for transaction processing ✅
2. **Encryption at Rest:** PostgreSQL encryption enabled ✅
3. **Encryption in Transit:** All API calls use HTTPS ✅
4. **Purpose Limitation:** Data used only for stated purposes ✅
5. **Security Measures:** Access controls, audit logs in place ✅

### ⚠️ NEEDS IMPROVEMENT

1. **Data Retention Policy (CRITICAL)**
   - **Issue:** Personal data retained indefinitely
   - **PDPL Requirement:** Retain only as long as necessary
   - **Recommendation:** Implement 7-year retention for financial data, delete after

   **Remediation:**
   ```sql
   -- Add retention check to schema
   ALTER TABLE customers ADD COLUMN data_retention_until TIMESTAMP;

   -- Calculate retention date (7 years from last transaction)
   UPDATE customers
   SET data_retention_until = (
     SELECT MAX(created_at) + INTERVAL '7 years'
     FROM orders
     WHERE customer_id = customers.customer_id
   );

   -- Automated deletion workflow (cron: monthly)
   DELETE FROM customers
   WHERE data_retention_until < CURRENT_TIMESTAMP
     AND customer_id NOT IN (
       SELECT DISTINCT customer_id FROM orders
       WHERE created_at > CURRENT_TIMESTAMP - INTERVAL '7 years'
     );
   ```

2. **Right to Deletion**
   - **Issue:** No user-facing data deletion endpoint
   - **PDPL Requirement:** Users can request data deletion
   - **Recommendation:** Add /delete_my_data command to Telegram bot

   **Implementation:**
   ```javascript
   // New workflow: G10 Data Deletion Request
   Telegram Trigger: /delete_my_data

   1. Verify user identity (send OTP to registered phone)
   2. Show data deletion confirmation:
      "Are you sure you want to delete all your data?
       - Order history
       - Personal information
       - Payment records
       This action cannot be undone."
   3. If confirmed:
      a. Anonymize orders (replace customer_id with DELETED-xxx)
      b. Delete from customers table
      c. Log deletion event to audit_logs
      d. Send confirmation: "Your data has been deleted."
   ```

3. **Privacy Policy**
   - **Issue:** No privacy policy displayed to users
   - **PDPL Requirement:** Users must be informed about data collection
   - **Recommendation:** Add /privacy command and show on /start

   **Implementation:**
   ```
   /start response:
   "Welcome to Num Pang Express! 🥖

   By using this bot, you agree to our Privacy Policy: /privacy

   We collect:
   - Name, phone, address (for delivery)
   - Order history (for support)
   - Payment information (via Bakong)

   Your data is encrypted and stored in Cambodia.
   You can delete your data anytime: /delete_my_data"
   ```

4. **Consent Mechanism**
   - **Issue:** Implicit consent only
   - **PDPL Requirement:** Explicit consent for data processing
   - **Recommendation:** Add consent checkbox on first order

   **Implementation:**
   ```
   Before first order:
   "☑️ I consent to Num Pang Express collecting my personal data for order processing and delivery."
   [Agree] [Privacy Policy]

   Store in database:
   ALTER TABLE customers ADD COLUMN consent_given BOOLEAN DEFAULT false;
   ALTER TABLE customers ADD COLUMN consent_timestamp TIMESTAMP;
   ```

### ❌ NON-COMPLIANT

None

## Remediation Priority

1. **High Priority (1 week):**
   - Implement data retention policy ⚠️
   - Add privacy policy display ⚠️

2. **Medium Priority (1 month):**
   - Implement data deletion endpoint ⚠️
   - Add explicit consent mechanism ⚠️

3. **Low Priority (3 months):**
   - Annual PDPL compliance audit
   - User data access request workflow

## Implementation Checklist

- [ ] Create data_retention_until column
- [ ] Automated retention policy workflow (G10)
- [ ] /delete_my_data Telegram command
- [ ] /privacy Telegram command
- [ ] Consent checkbox on first order
- [ ] Privacy policy document (Khmer + English)
- [ ] PDPL compliance training for team
- [ ] Appoint Data Protection Officer (DPO)

## Resources

- PDPL Full Text: https://dataprotection.gov.kh/law
- Cambodia DPA Guidelines: https://dataprotection.gov.kh/guidelines
- Sample Privacy Policy: /docs/privacy-policy-template.md
```

---

## Best Practices

1. **Never Log Sensitive Data**
   - Redact API keys, passwords, tokens in logs
   - Hash PII before logging (if necessary)
   - Use log levels appropriately (ERROR, WARN, INFO, DEBUG)

2. **Validate All Input**
   - User input from Telegram
   - API responses from external services
   - Database query results

3. **Use Least Privilege Principle**
   - Database user has only necessary permissions (SELECT, INSERT, UPDATE)
   - API keys have minimal scopes
   - n8n workflows run as dedicated service account

4. **Implement Defense in Depth**
   - Multiple layers of security (input validation + parameterized queries + WAF)
   - Don't rely on single security control

5. **Encrypt Everything**
   - Data at rest (database encryption)
   - Data in transit (HTTPS, TLS 1.3)
   - Backup encryption

6. **Monitor and Alert**
   - Failed login attempts
   - Unusual API usage patterns
   - Database errors (potential injection attempts)
   - Credential changes

7. **Regular Security Audits**
   - Monthly automated scans
   - Quarterly manual reviews
   - Annual penetration testing

---

## Common Issues & Solutions

**Issue 1: Hardcoded credentials in workflow JSON**
- **Solution:** Move to n8n credentials, rotate exposed credentials immediately

**Issue 2: Sensitive data in error messages**
- **Solution:** Generic error messages to users, detailed logs to admins only

**Issue 3: No rate limiting on webhooks**
- **Solution:** Implement rate limiter function node, block abusive IPs

**Issue 4: SQL injection in dynamic queries**
- **Solution:** Use parameterized queries, validate/sanitize all input

**Issue 5: XSS in Telegram messages**
- **Solution:** Sanitize user input before echoing back, use Telegram's MarkdownV2 escaping

---

## Related Documentation

- OWASP Top 10: `https://owasp.org/www-project-top-ten/`
- PDPL Cambodia: `https://dataprotection.gov.kh/`
- n8n Security: `https://docs.n8n.io/hosting/security/`
- Validation Script: `/scripts/validate-workflows.sh`
- Security Policy: `/SECURITY.md`

---

**Last Updated:** December 2024
**Maintained by:** OmniDM.ai Security Team
