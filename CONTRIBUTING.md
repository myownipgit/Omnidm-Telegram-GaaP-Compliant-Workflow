# Contributing to OmniDM.ai Telegram GaaP Workflow

Thank you for your interest in contributing to Cambodia's first open-source GaaP-compliant conversational commerce platform!

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Workflow Development Guidelines](#workflow-development-guidelines)
- [GaaP Compliance Requirements](#gaap-compliance-requirements)
- [Submission Process](#submission-process)

---

## Code of Conduct

This project adheres to the Contributor Covenant Code of Conduct. By participating, you are expected to uphold this code.

---

## How Can I Contribute?

### Priority Areas

We welcome contributions in these areas:

1. **Real API Integration**
   - CamDX API integration (replace httpbin.org mock)
   - Bakong/KHQR real payment rails
   - CamDigiKey OAuth2 flow
   - CamDL blockchain anchoring
   - Grab API delivery integration

2. **Additional Channels**
   - WhatsApp Business API
   - Meta Messenger
   - Instagram DM
   - TikTok Shop integration

3. **Compliance Features**
   - CamInvoice integration (May 2025 mandate)
   - Credit Bureau Cambodia integration
   - Enhanced audit logging
   - PDPL compliance features

4. **Testing & Documentation**
   - Integration tests
   - API endpoint tests
   - Additional test scenarios
   - Localization (Khmer language)

5. **Bug Fixes**
   - Workflow execution errors
   - Data validation issues
   - Performance optimizations

---

## Development Setup

### Prerequisites

- n8n v1.0 or higher
- Node.js v18+
- Docker (optional)
- Git

### Local Setup

```bash
# 1. Fork and clone the repository
git clone https://github.com/YOUR_USERNAME/Omnidm-Telegram-GaaP-Compliant-Workflow.git
cd Omnidm-Telegram-GaaP-Compliant-Workflow

# 2. Start n8n
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -v $(pwd)/workflows:/workflows \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n

# 3. Import workflows
# Via n8n UI: Workflows → Import from File → Select /workflows/*.json

# 4. Configure credentials
cp config/credentials.example.json config/credentials.json
# Edit credentials.json with your API keys
```

---

## Workflow Development Guidelines

### Naming Convention

All workflows MUST follow the GaaP naming convention:

```
[KH.GaaS] <tenant> :: <group> :: <purpose> (v<version>)
```

Example:
```
[KH.GaaS] omnidm.ai :: 01 Channel Ingress :: Telegram Num Pang Commerce (v1)
```

### Node Naming

All nodes within workflows should use consistent prefixes:

| Workflow | Prefix | Example |
|----------|--------|---------|
| 01 Channel Ingress | `ING:` | `ING: Parse User Message` |
| 02 Identity & Policy | `ID:` | `ID: Evaluate Policy Matrix` |
| 03 Intent Builder | `PI:` | `PI: Build Canonical PaymentIntent` |
| 04 CamDX Publish | `DX:` | `DX: Mock CamDX Publish` |
| 05 KHQR Generator | `QR:` | `QR: Build KHQR Payload` |
| 06 Deliver to Telegram | `DEL:` | `DEL: Send to Telegram` |
| 07 Settlement Verify | `SETTLE:` | `SETTLE: Check Bakong MD5` |
| 08 Fulfillment | `FUL:` | `FUL: Mock Grab API` |
| 09 Audit Logger | `AUD:` | `AUD: Build Audit Event` |

### Tagging Requirements

All workflows MUST include these tags:

**Core Tags:**
- `kh-gaap` - Cambodia Government-as-a-Platform
- `tenant:omnidm.ai` - Tenant identifier
- `compliance:level-5` - Compliance maturity level

**Group Tags:**
- `grp:01-ingress` through `grp:09-audit`

**Type Tags:**
- `type:orchestrator` - Main workflow
- `type:component` - Reusable component
- `type:daemon` - Background process

**Data Classification:**
- `data-class:public`
- `data-class:internal`
- `data-class:personal`
- `data-class:sensitive`
- `data-class:regulated`

**Rail Integration:**
- `rail:camdigikey`
- `rail:camdx`
- `rail:bakong`
- `rail:khqr`
- `rail:camdl`
- `rail:grab`

---

## GaaP Compliance Requirements

### 8-Layer Architecture

Ensure your contribution aligns with Cambodia's GaaP framework:

| Layer | Component | Requirement |
|-------|-----------|-------------|
| Layer 0 | Legal & Governance | Consumer protection, T&C |
| Layer 1 | Identity | CamDigiKey integration |
| Layer 2 | Interoperability | CamDX data exchange |
| Layer 3 | Payments | Bakong + KHQR |
| Layer 4 | Compliance | CamDL audit logging |
| Layer 5 | Credit | Credit Bureau integration |
| Layer 6 | Sectoral APIs | Grab, delivery, logistics |
| Layer 7 | Applications | Telegram, WhatsApp, etc. |

### Policy Threshold Matrix

All payment workflows MUST enforce the CamDX policy matrix:

| Amount Band | Range | Anonymous | Basic | Verified | High Assurance |
|-------------|-------|-----------|-------|----------|----------------|
| **A** | ≤ $10 | ✅ Allowed | ✅ Allowed | ✅ Allowed | ✅ Allowed |
| **B** | $10-100 | ⚠️ Limited | ✅ Allowed | ✅ Allowed | ✅ Allowed |
| **C** | $100-1K | ❌ Blocked | ⚠️ Limited | ✅ Allowed | ✅ Allowed |
| **D** | > $1,000 | ❌ Blocked | ❌ Blocked | ⚠️ Limited | ✅ Allowed |

### Audit Requirements

All transactions MUST:
1. Generate unique correlation IDs
2. Log to CamDL blockchain
3. Include SHA256 hash
4. Store immutable receipts
5. Enable compliance dashboard reporting

---

## Submission Process

### 1. Create a Feature Branch

```bash
git checkout -b feature/your-feature-name
```

### 2. Make Your Changes

- Follow naming conventions
- Add appropriate tags
- Include documentation
- Test thoroughly

### 3. Test Your Workflow

```bash
# Import to n8n
# Execute workflow manually
# Verify output schemas
# Check audit logs
```

### 4. Export Workflow

```bash
# Export from n8n UI
# Or use CLI:
n8n export:workflow --id=YOUR_WORKFLOW_ID --output=./workflows/
```

### 5. Commit Changes

```bash
git add .
git commit -m "feat: Add WhatsApp channel integration"

# Commit message format:
# feat: New feature
# fix: Bug fix
# docs: Documentation update
# refactor: Code refactoring
# test: Test additions
```

### 6. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub with:
- Clear description of changes
- Screenshots/videos if UI changes
- Test results
- Compliance checklist

---

## Pull Request Checklist

Before submitting, ensure:

- [ ] Workflow follows GaaP naming convention
- [ ] All nodes have appropriate prefixes
- [ ] Compliance tags are applied
- [ ] Documentation is updated
- [ ] Workflow has been tested
- [ ] No credentials are committed
- [ ] Code follows existing patterns
- [ ] Audit logging is implemented
- [ ] Error handling is included
- [ ] JSON is properly formatted

---

## Questions?

- **Project Issues:** https://github.com/myownipgit/Omnidm-Telegram-GaaP-Compliant-Workflow/issues
- **Email:** contact@omnidm.ai
- **Company:** https://camfintech.com

---

Thank you for contributing to Cambodia's digital economy!
