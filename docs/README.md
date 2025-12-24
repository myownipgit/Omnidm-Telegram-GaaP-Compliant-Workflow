# OmniDM.ai - Telegram GaaP-Compliant Workflow

🇰🇭 **Cambodia Government-as-a-Platform (GaaP) Compliant E-Commerce via Telegram**

A proof-of-concept implementation of conversational commerce on Telegram, fully aligned with Cambodia's national digital infrastructure (CamDX, Bakong, KHQR, CamDigiKey, CamDL).

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![n8n](https://img.shields.io/badge/n8n-v1.0+-orange.svg)](https://n8n.io)
[![Cambodia GaaP](https://img.shields.io/badge/Cambodia-GaaP%20Compliant-blue.svg)](https://www.techostartup.center)

---

## 🎯 Project Overview

**OmniDM.ai** is a multi-channel conversational commerce platform that enables Cambodian SMEs to conduct compliant e-commerce through direct messaging channels (Telegram, WhatsApp, Meta Messenger, Instagram, TikTok).

This repository demonstrates a **Telegram-based food delivery service** ("Num Pang Express") built with **9 modular n8n workflows** that implement Cambodia's **8-layer GaaP FinTech architecture**.

### **Key Features**

✅ **GaaP Compliant:** Implements all 8 layers of Cambodia's Government-as-a-Platform architecture
✅ **Policy-Driven:** Automated identity threshold enforcement via CamDX Policy Matrix
✅ **Audit-Ready:** Immutable blockchain logging via CamDL
✅ **Payment Rails:** KHQR + Bakong settlement integration
✅ **Delivery Integration:** Grab API integration for fulfillment
✅ **Modular Design:** 9 reusable workflow components

---

## 🏛️ GaaP Architecture Alignment

This implementation maps to Cambodia's national digital rails:

| GaaP Layer | Component | Workflow Implementation |
|------------|-----------|-------------------------|
| **Layer 0: Legal** | E-Commerce Law (2019) | Consumer protection controls in WF-01 |
| **Layer 1: Identity** | **CamDigiKey** | Identity verification in WF-02 |
| **Layer 2: Interoperability** | **CamDX** | Data exchange in WF-03, WF-04 |
| **Layer 3: Payments** | **Bakong + KHQR** | QR generation (WF-05), Settlement (WF-07) |
| **Layer 4: Compliance** | **CamDL + CamInvoice** | Audit logging in WF-09 |
| **Layer 5: Credit** | Credit Bureau Cambodia | (Future integration) |
| **Layer 6: Sectoral** | Grab API | Delivery fulfillment in WF-08 |
| **Layer 7: Applications** | Telegram Bot | User interface in WF-01, WF-06 |

---

## 🛠️ Technology Stack

- **Workflow Engine:** [n8n](https://n8n.io) (open-source workflow automation)
- **Messaging:** Telegram Bot API
- **Mock Rails:** httpbin.org (for CamDX, Bakong, CamDigiKey, CamDL)
- **Delivery:** Grab Express API (integration-ready)
- **Language:** JavaScript (n8n Code nodes)

---

## 📋 Workflow Architecture

### **9 Core Workflows**

| # | Workflow | Purpose | Type | GaaP Layer |
|---|----------|---------|------|------------|
| **01** | Channel Ingress | Receive Telegram messages, normalize to `commerce.request` | Orchestrator | Layer 7 |
| **02** | Identity & Policy | CamDX threshold evaluation, CamDigiKey verification | Component | Layer 1 |
| **03** | Intent Builder | Build canonical `camdx.payment_intent` | Component | Layer 2 |
| **04** | CamDX Publish | Publish intent to CamDX, receive correlation ID | Component | Layer 2 |
| **05** | KHQR Generator | Generate KHQR QR code + Bakong deeplink | Component | Layer 3 |
| **06** | Deliver to Telegram | Send payment QR to customer | Component | Layer 7 |
| **07** | Settlement Verification | Poll Bakong for payment confirmation (daemon) | Daemon | Layer 3 |
| **08** | Fulfillment | Trigger Grab delivery, release order | Component | Layer 6 |
| **09** | Audit Logger | Log events to CamDL blockchain | Component | Layer 4 |

### **Data Flow**

```
┌─────────────────────────────────────────────────────────────────┐
│  User (Telegram)                                                 │
└────────────┬────────────────────────────────────────────────────┘
             │
             ▼
    ┌────────────────┐
    │  WF-01: Ingress│  ← commerce.request
    └────────┬───────┘
             │
             ▼
    ┌────────────────┐
    │ WF-02: Identity│  ← CamDX Policy Matrix
    └────────┬───────┘
             │
             ▼
    ┌────────────────┐
    │ WF-03: Intent  │  ← camdx.payment_intent
    └────────┬───────┘
             │
             ▼
    ┌────────────────┐
    │ WF-04: Publish │  ← CamDX correlation_id
    └────────┬───────┘
             │
             ▼
    ┌────────────────┐
    │  WF-05: KHQR   │  ← KHQR QR + deeplink
    └────────┬───────┘
             │
             ▼
    ┌────────────────┐
    │ WF-06: Deliver │  → Send to Telegram
    └────────────────┘
             │
    ┌────────▼───────┐     ┌────────────────┐
    │ WF-07: Verify  │────▶│  WF-08: Fulfill│
    └────────────────┘     └────────┬───────┘
             │                       │
             ▼                       ▼
    ┌────────────────┐     ┌────────────────┐
    │  WF-09: Audit  │     │  Grab Delivery │
    └────────────────┘     └────────────────┘
```

---

## 🚀 Quick Start

### **Prerequisites**

- n8n installed ([Docker](https://docs.n8n.io/hosting/installation/docker/) or [npm](https://docs.n8n.io/hosting/installation/npm/))
- Telegram Bot Token ([Create via @BotFather](https://core.telegram.org/bots#botfather))
- (Optional) Grab API credentials for production

### **Installation**

1. **Clone Repository**
   ```bash
   git clone https://github.com/myownipgit/Omnidm-Telegram-GaaP-Compliant-Workflow.git
   cd Omnidm-Telegram-GaaP-Compliant-Workflow
   ```

2. **Import Workflows to n8n**
   ```bash
   # Option A: Via n8n UI
   # 1. Open n8n → Workflows → Import from File
   # 2. Import each workflow from /workflows/*.json

   # Option B: Via n8n CLI (if using self-hosted)
   n8n import:workflow --input=workflows/
   ```

3. **Configure Credentials**
   - Add Telegram Bot credentials in n8n:
     - Name: `your_bot_name`
     - Token: `YOUR_TELEGRAM_BOT_TOKEN` (obtain from @BotFather)

4. **Activate Workflow 01**
   - Enable "Channel Ingress" workflow
   - Set webhook to active

5. **Test**
   ```
   Open Telegram → Search @your_bot_name → /start
   ```

---

## 🧪 Testing

### **Test Scenarios (Policy Threshold Matrix)**

| Product | Amount | Band | Required Identity | Expected Behavior |
|---------|--------|------|-------------------|-------------------|
| Num Pang | $3.50 | A | anonymous | ✅ Allowed |
| Coffee Set | $5.00 | A | anonymous | ✅ Allowed |
| Lunch Set | $45.00 | B | basic | ⚠️ Step-up required |
| Party Catering | $250.00 | C | verified | ⚠️ CamDigiKey verification |
| Wedding Catering | $2,500 | D | high_assurance | ⚠️ Enhanced KYC |

### **User Journey**

```
User: /start
Bot: Welcome to Num Pang Express! 🥖

User: menu
Bot: [Shows 5 products with prices]

User: 3
Bot: Lunch Set for 4 - $45.00
     This requires basic identity verification.
     Generating payment QR...

Bot: ✅ Pay with KHQR:
     [QR Code]
     Deeplink: bakong://pay?qr=...
```

---

## 📐 CamDX Policy Threshold Matrix

Implemented in **Workflow 02 (Identity Evaluation)**:

| Amount Band | Anonymous | Basic | Verified | High Assurance |
|-------------|-----------|-------|----------|----------------|
| **A** ≤ $10 | ✅ Allowed | ✅ Allowed | ✅ Allowed | ✅ Allowed |
| **B** $10-100 | ⚠️ Limited | ✅ Allowed | ✅ Allowed | ✅ Allowed |
| **C** $100-1,000 | ❌ Blocked | ⚠️ Limited | ✅ Allowed | ✅ Allowed |
| **D** > $1,000 | ❌ Blocked | ❌ Blocked | ⚠️ Limited | ✅ Allowed |

**Step-Up Controls:**
- CamDigiKey challenge
- Velocity checks
- Manual review (high-value)

---

## 🏷️ Compliance Tags

All workflows are tagged for audit and dashboard visibility:

**Core Tags:**
- `kh-gaap` - Cambodia Government-as-a-Platform
- `tenant:omnidm.ai` - Multi-tenant identifier
- `compliance:level-5` - National infrastructure-aligned
- `env:sandbox` - Environment designation

**Data Classification:**
- `data-class:personal` - Customer profiles
- `data-class:regulated` - CamDigiKey, Bakong, CamDX data

**Rail Integration:**
- `rail:camdigikey` | `rail:camdx` | `rail:bakong` | `rail:khqr` | `rail:camdl`

---

## 📊 Compliance Dashboard Metrics

Workflows support these GaaP KPIs:

| Domain | Metric | Source Workflow |
|--------|--------|-----------------|
| Identity | % verified merchants | WF-02 |
| Payments | % KHQR/Bakong transactions | WF-05, WF-07 |
| Tax | % invoice coverage | WF-09 (CamDL) |
| Security | Incident MTTR | WF-09 |
| Audit | Log completeness | WF-09 |
| Policy | Threshold enforcement accuracy | WF-02 |

---

## 🔐 Security & Privacy

### **Data Protection (PDPL-Ready)**

- **Data Minimization:** Only essential fields stored
- **Encryption:** Credentials isolated in n8n vault
- **Audit Trail:** Immutable CamDL logging
- **No PII in Logs:** Auto-redaction in debug mode

### **Credential Management**

- OAuth2 for CamDigiKey
- mTLS for CamDX/CamInvoice
- API key rotation for Bakong

---

## 📦 Project Structure

```
Omnidm-Telegram-GaaP-Compliant-Workflow/
├── README.md                          # This file
├── docs/
│   ├── ARCHITECTURE.md               # GaaP architecture deep-dive
│   ├── COMPLIANCE.md                 # Compliance framework v3
│   ├── WORKFLOWS.md                  # Individual workflow documentation
│   ├── POLICY_MATRIX.md              # CamDX threshold matrix
│   └── TESTING.md                    # Test scenarios
├── workflows/
│   ├── 01-channel-ingress.json
│   ├── 02-identity-policy.json
│   ├── 03-intent-builder.json
│   ├── 04-camdx-publish.json
│   ├── 05-khqr-generator.json
│   ├── 06-deliver-telegram.json
│   ├── 07-settlement-verify.json
│   ├── 08-fulfillment-grab.json
│   └── 09-audit-camdl.json
├── config/
│   ├── product-catalog.json          # Num Pang menu
│   └── credentials.example.json      # Credential template
├── scripts/
│   └── export-workflows.sh           # Bulk export from n8n
└── LICENSE
```

---

## 🤝 Contributing

We welcome contributions! See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

**Priority Areas:**
- Real CamDX/Bakong API integration
- WhatsApp/Meta Messenger channels
- CamInvoice integration (May 2025 mandate)
- Credit Bureau Cambodia integration
- Additional payment threshold scenarios

---

## 📄 License

MIT License - See [LICENSE](./LICENSE)

---

## 🙏 Acknowledgments

- **Techo Startup Center (TSC)** - CamDX, CamDigiKey, CamDL platforms
- **National Bank of Cambodia (NBC)** - Bakong, KHQR standards
- **Ministry of Economy & Finance (MEF)** - Digital Economy & Society Policy Framework
- **n8n community** - Open-source workflow automation

---

## 📞 Contact

**Project:** https://github.com/myownipgit/Omnidm-Telegram-GaaP-Compliant-Workflow
**Company:** [CamFinTech.com](https://camfintech.com) - FinTech Consulting Cambodia
**Product:** [OmniDM.ai](https://omnidm.ai) - Conversational Commerce Platform

---

## 🔗 Related Resources

- [Cambodia GaaP FinTech Architecture](./docs/Cambodia-FinTech-Architecture-Multi-Layer-Ecosystem.pdf)
- [Compliance Framework v3](./docs/COMPLIANCE.md)
- [n8n Documentation](https://docs.n8n.io)
- [Telegram Bot API](https://core.telegram.org/bots/api)
- [Bakong Developer Portal](https://bakong.nbc.org.kh)

---

**🇰🇭 Built in Cambodia, for Cambodia's digital economy.**
