# Setup Guide

Complete installation and configuration guide for the OmniDM.ai Telegram GaaP-Compliant Workflow.

---

## Prerequisites

### Required

- **n8n** v1.0 or higher
  - [Docker installation](https://docs.n8n.io/hosting/installation/docker/)
  - [npm installation](https://docs.n8n.io/hosting/installation/npm/)
  - [Self-hosted server](https://docs.n8n.io/hosting/installation/server/)

- **Telegram Bot Token**
  - Create via [@BotFather](https://t.me/BotFather)
  - Keep token secure

### Optional (for production)

- **Grab API Credentials** (for real delivery integration)
- **PostgreSQL** (for persistent workflow state)
- **Redis** (for queue mode scaling)

---

## Installation

### Option 1: Docker (Recommended)

```bash
# Clone repository
git clone https://github.com/myownipgit/Omnidm-Telegram-GaaP-Compliant-Workflow.git
cd Omnidm-Telegram-GaaP-Compliant-Workflow

# Start n8n with Docker
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n

# Access n8n UI at http://localhost:5678
```

### Option 2: npm

```bash
# Install n8n globally
npm install -g n8n

# Start n8n
n8n start

# Access n8n UI at http://localhost:5678
```

---

## Workflow Import

### Via n8n UI

1. **Open n8n** → Navigate to http://localhost:5678
2. **Create Account** (first time only)
3. **Import Workflows:**
   - Click "Workflows" → "+ Add workflow" → "Import from file"
   - Import each workflow from `/workflows/` folder:
     - `01-channel-ingress.json`
     - `02-identity-policy.json`
     - `03-intent-builder.json`
     - `04-camdx-publish.json`
     - `05-khqr-generator.json`
     - `06-deliver-telegram.json`
     - `07-settlement-verify.json`
     - `08-fulfillment-grab.json`
     - `09-audit-camdl.json`

### Via n8n CLI (Advanced)

```bash
# Export workflows from this repo
n8n import:workflow --input=./workflows/

# Or import specific workflow
n8n import:workflow --input=./workflows/01-channel-ingress.json
```

---

## Configuration

### 1. Telegram Bot Credentials

#### Create Telegram Bot

1. Open Telegram → Search **@BotFather**
2. Send `/newbot`
3. Follow prompts:
   - **Bot Name:** Num Pang Express Bot
   - **Username:** `omnidm_bot` (or your choice)
4. **Save the token:** `7939716577:AAGEME3OeKPSIlruYq2wz5WgtrUCyifVEZo`

#### Add to n8n

1. **Open Workflow 01** (Channel Ingress)
2. **Click Telegram Trigger node**
3. **Add Credentials:**
   - Name: `omnidm_bot`
   - Access Token: `7939716577:AAGEME3OeKPSIlruYq2wz5WgtrUCyifVEZo`
4. **Save**

5. **Repeat for Workflow 06** (Deliver to Telegram)
   - Click Telegram Send Message nodes
   - Select existing `omnidm_bot` credential

### 2. Product Catalog (Optional Customization)

Edit **Workflow 02** → `ID: Lookup Product Price` node:

```javascript
const productCatalog = {
  'P001': { name: 'Your Product 1', price: 3.50, band: 'A' },
  'P002': { name: 'Your Product 2', price: 5.00, band: 'A' },
  'P003': { name: 'Your Product 3', price: 45.00, band: 'B' },
  'P004': { name: 'Your Product 4', price: 250.00, band: 'C' },
  'P005': { name: 'Your Product 5', price: 2500.00, band: 'D' }
};
```

Update menu in **Workflow 01** → `ING: Send Menu` node:

```
Menu:
1. Your Product 1 - $3.50
2. Your Product 2 - $5.00
3. Your Product 3 - $45.00
4. Your Product 4 - $250.00
5. Your Product 5 - $2,500
```

### 3. Grab API (Production Only)

Edit **Workflow 08** → `FUL: Mock Grab API` node:

```javascript
// Replace httpbin.org with real Grab API
url: "https://partner-api.grab.com/deliveries"

headers: {
  "Authorization": "Bearer YOUR_GRAB_API_KEY",
  "Content-Type": "application/json"
}
```

Get Grab API credentials from: https://developer.grab.com

---

## Activation

### Activate Workflows

1. **Workflow 01 (Channel Ingress):**
   - Open workflow
   - Click "Active" toggle (top right)
   - Status changes to green "Active"

2. **Workflow 07 (Settlement Verification):**
   - Open workflow
   - Click "Active" toggle
   - This is a daemon that runs every 30 seconds

3. **Keep other workflows inactive** (they're called programmatically)

---

## Testing

### Test Telegram Bot

1. **Open Telegram**
2. **Search for your bot:** `@omnidm_bot`
3. **Send `/start`**

**Expected Response:**
```
🥖 Welcome to Num Pang Express!

Cambodia's favorite street food, now on Telegram.

📱 Quick Commands:
• Type 'menu' to browse
• Type number (1-5) to select
• Type 'status' to track orders

✨ Powered by Cambodia GaaP FinTech Rails
```

### Test Product Selection

1. **Type:** `menu`

**Expected Response:**
```
🍽️ Num Pang Express Menu

1️⃣ Num Pang Sandwich - $3.50
   Classic Cambodian baguette

2️⃣ Coffee + Pastry Set - $5.00
   Perfect breakfast combo

3️⃣ Lunch Set (4 people) - $45.00
   Family meal deal

4️⃣ Party Catering - $250.00
   20-person event package

5️⃣ Wedding Catering - $2,500
   Full wedding service (100+ guests)

💡 Reply with a number (1-5) to order
```

2. **Type:** `3`

**Expected Response:**
```
✅ Order Confirmed!

🍽️ Lunch Set (4 people)
💰 Amount: $45.00 USD
📋 Order ID: pi_1737555123_abc123

Pay with KHQR:
`khqr:numpang-express-001:45.00:USD:pi_123`

🔗 Open Bakong

⏰ Expires: 22/01/2025 10:10 AM

🇰🇭 Powered by Cambodia GaaP
```

---

## Troubleshooting

### Bot doesn't respond

**Check:**
- ✅ Workflow 01 is **Active**
- ✅ Telegram credentials are correct
- ✅ Webhook URL is set (n8n handles this automatically)

**Debug:**
```bash
# View n8n logs
docker logs -f n8n  # (if using Docker)
# Or check n8n UI → Settings → Log Streaming
```

### Workflow execution fails

**Check:**
- Open failed workflow in n8n UI
- Click "Executions" tab
- View error details
- Common issues:
  - Missing credentials
  - Invalid JSON in Code nodes
  - Network timeout (httpbin.org unreachable)

### KHQR not generating

**Check:**
- Workflow 05 is imported correctly
- `QR: Build KHQR Payload` node has valid JavaScript
- httpbin.org is reachable (mock endpoint)

---

## Production Deployment

### Environment Variables

Create `.env` file:

```bash
# n8n Configuration
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your_secure_password

# Database (PostgreSQL)
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=localhost
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n
DB_POSTGRESDB_PASSWORD=your_db_password

# Encryption Key (keep secret!)
N8N_ENCRYPTION_KEY=your_32_character_encryption_key

# Webhook URL
WEBHOOK_URL=https://your-domain.com/

# Queue Mode (for scaling)
EXECUTIONS_MODE=queue
QUEUE_BULL_REDIS_HOST=localhost
QUEUE_BULL_REDIS_PORT=6379
```

### Docker Compose

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: n8n
      POSTGRES_USER: n8n
      POSTGRES_PASSWORD: your_db_password
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine

  n8n:
    image: n8nio/n8n
    ports:
      - 5678:5678
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_DATABASE=n8n
      - DB_POSTGRESDB_USER=n8n
      - DB_POSTGRESDB_PASSWORD=your_db_password
      - N8N_ENCRYPTION_KEY=your_encryption_key
      - EXECUTIONS_MODE=queue
      - QUEUE_BULL_REDIS_HOST=redis
    volumes:
      - n8n_data:/home/node/.n8n
    depends_on:
      - postgres
      - redis

volumes:
  postgres_data:
  n8n_data:
```

**Start:**
```bash
docker-compose up -d
```

---

## Security Best Practices

### Credentials

- **Never commit** `.env` files or credentials to Git
- Use n8n's credential encryption
- Rotate API keys regularly

### Access Control

- Enable n8n basic auth in production
- Use HTTPS for webhook endpoints
- Restrict n8n UI access by IP

### Data Protection

- Enable PostgreSQL encryption at rest
- Use Redis password protection
- Implement backup strategy

---

## Next Steps

1. ✅ Test all 5 product scenarios (A, B, C, D bands)
2. ✅ Monitor workflow executions in n8n UI
3. ✅ Review audit logs (Workflow 09)
4. 🔜 Integrate real CamDX/Bakong APIs
5. 🔜 Add WhatsApp channel
6. 🔜 Connect to production Grab API

---

**For architecture details, see [ARCHITECTURE.md](./ARCHITECTURE.md).**
**For workflow documentation, see [WORKFLOWS.md](./WORKFLOWS.md).**
