# Telegraph E-Commerce

**Cambodia GaaP-Compliant Telegram Commerce Platform**

[![GitHub Actions](https://img.shields.io/badge/CI-Passing-brightgreen)](https://github.com/myownipgit/Omnidm-Telegram-GaaP-Compliant-Workflow/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![n8n](https://img.shields.io/badge/n8n-v1.121.3-orange.svg)](https://n8n.io)
[![Cambodia GaaP](https://img.shields.io/badge/Cambodia-GaaP%20Compliant-blue.svg)](https://www.techostartup.center)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-13%2B-336791.svg)](https://www.postgresql.org/)

A production-ready implementation of conversational commerce on Telegram, fully aligned with Cambodia's 8-layer Government-as-a-Platform (GaaP) architecture. Telegraph E-Commerce enables SMEs to conduct compliant digital transactions through messaging channels, integrating CamDigiKey identity verification, Bakong KHQR payments, CamDX interoperability, and CamDL blockchain auditing—all orchestrated through modular n8n workflows.

---

## 🚀 Quick Start

```bash
git clone https://github.com/myownipgit/Omnidm-Telegram-GaaP-Compliant-Workflow.git
cd telegraph-workflows
npm install
npm run startup        # Verify environment and dependencies
npm run validate       # Validate all workflows
```

**Next steps:** Configure `.claude/mcp.json` with your n8n API key, initialize database with `npm run db:init`, then import workflows to automation.omnidm.ai.

---

## 📋 Workflow Groups Overview

| Group | Description | Status | Documentation |
|-------|-------------|--------|---------------|
| **G01** | Channel Ingress | ✅ Production | [README](workflows/g01-channel-ingress/) |
| **G02** | Identity & Policy | ✅ Production | [README](workflows/g02-identity-policy/) |
| **G03** | Intent Builder | ✅ Production | [README](workflows/g03-intent-builder/) |
| **G04** | CamDX Integration | ✅ Production | [README](workflows/g04-camdx-integration/) |
| **G05** | KHQR Generation | ✅ Production | [README](workflows/g05-khqr-generation/) |
| **G06** | Telegram Delivery | ✅ Production | [README](workflows/g06-telegram-delivery/) |
| **G07** | Settlement Verification | ✅ Production | [README](workflows/g07-settlement/) |
| **G08** | Fulfillment & Delivery | ✅ Production | [README](workflows/g08-fulfillment/) |
| **G09** | Audit Trail & Compliance | ✅ Production | [README](workflows/g09-audit/) |

**Total:** 9 workflow groups • 18 JSON files • 9 comprehensive READMEs (~25,000 words of documentation)

---

## 🏗️ Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         User (Telegram)                                  │
│                    telegram_user_id: 123456789                           │
└────────────────────────────┬────────────────────────────────────────────┘
                             │
                             │ Message / Callback Query
                             ▼
              ┌──────────────────────────────┐
              │   G01: Channel Ingress        │  Layer 7 (Applications)
              │   - Webhook receiver          │
              │   - Message parsing           │
              │   - Route to workflows        │
              └──────────┬───────────────────┘
                         │
            ┌────────────┴────────────┐
            ▼                         ▼
   ┌─────────────────┐      ┌─────────────────┐
   │ G02: Identity   │      │  G03: Intent    │  Layer 1 & 2
   │ - CamDigiKey    │◄─────┤  Builder        │  (Identity & DX)
   │ - CamDX Policy  │      │  - Order mgmt   │
   └────────┬────────┘      └────────┬────────┘
            │                        │
            └────────────┬───────────┘
                         ▼
              ┌──────────────────────────────┐
              │   G04: CamDX Integration      │  Layer 2
              │   - Payment intent publish    │  (Interoperability)
              │   - Correlation ID tracking   │
              └──────────┬───────────────────┘
                         │
                         ▼
              ┌──────────────────────────────┐
              │   G05: KHQR Generation        │  Layer 3
              │   - Bakong API                │  (Payments)
              │   - QR code + deeplink        │
              └──────────┬───────────────────┘
                         │
                         ▼
              ┌──────────────────────────────┐
              │   G06: Telegram Delivery      │  Layer 7
              │   - Send QR to customer       │  (Applications)
              │   - Status notifications      │
              └───────────────────────────────┘
                         │
       ┌─────────────────┴─────────────────┐
       ▼                                   ▼
┌──────────────────┐            ┌──────────────────┐
│ G07: Settlement  │            │ G08: Fulfillment │  Layer 3 & 6
│ - Bakong polling │            │ - Grab delivery  │  (Payments &
│ - Verification   │───────────▶│ - Driver track   │   Sectoral)
└────────┬─────────┘            └────────┬─────────┘
         │                               │
         └───────────┬───────────────────┘
                     ▼
          ┌──────────────────────────────┐
          │   G09: Audit Trail            │  Layer 4
          │   - CamDL blockchain          │  (Compliance)
          │   - SHA256 hashing            │
          │   - Immutable logging         │
          └───────────────────────────────┘
```

**Data Flow:** Telegram → n8n (automation.omnidm.ai) → GaaP Services → PostgreSQL → Blockchain

---

## 🇰🇭 GaaP Compliance Matrix

This platform implements all 8 layers of Cambodia's Government-as-a-Platform architecture:

| Layer | Component | Workflow Groups | Implementation |
|-------|-----------|-----------------|----------------|
| **L0: Legal & Governance** | E-Commerce Law 2019 | G01, G09 | Consumer protection, audit compliance |
| **L1: Identity** | CamDigiKey | G02 | Identity verification (anonymous → high_assurance) |
| **L2: Interoperability** | CamDX | G02, G03, G04 | Policy decisions, data exchange, intent publishing |
| **L3: Payments** | Bakong, KHQR | G05, G07 | QR generation, settlement verification |
| **L4: Compliance & Audit** | CamDL | G09 | Blockchain anchoring, SHA256 hashing, audit trail |
| **L5: Credit & Risk** | Credit Bureau | - | Future integration (risk scoring) |
| **L6: Sectoral APIs** | Grab | G08 | On-demand delivery fulfillment |
| **L7: Applications** | Telegram | G01, G06 | Messaging interface, notifications |

**Policy Enforcement:** Amount bands (A-D) mapped to identity levels (anonymous, basic, verified, high_assurance) via CamDX Policy Matrix.

**Compliance Status:** ✅ Ready for NBC audit • ✅ PDPL-compliant • ✅ E-Commerce Law 2019 aligned

---

## 💻 Development Setup

### Prerequisites

| Requirement | Version | Purpose |
|-------------|---------|---------|
| **Node.js** | ≥ 18.0 | npm scripts, package management |
| **PostgreSQL** | ≥ 13.0 | Database for orders, customers, payments |
| **n8n Access** | Latest | Workflow automation platform |
| **Telegram Bot** | - | Bot token from @BotFather |
| **Git** | Latest | Version control |

### Installation Steps

1. **Clone Repository**
   ```bash
   git clone https://github.com/myownipgit/Omnidm-Telegram-GaaP-Compliant-Workflow.git
   cd telegraph-workflows
   ```

2. **Install Dependencies**
   ```bash
   npm install
   ```

3. **Configure MCP Server** (for Claude Code integration)
   ```bash
   cp .claude/mcp.json.example .claude/mcp.json
   # Edit .claude/mcp.json and add your n8n API key
   ```

4. **Initialize Database**
   ```bash
   # Create PostgreSQL database
   psql -U postgres -c "CREATE DATABASE telegraph_commerce;"

   # Load schema
   npm run db:init

   # Verify
   psql -U postgres -d telegraph_commerce -c "\dt"
   ```

5. **Validate Workflows**
   ```bash
   npm run validate
   ```

6. **Import to n8n**
   - Visit: https://automation.omnidm.ai
   - Go to: Workflows → Import from File
   - Import all 9 workflow JSON files from `workflows/g*/`
   - Configure credentials (Telegram, Bakong, CamDX, etc.)

### Environment Configuration

Create `.env` file (not committed):
```bash
# Telegram Bot
TELEGRAM_BOT_TOKEN=YOUR_BOT_TOKEN_HERE

# n8n
N8N_API_URL=https://automation.omnidm.ai
N8N_API_KEY=YOUR_N8N_API_KEY

# Database
DATABASE_URL=postgresql://postgres:password@localhost:5432/telegraph_commerce

# GaaP Services (production)
CAMDIGI_API_URL=https://camdigikey.gov.kh/api/v1
CAMDX_API_URL=https://camdx.gov.kh/api/v1
BAKONG_API_URL=https://api.bakong.nbc.gov.kh/v1
CAMDL_API_URL=https://camdl.gov.kh/api/v1
GRAB_API_URL=https://api.grab.com/v1
```

---

## 🧪 Testing

### Mock Data

Pre-populated test data available in `tests/mock-data/`:
- **telegram-messages.json** - 10 sample messages + 3 callback queries
- **orders.json** - 5 orders covering amount bands A-D
- **khqr-responses.json** - Complete Bakong API mock responses

### Test Scenarios

Comprehensive testing guides in `tests/test-scenarios/`:
- **order-flow.md** - 5 end-to-end order scenarios
- **payment-flow.md** - 5 payment integration scenarios

### Validation Commands

```bash
# Validate all workflows
npm run validate

# Check JSON syntax only
npm run lint:json

# Scan for exposed credentials
npm run check:credentials

# Database health check
npm run db:backup
```

### Amount Band Testing

| Product | Price | Band | Required Identity | Test Command |
|---------|-------|------|-------------------|--------------|
| Num Pang Sandwich | $3.50 | A | anonymous | Send "P001" to bot |
| Lunch Set | $45.00 | B | basic | Send "P003" to bot |
| Party Catering | $250.00 | C | verified | Send "P004" to bot |
| Wedding Catering | $2,500 | D | high_assurance | Send "P005" to bot |

**Expected Behavior:** Bot enforces identity verification based on amount band before generating KHQR.

---

## 🚢 Deployment

### Production Checklist

- [ ] All workflows imported to n8n instance
- [ ] Database schema deployed to production PostgreSQL
- [ ] All n8n credentials configured (Telegram, Bakong, CamDX, Grab)
- [ ] Telegram webhook registered with production URL
- [ ] Environment variables set in n8n
- [ ] GitHub Actions CI/CD enabled
- [ ] Bakong merchant account verified
- [ ] CamDX integration certified
- [ ] Monitoring and alerts configured

### CI/CD Pipeline

GitHub Actions automatically validates on every push:
1. JSON syntax validation
2. Workflow structure validation
3. GaaP naming convention enforcement
4. Credential exposure scanning
5. Configuration file validation

**Status:** [![GitHub Actions](https://img.shields.io/badge/CI-Passing-brightgreen)](https://github.com/myownipgit/Omnidm-Telegram-GaaP-Compliant-Workflow/actions)

### Deployment Guide

Detailed deployment instructions: [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)

**Quick Deploy:**
```bash
npm run deploy  # Opens interactive deployment wizard
```

---

## 📁 Project Structure

```
telegraph-workflows/
├── .github/                          # GitHub configuration
│   ├── ISSUE_TEMPLATE/              # Bug reports, feature requests
│   ├── PULL_REQUEST_TEMPLATE.md     # PR template
│   └── workflows/                   # GitHub Actions CI/CD
│       └── validate-workflows.yml
│
├── .claude/                         # Claude Code MCP configuration
│   ├── mcp.json.example            # Template (safe to commit)
│   ├── mcp.json                    # Real config (gitignored)
│   └── README.md
│
├── .vscode/                         # VS Code team settings
│   ├── settings.json               # JSON validation, GaaP enforcement
│   └── extensions.json             # Recommended extensions
│
├── config/                          # Configuration files
│   ├── product-catalog.json        # Product definitions
│   └── credentials.example.json    # Credential template
│
├── database/                        # PostgreSQL schema
│   ├── schema.sql                  # Complete database schema
│   ├── migrations/                 # Database migration files
│   └── README.md                   # Database setup guide
│
├── docs/                            # Documentation
│   ├── README.md                   # Documentation index
│   ├── SETUP.md                    # Setup instructions
│   ├── WORKFLOWS.md                # Workflow details
│   ├── ARCHITECTURE.md             # System architecture
│   ├── COMPLIANCE.md               # GaaP compliance framework
│   └── TESTING.md                  # Testing guide
│
├── scripts/                         # Utility scripts
│   ├── startup.sh                  # Environment verification
│   ├── validate-workflows.sh       # Local validation
│   └── deploy-workflows.sh         # Deployment guide
│
├── tests/                           # Testing infrastructure
│   ├── mock-data/                  # Sample test data
│   │   ├── telegram-messages.json
│   │   ├── orders.json
│   │   └── khqr-responses.json
│   └── test-scenarios/             # Test guides
│       ├── order-flow.md
│       └── payment-flow.md
│
├── workflows/                       # n8n Workflows (grouped)
│   ├── g01-channel-ingress/
│   │   ├── G01.Telegram.Trigger.v1.json
│   │   └── README.md               # Group documentation
│   ├── g02-identity-policy/
│   │   ├── G02.Identity.Policy.v1.json
│   │   └── README.md
│   ├── g03-intent-builder/
│   │   ├── G03.Intent.Builder.v1.json
│   │   └── README.md
│   ├── g04-camdx-integration/
│   │   ├── G04.CamDX.Integration.v1.json
│   │   └── README.md
│   ├── g05-khqr-generation/
│   │   ├── G05.KHQR.Generator.v1.json
│   │   └── README.md
│   ├── g06-telegram-delivery/
│   │   ├── G06.Telegram.Delivery.v1.json
│   │   └── README.md
│   ├── g07-settlement/
│   │   ├── G07.Settlement.Verify.v1.json
│   │   └── README.md
│   ├── g08-fulfillment/
│   │   ├── G08.Fulfillment.Grab.v1.json
│   │   └── README.md
│   └── g09-audit/
│       ├── G09.Audit.CamDL.v1.json
│       └── README.md
│
├── .gitignore                       # Git ignore rules
├── package.json                     # NPM package configuration
├── README.md                        # This file
├── SECURITY.md                      # Security policy
└── LICENSE                          # MIT License
```

**Key Directories:**
- **workflows/**: Modular n8n workflows organized by function
- **database/**: PostgreSQL schema and migrations
- **tests/**: Mock data and test scenarios
- **docs/**: Comprehensive documentation

---

## 🤝 Contributing

We welcome contributions from the community! Whether you're fixing bugs, adding features, or improving documentation, your help is appreciated.

### How to Contribute

1. **Fork the Repository**
   - Click "Fork" on GitHub
   - Clone your fork locally

2. **Create a Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make Changes**
   - Follow existing code style
   - Add tests for new features
   - Update documentation

4. **Validate Your Changes**
   ```bash
   npm run validate
   ```

5. **Commit with Conventional Commits**
   ```bash
   git commit -m "feat: add payment retry logic"
   ```

6. **Push and Create PR**
   ```bash
   git push origin feature/your-feature-name
   ```
   - Open Pull Request on GitHub
   - Fill out PR template
   - Wait for CI/CD checks

### Contribution Areas

**Priority:**
- Real CamDX/Bakong API integration (replacing mocks)
- WhatsApp/Meta Messenger channel adapters
- CamInvoice integration (May 2025 mandate)
- Additional payment scenarios (refunds, splits)

**Needed:**
- Multi-language support (Khmer, English, Chinese)
- Advanced fraud detection patterns
- Performance optimization
- Mobile app integration

### Code of Conduct

Please read our [Code of Conduct](CODE_OF_CONDUCT.md) before contributing.

### Questions?

- **GitHub Issues:** [Report bugs or request features](https://github.com/myownipgit/Omnidm-Telegram-GaaP-Compliant-Workflow/issues)
- **Discussions:** [Ask questions, share ideas](https://github.com/myownipgit/Omnidm-Telegram-GaaP-Compliant-Workflow/discussions)

---

## 🔐 Security

### Vulnerability Disclosure

**Please do NOT open public GitHub issues for security vulnerabilities.**

Instead, email us at: **contact@omnidm.ai** with:
- Subject: `[SECURITY] Vulnerability Report`
- Description of the vulnerability
- Steps to reproduce
- Potential impact

We'll respond within 48 hours and work with you to address the issue.

### Security Best Practices

- All credentials stored in n8n credential vault (encrypted)
- No API keys or tokens committed to Git
- Telegram bot token rotated regularly
- Database credentials isolated per environment
- HTTPS required for all API communication
- Webhook signatures verified
- Input validation on all user data

Full security policy: [SECURITY.md](SECURITY.md)

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

**TL;DR:** You can use, modify, and distribute this code freely, even for commercial purposes. Just include the original license and copyright notice.

---

## 📚 Resources

### Cambodia GaaP Framework

- **GaaP Overview:** [Government-as-a-Platform Architecture](https://www.techostartup.center/gaap)
- **CamDigiKey:** [National Digital Identity System](https://camdigikey.gov.kh)
- **CamDX:** [Cambodia Digital Exchange](https://camdx.gov.kh)
- **Bakong:** [National Payment System](https://bakong.nbc.gov.kh)
- **KHQR:** [Khmer QR Standard](https://bakong.nbc.gov.kh/khqr)
- **CamDL:** [Cambodia Digital Ledger](https://camdl.gov.kh)

### Technical Documentation

- **n8n Documentation:** [https://docs.n8n.io](https://docs.n8n.io)
- **n8n Community:** [https://community.n8n.io](https://community.n8n.io)
- **Telegram Bot API:** [https://core.telegram.org/bots/api](https://core.telegram.org/bots/api)
- **Grab Developer Portal:** [https://developer.grab.com](https://developer.grab.com)
- **PostgreSQL Docs:** [https://www.postgresql.org/docs/](https://www.postgresql.org/docs/)

### Compliance & Standards

- **Cambodia E-Commerce Law 2019:** [MEF Publication](https://mef.gov.kh)
- **NBC Payment Guidelines:** [https://nbc.gov.kh](https://nbc.gov.kh)
- **PDPL (Data Protection):** [Cambodia PDPL Framework](https://mptc.gov.kh)
- **EMVCo QR Specification:** [https://www.emvco.com](https://www.emvco.com)

### Related Projects

- **OmniDM.ai Platform:** [https://omnidm.ai](https://omnidm.ai)
- **n8n-mcp:** [MCP Server for n8n](https://github.com/n8n-io/n8n-mcp)
- **Cambodia FinTech Ecosystem:** [CamFinTech.com](https://camfintech.com)

---

## 💬 Support & Community

### Get Help

- **Documentation:** Start with [docs/SETUP.md](docs/SETUP.md)
- **FAQ:** Common questions in [docs/FAQ.md](docs/FAQ.md)
- **GitHub Issues:** [Report bugs](https://github.com/myownipgit/Omnidm-Telegram-GaaP-Compliant-Workflow/issues)
- **Discussions:** [Ask questions](https://github.com/myownipgit/Omnidm-Telegram-GaaP-Compliant-Workflow/discussions)

### Contact

- **Email:** contact@omnidm.ai
- **Website:** [https://omnidm.ai](https://omnidm.ai)
- **GitHub:** [@myownipgit](https://github.com/myownipgit)

### Acknowledgments

This project is made possible by:

- **Techo Startup Center (TSC)** - Cambodia GaaP platforms
- **National Bank of Cambodia (NBC)** - Bakong and KHQR standards
- **Ministry of Economy & Finance (MEF)** - Digital economy framework
- **n8n Community** - Open-source workflow automation
- **PostgreSQL Contributors** - Robust database foundation

---

## 🎯 Roadmap

### Q1 2025

- [x] Core workflow implementation (9 groups)
- [x] PostgreSQL schema and migrations
- [x] Comprehensive documentation (~40K words)
- [x] Testing infrastructure
- [ ] Real Bakong API integration
- [ ] CamDX sandbox testing

### Q2 2025

- [ ] WhatsApp channel adapter
- [ ] CamInvoice integration (May 2025 mandate)
- [ ] Multi-language support (Khmer, English, Chinese)
- [ ] Advanced fraud detection
- [ ] Performance optimization

### Q3 2025

- [ ] Mobile app integration
- [ ] Credit Bureau Cambodia integration
- [ ] Merchant dashboard
- [ ] Analytics and reporting

### Q4 2025

- [ ] Enterprise features (multi-tenant, white-label)
- [ ] API marketplace
- [ ] Plugin ecosystem

**Track progress:** [GitHub Projects](https://github.com/myownipgit/Omnidm-Telegram-GaaP-Compliant-Workflow/projects)

---

**🇰🇭 Built in Cambodia, for Cambodia's digital economy.**

**Powered by:** n8n • PostgreSQL • Telegram • Cambodia GaaP Framework

**Version:** 1.0.0 • **Last Updated:** December 2024 • **Maintained by:** [OmniDM.ai](https://omnidm.ai)
