# G06 - Telegram Delivery

## Purpose

Delivers messages, notifications, and interactive content to customers via Telegram. Handles all outbound communication including order confirmations, payment instructions, delivery updates, and customer support responses.

## Workflows in This Group

| Workflow Name | Version | Status | File |
|---------------|---------|--------|------|
| [KH.GaaS] 06 - Telegram Delivery | v1 | Active | G06.Telegram.Delivery.v1.json |

## Integration Points

### Upstream
- **G01 - Channel Ingress** - Receives help requests and informational queries
- **G03 - Intent Builder** - Receives order summaries for confirmation
- **G05 - KHQR Generation** - Receives payment QR codes and deeplinks
- **G07 - Settlement** - Receives payment confirmations
- **G08 - Fulfillment** - Receives delivery status updates

### Downstream
- **Telegram Bot API** - Sends messages to customers
- **G09 - Audit** - Logs all outbound messages

## GaaP Compliance Layers

| Layer | Purpose | Implementation |
|-------|---------|----------------|
| **L7 - Applications** | Customer communication | Message formatting, delivery tracking |
| **L4 - Compliance** | Communication audit trail | All messages logged |

## Quick Start Guide

### Prerequisites
- Telegram bot token configured
- Customers have active Telegram chat sessions

### Configuration Steps

1. **Verify Telegram Bot Credentials**
   ```
   Credentials → Telegram API → telegram_bot
   - Ensure Access Token is valid
   ```

2. **Import Workflow**
   - Upload `G06.Telegram.Delivery.v1.json`
   - Link Telegram credentials
   - Activate workflow

3. **Test Message Delivery**
   ```javascript
   // Trigger test message
   {
     "chat_id": 123456789,
     "message": "Test message from Telegraph",
     "message_type": "text"
   }
   ```

### Message Types

| Type | Purpose | Example |
|------|---------|---------|
| **text** | Simple text messages | "Welcome to Num Pang Express!" |
| **photo** | Images (QR codes) | Payment QR code |
| **inline_keyboard** | Interactive buttons | [Confirm Order] [Cancel] |
| **location** | Delivery tracking | Driver location map |
| **document** | Receipts, invoices | Order receipt PDF |

### Message Templates

**Welcome Message:**
```javascript
{
  "chat_id": "{telegram_user_id}",
  "text": "Welcome to Num Pang Express! 🥖\n\nWhat would you like to do?\n- /menu - View our menu\n- /order - Start an order\n- /help - Get help"
}
```

**Order Confirmation:**
```javascript
{
  "chat_id": "{telegram_user_id}",
  "text": "✅ Order confirmed!\nOrder ID: {order_id}\n\n{order_items}\n\nTotal: ${total_amount}\n\nPlease scan QR code to pay:",
  "reply_markup": {
    "inline_keyboard": [[
      {"text": "View QR Code", "callback_data": "view_qr_{order_id}"}
    ]]
  }
}
```

**Payment QR Delivery:**
```javascript
{
  "chat_id": "{telegram_user_id}",
  "photo": "{khqr_base64_image}",
  "caption": "💰 Scan to pay ${amount}\n\n⏰ Payment expires in {timeout} minutes\n\nOr use this link: {khqr_deeplink}",
  "reply_markup": {
    "inline_keyboard": [[
      {"text": "Open Bakong App", "url": "{khqr_deeplink}"}
    ]]
  }
}
```

**Payment Confirmed:**
```javascript
{
  "chat_id": "{telegram_user_id}",
  "text": "💰 Payment received! (${amount})\n\nYour order is being prepared.\nOrder ID: {order_id}\n\nEstimated time: {prep_time} minutes"
}
```

**Delivery Assigned:**
```javascript
{
  "chat_id": "{telegram_user_id}",
  "text": "🚗 Your order is ready for delivery!\n\nDriver: {driver_name}\nETA: {eta} minutes\n\nTrack delivery: {tracking_link}",
  "reply_markup": {
    "inline_keyboard": [[
      {"text": "Track Delivery", "url": "{tracking_link}"},
      {"text": "Call Driver", "url": "tel:{driver_phone}"}
    ]]
  }
}
```

**Order Complete:**
```javascript
{
  "chat_id": "{telegram_user_id}",
  "text": "✅ Order delivered!\n\nThank you for your order.\n\nRate your experience:",
  "reply_markup": {
    "inline_keyboard": [
      [
        {"text": "⭐", "callback_data": "rate_1"},
        {"text": "⭐⭐", "callback_data": "rate_2"},
        {"text": "⭐⭐⭐", "callback_data": "rate_3"},
        {"text": "⭐⭐⭐⭐", "callback_data": "rate_4"},
        {"text": "⭐⭐⭐⭐⭐", "callback_data": "rate_5"}
      ]
    ]
  }
}
```

### Inline Keyboards (Interactive Buttons)

**Product Selection:**
```javascript
{
  "inline_keyboard": [
    [{"text": "🥖 Num Pang Sandwich ($3.50)", "callback_data": "product_P001"}],
    [{"text": "☕ Coffee + Pastry ($5.00)", "callback_data": "product_P002"}],
    [{"text": "🍱 Lunch Set ($45.00)", "callback_data": "product_P003"}]
  ]
}
```

