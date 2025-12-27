# G08 - Fulfillment & Delivery

## Purpose

Manages order fulfillment and delivery logistics via Grab API. Assigns delivery drivers, tracks delivery progress, and provides real-time updates to customers about their order status.

## Workflows in This Group

| Workflow Name | Version | Status | File |
|---------------|---------|--------|------|
| [KH.GaaS] 08 - Fulfillment Grab | v1 | Active | G08.Fulfillment.Grab.v1.json |

## Integration Points

### Upstream
- **G07 - Settlement** - Triggered when payment is verified
- **Grab API Webhooks** - Receives delivery status updates

### Downstream
- **Grab API** - Creates delivery requests, tracks status
- **G06 - Telegram Delivery** - Sends delivery updates to customer
- **Database (fulfillments)** - Persists delivery data
- **G09 - Audit** - Logs fulfillment events

## GaaP Compliance Layers

| Layer | Purpose | Implementation |
|-------|---------|----------------|
| **L6 - Sectoral APIs** | Grab delivery integration | On-demand logistics |
| **L7 - Applications** | Order fulfillment | End-to-end order completion |
| **L4 - Compliance** | Delivery audit trail | Driver assignment, delivery proof |

## Quick Start Guide

### Prerequisites
- Grab for Business account
- Grab API credentials
- Merchant location configured
- Database schema initialized (fulfillments table)

### Configuration Steps

1. **Register Grab for Business**
   - Visit: https://business.grab.com
   - Register merchant account
   - Complete KYC verification
   - Receive API credentials

2. **Set up Grab API Credentials in n8n**
   ```
   Credentials → Add Credential → OAuth2 API
   Name: grab_api
   Grant Type: Client Credentials
   Client ID: YOUR_GRAB_CLIENT_ID
   Client Secret: YOUR_GRAB_CLIENT_SECRET
   Access Token URL: https://api.grab.com/oauth2/v1/token
   ```

3. **Configure Merchant Location**
   ```json
   {
     "merchant_id": "numpang-express-001",
     "pickup_address": "Street 240, Sangkat Chaktomuk, Phnom Penh",
     "pickup_lat": 11.5564,
     "pickup_lng": 104.9282,
     "pickup_phone": "+855 12 345 678",
     "pickup_instructions": "Restaurant on ground floor"
   }
   ```

4. **Import and Activate Workflow**
   - Upload `G08.Fulfillment.Grab.v1.json`
   - Link Grab credentials
   - Configure database connection
   - Set up webhook endpoint
   - Activate workflow

### Grab Delivery Flow

```
Payment verified (G07)
    ↓
Create fulfillment record
    ↓
Call Grab API to create delivery
    ↓
Grab assigns driver
    ↓
Driver picks up order
    ↓
Driver delivers to customer
    ↓
Customer confirms receipt
    ↓
Mark order as completed
```

### Grab API - Create Delivery

**Endpoint:** `POST https://api.grab.com/v1/deliveries`

**Request:**
```json
{
  "service_type": "INSTANT",
  "delivery_info": {
    "pickup": {
      "address": "Street 240, Sangkat Chaktomuk, Phnom Penh",
      "lat": 11.5564,
      "lng": 104.9282,
      "contact_name": "Num Pang Express",
      "contact_phone": "+855 12 345 678",
      "instructions": "Restaurant on ground floor"
    },
    "dropoff": {
      "address": "Street 51, Sangkat Boeung Keng Kang, Phnom Penh",
      "lat": 11.5500,
      "lng": 104.9200,
      "contact_name": "Sokha Chen",
      "contact_phone": "+855 98 765 432",
      "instructions": "Apartment 3B, second floor"
    }
  },
  "package_info": {
    "name": "Food order",
    "description": "2x Num Pang Sandwich",
    "quantity": 1,
    "weight_kg": 0.5,
    "dimensions": {
      "length_cm": 20,
      "width_cm": 15,
      "height_cm": 10
    }
  },
  "order_info": {
    "order_id": "ORD-20250101-0001",
    "order_value": 7.00,
    "payment_method": "PREPAID",
    "notes": "Handle with care, food items"
  }
}
```

**Response:**
```json
{
  "delivery_id": "GRAB-DLV-20250101-XYZ123",
  "status": "ASSIGNING",
  "estimated_pickup_time": "2025-01-01T10:10:00Z",
  "estimated_delivery_time": "2025-01-01T10:25:00Z",
  "tracking_url": "https://grab.com/track/GRAB-DLV-20250101-XYZ123",
  "fee": {
    "amount": 2.50,
    "currency": "USD"
  }
}
```

