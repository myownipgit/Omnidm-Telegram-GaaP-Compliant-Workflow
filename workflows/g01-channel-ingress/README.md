# G01 - Channel Ingress

## Purpose

Handles incoming Telegram messages and webhooks, routing them to appropriate downstream workflows based on message type and content. This is the entry point for all customer interactions in the Telegraph E-Commerce platform.

## Workflows in This Group

| Workflow Name | Version | Status | File |
|---------------|---------|--------|------|
| [KH.GaaS] 01 - Channel Ingress | v1 | Active | G01.Telegram.Trigger.v1.json |

## Integration Points

### Upstream
- **Telegram Bot API** - Webhook receiver for all message types (text, callback queries, inline queries)

### Downstream
- **G02 - Identity & Policy** - Routes new users for identity verification
- **G03 - Intent Builder** - Routes order requests and product inquiries
- **G06 - Telegram Delivery** - Routes help requests and informational queries
- **G09 - Audit** - Logs all incoming messages

## GaaP Compliance Layers

| Layer | Purpose | Implementation |
|-------|---------|----------------|
| **L7 - Applications** | Telegram messaging interface | Webhook processing, message parsing |
| **L4 - Compliance & Audit** | Message logging | All messages logged to audit trail |

## Quick Start Guide

### Prerequisites
- Telegram bot created via @BotFather
- Bot token configured in n8n credentials
- Webhook URL registered with Telegram

### Configuration Steps

1. **Set up Telegram Bot Credentials in n8n**
   ```
   Credentials → Add Credential → Telegram API
   Name: telegram_bot
   Access Token: YOUR_TELEGRAM_BOT_TOKEN
   ```

2. **Register Webhook**
   ```bash
   curl -X POST "https://api.telegram.org/bot<YOUR_BOT_TOKEN>/setWebhook" \
     -H "Content-Type: application/json" \
     -d '{"url": "https://automation.omnidm.ai/webhook/telegram"}'
   ```

3. **Import Workflow**
   - Upload `G01.Telegram.Trigger.v1.json` to n8n
   - Verify webhook URL matches Telegram registration
   - Activate workflow

4. **Test**
   - Send `/start` to your Telegram bot
   - Verify message appears in n8n execution log
   - Check routing to appropriate downstream workflow

### Supported Message Types

| Message Type | Handler | Example |
|--------------|---------|---------|
| `/start` | Welcome message | User opens bot |
| `/menu` | Product catalog | Show available products |
| `/order` | Order creation | Start new order |
| `/help` | Help information | Bot capabilities |
| `/verify` | Identity verification | CamDigiKey flow |
| Product code (P001-P005) | Product selection | Add to cart |
| Callback queries | Button interactions | Confirm order, etc. |

### Message Routing Logic

```
Incoming Message
    ↓
Parse message type & content
    ↓
    ├─ New user → G02 (Identity check)
    ├─ Order request → G03 (Intent builder)
    ├─ Help/Info → G06 (Telegram delivery)
    └─ All → G09 (Audit log)
```

### Environment Variables

None required for this workflow (credentials stored in n8n).

### Monitoring

**Key Metrics:**
- Messages processed per minute
- Response time (webhook → processing)
- Error rate (malformed messages)
- Routing distribution (which downstream workflows)

**Alerts:**
- Webhook timeout > 10 seconds
- Error rate > 5%
- Unrouted messages detected

### Troubleshooting

**Issue: Bot not responding to messages**
- Check webhook is registered: `curl https://api.telegram.org/bot<TOKEN>/getWebhookInfo`
- Verify n8n workflow is active
- Check n8n logs for errors

**Issue: Messages not routing correctly**
- Verify message parsing logic in workflow
- Check downstream workflow triggers are active
- Review audit logs for routing decisions

**Issue: Webhook timeout**
- Reduce processing in this workflow (move heavy logic downstream)
- Check n8n instance performance
- Verify network connectivity to Telegram

### Related Documentation

- [Telegram Bot API Documentation](https://core.telegram.org/bots/api)
- [n8n Telegram Trigger Node](https://docs.n8n.io/integrations/builtin/trigger-nodes/n8n-nodes-base.telegramtrigger/)
- G02 - Identity & Policy (identity verification flow)
- G03 - Intent Builder (order creation flow)
