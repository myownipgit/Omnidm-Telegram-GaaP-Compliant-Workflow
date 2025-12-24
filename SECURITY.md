# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

---

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly:

### DO NOT:
- ❌ Open a public GitHub issue
- ❌ Disclose the vulnerability publicly
- ❌ Share details on social media

### DO:
1. **Email:** contact@omnidm.ai
2. **Subject:** `[SECURITY] Vulnerability Report - Cambodia GaaP Workflows`
3. **Include:**
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if available)

### Response Timeline:
- **Initial Response:** Within 48 hours
- **Status Update:** Within 7 days
- **Fix Timeline:** Depends on severity (critical: 24-72 hours)

---

## Security Best Practices

### For Developers

#### 1. Never Commit Credentials

```bash
# Always check before committing
git diff
git status

# Use .gitignore
config/credentials.json
.env
*.pem
*.key
```

#### 2. Use Environment Variables

```javascript
// Good ✅
const apiKey = process.env.CAMDX_API_KEY;

// Bad ❌
const apiKey = "actual-api-key-here";
```

#### 3. Use n8n Credential System

All API credentials should be stored in n8n's encrypted credential system, not hardcoded in workflows.

#### 4. Validate Input

```javascript
// Always validate and sanitize user input
const userInput = $json.message.text.trim();
if (!userInput.match(/^[1-5]$/)) {
  throw new Error('Invalid input');
}
```

#### 5. Rate Limiting

Implement rate limiting for all public-facing workflows:

```javascript
// Track requests per user
const userId = $json.from.id;
const requestCount = await getRequestCount(userId);
if (requestCount > 10) {
  throw new Error('Rate limit exceeded');
}
```

---

## Security Considerations by Component

### Telegram Bot

**Risks:**
- Bot token exposure
- Message interception
- Spam/abuse
- Data leakage

**Mitigations:**
- Use HTTPS webhooks only
- Validate all incoming messages
- Implement rate limiting
- Store token in n8n credentials
- Enable Telegram's built-in privacy settings

### CamDX Integration

**Risks:**
- API key exposure
- Man-in-the-middle attacks
- Data tampering

**Mitigations:**
- Use mTLS certificates
- Validate API responses
- Implement request signing
- Monitor for anomalies

### Bakong/KHQR

**Risks:**
- Payment fraud
- QR code manipulation
- Settlement verification bypass

**Mitigations:**
- Validate MD5 hashes
- Verify settlement with Bakong API
- Implement timeout checks
- Log all payment events to CamDL

### Database

**Risks:**
- SQL injection
- Data breach
- Unauthorized access

**Mitigations:**
- Use parameterized queries
- Enable encryption at rest
- Use strong passwords
- Restrict network access
- Regular backups

### n8n Instance

**Risks:**
- Unauthorized workflow access
- Credential theft
- Workflow manipulation

**Mitigations:**
- Enable basic authentication
- Use HTTPS only
- Restrict IP access
- Regular updates
- Audit logs enabled

---

## Compliance Requirements

### Cambodia PDPL (Personal Data Protection Law)

This project handles personal data and must comply with Cambodia's PDPL:

1. **Data Minimization:** Only collect necessary data
2. **User Consent:** Obtain explicit consent for data collection
3. **Data Security:** Implement appropriate security measures
4. **Data Access:** Allow users to access their data
5. **Data Deletion:** Allow users to request data deletion
6. **Breach Notification:** Report breaches within 72 hours

### Implementation:

```javascript
// Example: Data minimization
const userProfile = {
  user_id: $json.from.id,
  // DO NOT store: phone number, email (unless explicitly needed)
};

// Example: User consent
const consentText = "By using this bot, you agree to our Privacy Policy";
```

### GaaP Layer 4 Compliance (Audit & Tax)

All transactions MUST be logged to CamDL for immutability:

```javascript
// Workflow 09: Audit Logger
const auditEvent = {
  event_type: 'payment_intent_created',
  intent_id: $json.intent_id,
  timestamp: new Date().toISOString(),
  hash: sha256(JSON.stringify(eventData))
};

// Submit to CamDL blockchain
await submitToCamDL(auditEvent);
```

---

## Vulnerability Disclosure

### Known Issues

| Issue | Severity | Status | Fix Version |
|-------|----------|--------|-------------|
| None  | -        | -      | -           |

### Previous Vulnerabilities

| CVE | Description | Severity | Fixed In |
|-----|-------------|----------|----------|
| -   | -           | -        | -        |

---

## Security Checklist for Deployment

Before deploying to production:

### Infrastructure

- [ ] HTTPS enabled with valid SSL certificate
- [ ] Firewall configured (only ports 443, 22)
- [ ] SSH key authentication only (no password)
- [ ] n8n basic auth enabled with strong password
- [ ] PostgreSQL user has minimal permissions
- [ ] Redis password protection enabled
- [ ] Backup strategy in place
- [ ] Monitoring and alerting configured

### Application

- [ ] All credentials stored in n8n vault
- [ ] No hardcoded secrets in workflows
- [ ] Environment variables used for configuration
- [ ] Rate limiting implemented
- [ ] Input validation on all user inputs
- [ ] Error messages don't leak sensitive info
- [ ] Logging excludes PII data
- [ ] CORS properly configured

### Telegram Bot

- [ ] Bot token regenerated (not using example token)
- [ ] Webhook uses HTTPS
- [ ] Bot privacy mode enabled (@BotFather)
- [ ] Rate limiting per user
- [ ] Message validation implemented
- [ ] No sensitive data in bot responses

### API Integrations

- [ ] CamDX: mTLS certificates configured
- [ ] Bakong: API key rotated
- [ ] CamDigiKey: OAuth2 properly configured
- [ ] Grab: API credentials secured
- [ ] All API endpoints use HTTPS
- [ ] Request/response logging (excluding auth headers)

### Compliance

- [ ] Privacy policy published
- [ ] Terms of service published
- [ ] User consent mechanism implemented
- [ ] Data retention policy defined
- [ ] Data deletion procedure documented
- [ ] PDPL compliance verified
- [ ] Audit logs enabled

---

## Incident Response Plan

### If Credentials Are Compromised:

1. **Immediate Actions (0-1 hour):**
   - Revoke compromised credentials
   - Generate new credentials
   - Update all systems
   - Notify affected users (if applicable)

2. **Investigation (1-24 hours):**
   - Review access logs
   - Identify scope of breach
   - Document timeline
   - Preserve evidence

3. **Remediation (1-7 days):**
   - Implement fixes
   - Enhanced monitoring
   - Security audit
   - Post-mortem report

4. **Notification (24-72 hours):**
   - Report to authorities (if required by PDPL)
   - Notify affected users
   - Public disclosure (if necessary)

---

## Contact

- **Security Email:** contact@omnidm.ai
- **PGP Key:** (To be added)
- **Response Time:** 48 hours

---

## Updates

This security policy is reviewed quarterly. Last updated: 2025-12-24

---

## Acknowledgments

We appreciate responsible security researchers who help us keep this project secure.

### Hall of Fame

(No vulnerabilities reported yet)

---

**For immediate security concerns, read [SECURITY_ALERT.md](SECURITY_ALERT.md)**