### Grab Service Types

| Service | Description | ETA | Use Case |
|---------|-------------|-----|----------|
| **INSTANT** | Immediate delivery | 15-30 min | Hot food, urgent orders |
| **SAME_DAY** | Delivered today | 2-4 hours | Catering prep time |
| **SCHEDULED** | Specific time slot | Custom | Wedding catering |

### Delivery Status States

| Status | Description | Actions |
|--------|-------------|---------|
| `ASSIGNING` | Looking for driver | Wait, notify customer "Finding driver" |
| `ASSIGNED` | Driver assigned | Send driver info to customer |
| `PICKING_UP` | Driver en route to restaurant | Notify "Driver on the way" |
| `PICKED_UP` | Driver has order | Notify "Order picked up, in transit" |
| `DELIVERING` | En route to customer | Send tracking link, ETA updates |
| `DELIVERED` | Order delivered | Request customer confirmation |
| `CANCELLED` | Delivery cancelled | Notify customer, refund |
| `FAILED` | Delivery failed | Retry or refund |

### Database Schema

**fulfillments Table:**
```sql
CREATE TABLE fulfillments (
  fulfillment_id SERIAL PRIMARY KEY,
  order_id VARCHAR(100) REFERENCES orders,
  delivery_method VARCHAR(50) DEFAULT 'grab_express',
  grab_delivery_id VARCHAR(255),           -- GRAB-DLV-20250101-XYZ123
  driver_assigned BOOLEAN DEFAULT FALSE,
  driver_name VARCHAR(255),
  driver_phone VARCHAR(20),
  driver_vehicle VARCHAR(100),
  pickup_address TEXT,
  delivery_address TEXT,
  estimated_pickup TIMESTAMP,
  estimated_delivery TIMESTAMP,
  actual_pickup TIMESTAMP,
  actual_delivery TIMESTAMP,
  fulfillment_status VARCHAR(50) DEFAULT 'preparing',
  tracking_url TEXT,
  delivery_fee DECIMAL(10, 2),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Webhook Configuration

Grab sends status updates to your webhook:

**Register Webhook:**
```bash
POST https://api.grab.com/v1/webhooks
{
  "url": "https://automation.omnidm.ai/webhook/grab",
  "events": [
    "delivery.assigned",
    "delivery.picked_up",
    "delivery.delivered",
    "delivery.cancelled"
  ],
  "secret": "YOUR_WEBHOOK_SECRET"
}
```

**Webhook Payload Example (Driver Assigned):**
```json
{
  "event": "delivery.assigned",
  "timestamp": "2025-01-01T10:08:00Z",
  "data": {
    "delivery_id": "GRAB-DLV-20250101-XYZ123",
    "order_id": "ORD-20250101-0001",
    "driver": {
      "name": "Sopheak",
      "phone": "+855 11 222 333",
      "vehicle": "Honda Dream (PP 1A-2345)",
      "photo_url": "https://grab.com/drivers/photos/12345.jpg",
      "rating": 4.8
    },
    "estimated_pickup_time": "2025-01-01T10:10:00Z",
    "estimated_delivery_time": "2025-01-01T10:25:00Z"
  },
  "signature": "sha256=abc123..."
}
```

**Webhook Handling:**
```javascript
// 1. Verify signature
const crypto = require('crypto');
const signature = req.headers['x-grab-signature'];
const payload = JSON.stringify(req.body);
const expected = crypto
  .createHmac('sha256', WEBHOOK_SECRET)
  .update(payload)
  .digest('hex');

if (`sha256=${expected}` !== signature) {
  throw new Error('Invalid webhook signature');
}

// 2. Update database
UPDATE fulfillments
SET driver_assigned = TRUE,
    driver_name = 'Sopheak',
    driver_phone = '+855 11 222 333',
    fulfillment_status = 'assigned'
WHERE grab_delivery_id = 'GRAB-DLV-20250101-XYZ123';

