# Deployment Guide

Complete guide for deploying the OmniDM.ai Telegram GaaP-Compliant Workflow to GitHub and production.

---

## Table of Contents

- [GitHub Repository Setup](#github-repository-setup)
- [Initial Push to GitHub](#initial-push-to-github)
- [Updating Workflows](#updating-workflows)
- [Production Deployment](#production-deployment)

---

## GitHub Repository Setup

### Prerequisites

- Git installed
- GitHub account
- Repository created: `https://github.com/myownipgit/Omnidm-Telegram-GaaP-Compliant-Workflow`

### Initial Setup

```bash
# 1. Navigate to your project directory
cd /Users/myownip/workspace/n8n-mcp

# 2. Initialize Git repository (if not already initialized)
git init

# 3. Add remote repository
git remote add origin https://github.com/myownipgit/Omnidm-Telegram-GaaP-Compliant-Workflow.git

# 4. Verify remote
git remote -v
```

---

## Initial Push to GitHub

### Step 1: Review Project Structure

```bash
# Verify all files are in place
tree -L 2 -I 'node_modules'
```

Expected structure:
```
.
├── README.md
├── LICENSE
├── CONTRIBUTING.md
├── DEPLOYMENT.md
├── .gitignore
├── docs/
│   ├── ARCHITECTURE.md
│   ├── SETUP.md
│   └── WORKFLOWS.md
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
│   ├── product-catalog.json
│   └── credentials.example.json
└── scripts/
    └── export-workflows.sh
```

### Step 2: Stage All Files

```bash
# Add all files to Git
git add .

# Verify staged files
git status
```

### Step 3: Create Initial Commit

```bash
# Create initial commit
git commit -m "feat: Initial commit - Cambodia GaaP-compliant Telegram commerce workflows

- Add 9 modular n8n workflows implementing GaaP framework
- Include comprehensive documentation (README, ARCHITECTURE, SETUP, WORKFLOWS)
- Add product catalog configuration
- Add credential template
- Add export utility script
- Implement CamDX Policy Threshold Matrix
- Mock integrations for CamDX, Bakong, KHQR, CamDL, Grab APIs
- Full compliance with Cambodia 8-layer GaaP architecture"
```

### Step 4: Push to GitHub

```bash
# Push to main branch
git branch -M main
git push -u origin main
```

If you encounter authentication issues:

```bash
# Use Personal Access Token (PAT)
# 1. Generate PAT at: https://github.com/settings/tokens
# 2. Use it as password when prompted

# Or configure Git credential helper
git config --global credential.helper store
```

---

## Updating Workflows

### When You Make Changes to Workflows

```bash
# 1. Export updated workflows from n8n
./scripts/export-workflows.sh

# 2. Review changes
git diff workflows/

# 3. Stage and commit
git add workflows/
git commit -m "fix: Update KHQR generation logic in workflow 05"

# 4. Push to GitHub
git push origin main
```

### Creating Feature Branches

```bash
# 1. Create new branch for feature
git checkout -b feature/whatsapp-integration

# 2. Make your changes
# ... edit files ...

# 3. Commit changes
git add .
git commit -m "feat: Add WhatsApp channel integration"

# 4. Push branch
git push origin feature/whatsapp-integration

# 5. Create Pull Request on GitHub
# Visit: https://github.com/myownipgit/Omnidm-Telegram-GaaP-Compliant-Workflow/pulls
```

---

## Production Deployment

### Environment Setup

#### Option 1: Docker Compose (Recommended)

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15
    restart: always
    environment:
      POSTGRES_DB: n8n
      POSTGRES_USER: n8n
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    restart: always

  n8n:
    image: n8nio/n8n:latest
    restart: always
    ports:
      - "5678:5678"
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_DATABASE=n8n
      - DB_POSTGRESDB_USER=n8n
      - DB_POSTGRESDB_PASSWORD=${DB_PASSWORD}
      - N8N_ENCRYPTION_KEY=${ENCRYPTION_KEY}
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=${N8N_USER}
      - N8N_BASIC_AUTH_PASSWORD=${N8N_PASSWORD}
      - WEBHOOK_URL=${WEBHOOK_URL}
      - EXECUTIONS_MODE=queue
      - QUEUE_BULL_REDIS_HOST=redis
      - N8N_METRICS=true
    volumes:
      - n8n_data:/home/node/.n8n
      - ./workflows:/workflows:ro
    depends_on:
      - postgres
      - redis

volumes:
  postgres_data:
  n8n_data:
```

Create `.env` file:

```bash
# Database
DB_PASSWORD=your_secure_db_password

# n8n
N8N_USER=admin
N8N_PASSWORD=your_secure_password
ENCRYPTION_KEY=your_32_character_encryption_key_here

# Webhook
WEBHOOK_URL=https://your-domain.com
```

Deploy:

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f n8n

# Stop services
docker-compose down
```

#### Option 2: npm (Development)

```bash
# Install n8n globally
npm install -g n8n

# Set environment variables
export N8N_BASIC_AUTH_ACTIVE=true
export N8N_BASIC_AUTH_USER=admin
export N8N_BASIC_AUTH_PASSWORD=your_password

# Start n8n
n8n start
```

### Import Workflows to Production

```bash
# 1. Clone repository on production server
git clone https://github.com/myownipgit/Omnidm-Telegram-GaaP-Compliant-Workflow.git
cd Omnidm-Telegram-GaaP-Compliant-Workflow

# 2. Import workflows via n8n UI
# Visit: https://your-domain.com:5678
# Workflows → Import from File → Select each workflow

# 3. Configure credentials
# Settings → Credentials → Add credentials for:
#   - Telegram
#   - CamDX (when available)
#   - Bakong (when available)
#   - Grab API

# 4. Activate workflows
# Workflow 01: Channel Ingress → Toggle Active
# Workflow 07: Settlement Verification → Toggle Active
```

### Production Checklist

- [ ] Set strong passwords for n8n basic auth
- [ ] Configure HTTPS with SSL certificate
- [ ] Set up firewall rules (only expose port 443)
- [ ] Configure backup strategy for PostgreSQL
- [ ] Enable n8n metrics and monitoring
- [ ] Set up log aggregation
- [ ] Configure Telegram webhook with production URL
- [ ] Test all workflows in production
- [ ] Set up alerting for workflow failures
- [ ] Document production credentials securely

---

## Security Best Practices

### Never Commit Secrets

```bash
# Verify .gitignore is working
git status --ignored

# If credentials.json appears, add to .gitignore
echo "config/credentials.json" >> .gitignore
```

### Rotate Credentials Regularly

```bash
# Update credentials in n8n UI
# Update environment variables
# Restart services
docker-compose restart n8n
```

### Use Environment Variables

```bash
# Instead of hardcoding in workflows, use expressions:
# {{ $env.TELEGRAM_BOT_TOKEN }}
# {{ $env.GRAB_API_KEY }}
```

---

## Monitoring and Maintenance

### View n8n Logs

```bash
# Docker
docker-compose logs -f n8n

# npm
n8n log:view
```

### Backup Workflows

```bash
# Automated backup script
./scripts/export-workflows.sh

# Commit to Git
git add workflows/
git commit -m "chore: Backup workflows"
git push origin main
```

### Update n8n Version

```bash
# Docker
docker-compose pull
docker-compose up -d

# npm
npm update -g n8n
```

---

## Troubleshooting

### Workflow Import Fails

```bash
# Check workflow JSON validity
cat workflows/01-channel-ingress.json | jq .

# Verify n8n version compatibility
docker exec -it n8n n8n --version
```

### Telegram Webhook Not Working

```bash
# Check webhook URL
curl https://api.telegram.org/bot<TOKEN>/getWebhookInfo

# Reset webhook
curl -X POST https://api.telegram.org/bot<TOKEN>/deleteWebhook

# n8n will auto-register on workflow activation
```

### Database Connection Issues

```bash
# Check PostgreSQL status
docker-compose ps postgres

# View database logs
docker-compose logs postgres

# Connect to database
docker-compose exec postgres psql -U n8n -d n8n
```

---

## Support

- **Issues:** https://github.com/myownipgit/Omnidm-Telegram-GaaP-Compliant-Workflow/issues
- **Email:** contact@omnidm.ai
- **Documentation:** See `/docs` folder

---

**For detailed setup instructions, see [SETUP.md](docs/SETUP.md)**
**For architecture details, see [ARCHITECTURE.md](docs/ARCHITECTURE.md)**