**Order Confirmation:**
```javascript
{
  "inline_keyboard": [
    [
      {"text": "✅ Confirm Order", "callback_data": "confirm_order"},
      {"text": "❌ Cancel", "callback_data": "cancel_order"}
    ]
  ]
}
```

### Message Formatting

Telegram supports **Markdown** and **HTML** formatting:

**Markdown:**
```
*bold text*
_italic text_
`inline code`
[link](http://example.com)
```

**HTML:**
```html
<b>bold</b>
<i>italic</i>
<code>code</code>
<a href="http://example.com">link</a>
```

**Emojis:**
- 🥖 Sandwich
- ☕ Coffee
- 💰 Payment
- ✅ Success
- ❌ Error
- ⏰ Time
- 🚗 Delivery
- ⭐ Rating

### Delivery Status Tracking

Track message delivery success:

```sql
CREATE TABLE message_log (
  message_id SERIAL PRIMARY KEY,
  telegram_message_id BIGINT,
  chat_id BIGINT,
  message_type VARCHAR(50),
  sent_at TIMESTAMP,
  delivered BOOLEAN,
  error_message TEXT
);
```

### Rate Limiting

Telegram API limits:
- **30 messages/second** per bot
- **20 messages/minute** per chat
- **Broadcast:** max 30 messages/second

If exceeded:
- `429 Too Many Requests` error
- Retry after X seconds (specified in response)

**Mitigation:**
```javascript
// Queue messages
const queue = [];
const RATE_LIMIT = 30; // per second

setInterval(() => {
  const batch = queue.splice(0, RATE_LIMIT);
  batch.forEach(msg => sendMessage(msg));
}, 1000);
```

### Error Handling

| Error Code | Meaning | Action |
|------------|---------|--------|
| **400** | Bad Request | Check message format |
| **401** | Unauthorized | Verify bot token |
| **403** | Forbidden | User blocked bot |
| **404** | Not Found | Chat doesn't exist |
| **429** | Too Many Requests | Implement rate limiting |
| **500** | Server Error | Retry with backoff |

**User Blocked Bot:**
```javascript
// Error response
{
  "ok": false,
  "error_code": 403,
  "description": "Forbidden: bot was blocked by the user"
}

// Action: Mark user as inactive
UPDATE customers
SET bot_blocked = TRUE
WHERE telegram_user_id = 123456789;
```

### Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `TELEGRAM_BOT_TOKEN` | Bot API token | 7939716577:AAG... |
| `TELEGRAM_API_URL` | Telegram API endpoint | https://api.telegram.org |

### Monitoring

**Key Metrics:**
- Messages sent per minute
- Delivery success rate
- Average delivery time
- User blocking rate
- Button click-through rate

**Alerts:**
- Delivery failure rate > 5%
- Rate limit errors > 10/hour
- Bot blocked by > 10 users/day

### Troubleshooting

**Issue: Messages not delivered**
- Check bot token validity
- Verify chat_id exists
- Ensure user hasn't blocked bot
- Review Telegram API status

**Issue: QR code not displaying**
- Check Base64 encoding
- Verify image size < 10MB
- Try sending as document instead

**Issue: Inline buttons not working**
- Verify callback_data format
- Check G01 handles callback queries
- Review button JSON structure

**Issue: Rate limit errors**
- Implement message queuing
- Add exponential backoff
- Reduce message frequency

### Testing

**Test Scenario 1: Send welcome message**
```bash
POST https://api.telegram.org/bot<TOKEN>/sendMessage
{
  "chat_id": 123456789,
  "text": "Welcome to Num Pang Express!"
}

Expected:
- Response: {"ok": true, "result": {...}}
- Message appears in Telegram
```

**Test Scenario 2: Send QR code**
```bash
POST https://api.telegram.org/bot<TOKEN>/sendPhoto
{
  "chat_id": 123456789,
  "photo": "data:image/png;base64,...",
  "caption": "Scan to pay $7.00"
}

Expected:
- QR code displays in Telegram
- Caption appears below image
```

**Test Scenario 3: Interactive buttons**
```bash
POST https://api.telegram.org/bot<TOKEN>/sendMessage
{
  "chat_id": 123456789,
  "text": "Confirm your order?",
  "reply_markup": {
    "inline_keyboard": [[
      {"text": "Yes", "callback_data": "confirm"},
      {"text": "No", "callback_data": "cancel"}
    ]]
  }
}

Expected:
- Buttons display below message
- Clicking triggers callback query in G01
```

### Related Documentation

- [Telegram Bot API](https://core.telegram.org/bots/api)
- [Telegram Message Formatting](https://core.telegram.org/bots/api#formatting-options)
- [Inline Keyboards](https://core.telegram.org/bots/api#inlinekeyboardmarkup)
- G01 - Channel Ingress (receives callback queries)
- G05 - KHQR Generation (provides QR codes)