// 3. Notify customer via G06
{
  "chat_id": 123456789,
  "text": "🚗 Driver assigned!\n\nDriver: Sopheak\nVehicle: Honda Dream (PP 1A-2345)\nETA: 15 minutes"
}
```

### Delivery Tracking

**Real-time Location Updates:**

```bash
GET https://api.grab.com/v1/deliveries/{delivery_id}/location
```

**Response:**
```json
{
  "delivery_id": "GRAB-DLV-20250101-XYZ123",
  "driver_location": {
    "lat": 11.5550,
    "lng": 104.9250,
    "heading": 45,
    "speed_kmh": 30,
    "updated_at": "2025-01-01T10:12:34Z"
  },
  "eta_minutes": 13,
  "distance_remaining_km": 3.2
}
```

**Send to Customer:**
```javascript
// Via Telegram location sharing
{
  "chat_id": 123456789,
  "latitude": 11.5550,
  "longitude": 104.9250,
  "live_period": 900  // 15 minutes
}
```

### Delivery Proof

Upon delivery, Grab provides proof:

```json
{
  "event": "delivery.delivered",
  "data": {
    "delivery_id": "GRAB-DLV-20250101-XYZ123",
    "delivered_at": "2025-01-01T10:23:15Z",
    "proof": {
      "type": "SIGNATURE",
      "signature_image": "https://grab.com/proof/sig-12345.jpg",
      "photo": "https://grab.com/proof/photo-12345.jpg",
      "notes": "Delivered to customer at door"
    }
  }
}
```

**Store Proof:**
```sql
UPDATE fulfillments
SET actual_delivery = '2025-01-01T10:23:15Z',
    fulfillment_status = 'delivered',
    delivery_proof_url = 'https://grab.com/proof/sig-12345.jpg'
WHERE grab_delivery_id = 'GRAB-DLV-20250101-XYZ123';

UPDATE orders
SET order_status = 'completed',
    completed_at = '2025-01-01T10:23:15Z'
WHERE order_id = 'ORD-20250101-0001';
```

### Delivery Fee Calculation

Grab calculates fees based on:
- **Distance** - Pickup to dropoff (km)
- **Service type** - Instant vs same-day
- **Time of day** - Peak hours surcharge
- **Weather** - Rain surcharge

**Typical Fees (Phnom Penh):**
- Base: $1.00
- Per km: $0.50
- Peak hour: +$0.50
- Rain: +$0.50

**Example:** 3km delivery during peak hour = $1.00 + (3 × $0.50) + $0.50 = $3.00

### Failed Delivery Handling

**Scenarios:**
1. **Customer not reachable** - Driver waited 10 minutes
2. **Wrong address** - Location doesn't exist
3. **Customer refused** - Cancelled at door

**Actions:**
```sql
-- Mark as failed
UPDATE fulfillments
SET fulfillment_status = 'failed',
    failure_reason = 'customer_not_reachable'
WHERE grab_delivery_id = 'GRAB-DLV-20250101-XYZ123';

-- Notify customer to provide correct address or reschedule
-- May charge cancellation fee
```

### Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `GRAB_API_URL` | Grab API endpoint | https://api.grab.com/v1 |
| `GRAB_CLIENT_ID` | OAuth client ID | Your client ID |
| `GRAB_CLIENT_SECRET` | OAuth secret | Your secret |
| `GRAB_WEBHOOK_SECRET` | Webhook signature key | Your HMAC secret |
| `MERCHANT_LAT` | Restaurant latitude | 11.5564 |
| `MERCHANT_LNG` | Restaurant longitude | 104.9282 |

### Monitoring

**Key Metrics:**
- Average delivery time
- Driver assignment time
- On-time delivery rate
- Failed delivery rate
- Average delivery fee

**Alerts:**
- Driver assignment > 5 minutes
- Delivery failure rate > 5%
- Grab API errors > 1%
- Webhook signature failures

### Troubleshooting

**Issue: No driver available**
- Peak hours - wait or retry
- Remote location - limited coverage
- Try different service type

**Issue: Delivery stuck in "ASSIGNING"**
- Check Grab API status
- Verify pickup location valid
- May need manual driver assignment

**Issue: Wrong delivery address**
- Verify customer provided correct address
- Update via Grab API if possible
- Contact driver directly

**Issue: Webhook not received**
- Check webhook URL registered
- Verify HTTPS certificate
- Review signature verification logic

### Testing

**Test Scenario 1: Create delivery**
```bash
POST https://api.grab.com/v1/deliveries
{
  "service_type": "INSTANT",
  "order_id": "ORD-20250101-0001",
  "pickup": {...},
  "dropoff": {...}
}

Expected Response:
- delivery_id returned
- status: "ASSIGNING"
- ETA provided
```

**Test Scenario 2: Track delivery**
```bash
GET https://api.grab.com/v1/deliveries/{delivery_id}/location

Expected Response:
- driver_location with lat/lng
- eta_minutes
- distance_remaining_km
```

### Related Documentation

- [Grab for Business](https://business.grab.com)
- [Grab API Documentation](https://developer.grab.com)
- [Grab Webhooks Guide](https://developer.grab.com/docs/webhooks)
- G06 - Telegram Delivery (sends delivery updates)
- G07 - Settlement (triggers fulfillment)
