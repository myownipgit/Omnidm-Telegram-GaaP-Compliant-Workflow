# n8n Engineer

## Subagent Role

**Expert in n8n workflow implementation, node configuration, and technical validation.**

This subagent specializes in:
- n8n node configuration (HTTP Request, PostgreSQL, Function, Switch, etc.)
- Workflow design patterns (polling, webhooks, error handling)
- Expression syntax (`{{ }}`, `$json`, `$node`, `$input`)
- JavaScript/Python code nodes
- Workflow validation and debugging
- Performance optimization
- Credential management

---

## Invocation Pattern

Copy-paste this prompt to invoke the n8n Engineer:

```
You are an n8n Workflow Engineer with expertise in building robust, production-grade
n8n workflows. Your role is to implement technical workflows, configure nodes correctly,
and ensure workflows follow best practices.

I need help with: [DESCRIBE YOUR TECHNICAL REQUIREMENT]

Current context:
- Workflow purpose: [e.g., payment polling, webhook processing]
- Nodes involved: [e.g., HTTP Request, PostgreSQL, Function]
- Integration endpoints: [e.g., Bakong API, CamDigiKey]
- Technical challenges: [e.g., error handling, data transformation]

Please provide:
1. Complete n8n workflow JSON (ready to import)
2. Node-by-node configuration details
3. Expression syntax examples
4. Error handling implementation
5. Testing and validation steps
```

---

## Input Checklist

Before invoking, gather this information:

- [ ] **Workflow Requirements**
  - What does the workflow do? (clear description)
  - What triggers it? (webhook, cron, manual)
  - What is the expected output?
  - What are the success/failure conditions?

- [ ] **Integration Details**
  - API endpoints to call (full URLs)
  - Authentication methods (API key, OAuth2, Basic Auth)
  - Request/response formats (JSON, XML, form data)
  - Rate limits or constraints

- [ ] **Data Requirements**
  - Input data structure (sample JSON)
  - Data transformations needed
  - Database schema (if applicable)
  - Validation rules

- [ ] **Technical Constraints**
  - n8n version (e.g., 1.121.3)
  - Execution timeout limits
  - Memory constraints
  - Retry/polling requirements

- [ ] **Error Handling**
  - What errors can occur?
  - How should errors be handled? (retry, alert, log)
  - Fallback behaviors needed?

---

## Expected Deliverables

The n8n Engineer will provide:

1. **Complete Workflow JSON**
   ```json
   {
     "name": "[KH.GaaS] Workflow Name",
     "nodes": [
       {
         "parameters": {
           "httpMethod": "POST",
           "url": "https://api.example.com/endpoint",
           "authentication": "predefinedCredentialType",
           "nodeCredentialType": "httpHeaderAuth",
           "sendBody": true,
           "bodyParameters": {
             "parameters": [
               {
                 "name": "key",
                 "value": "={{ $json.value }}"
               }
             ]
           }
         },
         "name": "HTTP Request",
         "type": "n8n-nodes-base.httpRequest",
         "typeVersion": 4.2,
         "position": [250, 300]
       }
     ],
     "connections": {
       "Trigger": {
         "main": [[{ "node": "HTTP Request", "type": "main", "index": 0 }]]
       }
     }
   }
   ```

2. **Node Configuration Guide**
   - Step-by-step configuration for each node
   - Parameter explanations
   - Expression syntax examples
   - Credential setup instructions

3. **Expression Reference**
   ```javascript
   // Access JSON from previous node
   {{ $json.field_name }}

   // Access specific node output
   {{ $node["Node Name"].json.field }}

   // Access all items
   {{ $input.all() }}

   // Date formatting
   {{ $now.format('YYYY-MM-DD') }}

   // Conditional logic
   {{ $json.amount > 100 ? 'high' : 'low' }}
   ```

4. **Error Handling Patterns**
   - Try/catch in Function nodes
   - Error Trigger workflows
   - Retry logic with exponential backoff
   - Dead letter queue patterns

5. **Testing Checklist**
   - Test data examples
   - Expected outputs
   - Edge cases to test
   - Validation commands

---

## Skills to Use

When working with the n8n Engineer, leverage:

- **n8n-node-configuration** - For configuring specific node types
- **n8n-code-javascript** - For Function node JavaScript code
- **n8n-code-python** - For Function node Python code
- **n8n-expression-syntax** - For expression validation
- **n8n-validation-expert** - For workflow validation
- **n8n-workflow-patterns** - For design patterns

---

## Common Patterns

### Pattern 1: HTTP Request with Error Handling

**Scenario:** Call external API with automatic retries

**Implementation:**
```javascript
n8n Nodes:

1. HTTP Request Node:
   - Method: POST
   - URL: https://api.bakong.nbc.gov.kh/v1/khqr/generate
   - Authentication: Predefined Credential Type → API Key
   - Options:
     - Retry on Fail: ✅ Enabled
     - Max Tries: 3
     - Wait Between Tries: 1000ms
     - Continue on Fail: ✅ Enabled (so we can catch errors)
   - Body:
     {
       "merchant_id": "{{ $json.merchant_id }}",
       "amount": "{{ $json.amount }}"
     }

2. IF Node (Check for errors):
   - Condition: {{ $json.error }} exists
   - True → Error Handler
   - False → Success Path

3. Function Node (Error Handler):
   const error = $input.item.json.error;
   const originalData = $input.item.json;

   // Log error
   console.error('API Error:', error);

   // Return structured error
   return {
     json: {
       status: 'error',
       error_type: error.type || 'unknown',
       error_message: error.message || 'API request failed',
       original_request: originalData,
       timestamp: new Date().toISOString()
     }
   };

4. PostgreSQL Node (Log Error):
   INSERT INTO error_logs (error_type, error_message, request_data, created_at)
   VALUES (
     '{{ $json.error_type }}',
     '{{ $json.error_message }}',
     '{{ $json.original_request }}',
     CURRENT_TIMESTAMP
   );

5. Telegram Alert (Notify Admin):
   ⚠️ API Error Detected

   Type: {{ $json.error_type }}
   Message: {{ $json.error_message }}
   Time: {{ $json.timestamp }}
```

### Pattern 2: Polling with Timeout

**Scenario:** Poll API every 3 seconds until status changes or timeout

**Implementation:**
```javascript
1. Trigger Node (Start polling):
   - Type: Manual / Webhook

2. Set Node (Initialize variables):
   {
     "max_attempts": 100,  // 100 × 3s = 300s (5 min timeout)
     "attempt": 0,
     "status": "pending",
     "md5_hash": "{{ $json.khqr_md5_hash }}"
   }

3. Loop Node:
   - Loop Until: {{ $json.status }} !== 'pending' OR {{ $json.attempt }} >= {{ $json.max_attempts }}

4. Wait Node:
   - Wait Time: 3 seconds

5. HTTP Request (Check status):
   GET https://api.bakong.nbc.gov.kh/v1/settlement/check?md5_hash={{ $json.md5_hash }}

   Response:
   {
     "status": "settled" | "pending" | "failed",
     "transaction_id": "BKG-2025-TXN-123"
   }

6. Function Node (Update loop variables):
   const currentAttempt = $node["Set"].json.attempt || 0;
   const status = $input.item.json.status;

   return {
     json: {
       attempt: currentAttempt + 1,
       status: status,
       md5_hash: $node["Set"].json.md5_hash,
       max_attempts: $node["Set"].json.max_attempts,
       result: $input.item.json
     }
   };

7. IF Node (After loop - Check result):
   - Condition: {{ $json.status }} === 'settled'
   - True → Success Path
   - False → Timeout/Failed Path

8A. Success Path:
   PostgreSQL → Update payment_intents SET payment_status = 'captured'

8B. Timeout Path:
   PostgreSQL → Update payment_intents SET payment_status = 'expired'
   Telegram → Notify customer: "Payment timeout"
```

### Pattern 3: Batch Processing with Rate Limiting

**Scenario:** Process 1000 invoices, max 10 requests/second

**Implementation:**
```javascript
1. Cron Trigger:
   - Schedule: Daily at 9 AM

2. PostgreSQL (Fetch pending invoices):
   SELECT invoice_id, customer_id, amount
   FROM invoices
   WHERE status = 'pending'
   LIMIT 1000;

3. Split In Batches Node:
   - Batch Size: 10
   - Options → Reset: ✅ Enabled

4. Loop Over Items:
   - Items to Process: {{ $json }}

5. HTTP Request (Process each invoice):
   POST https://caminvoice.mef.gov.kh/api/v1/submit
   Body: {{ $json }}

6. Wait Node:
   - Wait Time: 1 second (ensures max 10/sec)

7. Function Node (Aggregate results):
   const allResults = $input.all();

   const summary = {
     total: allResults.length,
     success: allResults.filter(r => r.json.status === 'success').length,
     failed: allResults.filter(r => r.json.status === 'error').length,
     errors: allResults
       .filter(r => r.json.status === 'error')
       .map(r => ({ invoice_id: r.json.invoice_id, error: r.json.error }))
   };

   return { json: summary };

8. Telegram Summary:
   📊 Batch Invoice Processing Complete

   Total: {{ $json.total }}
   ✅ Success: {{ $json.success }}
   ❌ Failed: {{ $json.failed }}

   {{ $json.failed > 0 ? 'Errors:\n' + $json.errors.map(e => `- Invoice ${e.invoice_id}: ${e.error}`).join('\n') : '' }}
```

---

## Example Usage

### Example 1: Configure HTTP Request Node for Bakong KHQR

**Prompt:**
```
I need to configure an HTTP Request node to call the Bakong KHQR generation API.
Show me the exact configuration with authentication and error handling.
```

**Expected Response:**
```
Bakong KHQR HTTP Request Node Configuration:

Node Type: HTTP Request (n8n-nodes-base.httpRequest)
Type Version: 4.2

Basic Configuration:
┌─────────────────────────────────────┐
│ Method: POST                        │
│ URL: https://api.bakong.nbc.gov.kh/v1/khqr/generate │
└─────────────────────────────────────┘

Authentication:
┌─────────────────────────────────────┐
│ Authentication: Predefined Credential Type │
│ Credential Type: API Key            │
│                                     │
│ Create new credential:              │
│ - Name: Bakong API Key              │
│ - Header Name: X-API-Key            │
│ - API Key: [Your Bakong API key]    │
└─────────────────────────────────────┘

Headers:
┌─────────────────────────────────────┐
│ Content-Type: application/json      │
│ Accept: application/json            │
└─────────────────────────────────────┘

Body Parameters (JSON):
┌─────────────────────────────────────┐
│ Send Body: ✅ Yes                    │
│ Body Content Type: JSON             │
│                                     │
│ JSON:                               │
│ {                                   │
│   "merchant_id": "={{ $json.merchant_khqr_id }}",  │
│   "merchant_name": "Num Pang Express", │
│   "merchant_city": "Phnom Penh",    │
│   "mcc": "5814",                    │
│   "amount": "={{ $json.amount }}",  │
│   "currency": "USD",                │
│   "reference": {                    │
│     "order_id": "={{ $json.order_id }}", │
│     "intent_id": "={{ $json.intent_id }}" │
│   },                                │
│   "bill_number": "={{ $json.order_id }}", │
│   "ttl_seconds": 900                │
│ }                                   │
└─────────────────────────────────────┘

Options (Click "Add Option"):
┌─────────────────────────────────────┐
│ ✅ Retry On Fail                     │
│    - Max Tries: 3                   │
│    - Wait Between Tries (ms): 1000  │
│                                     │
│ ✅ Response                          │
│    - Response Format: JSON          │
│                                     │
│ ✅ Timeout (ms): 10000               │
│                                     │
│ ⚠️ Continue On Fail: Enabled        │
│    (So we can handle errors)        │
└─────────────────────────────────────┘

Expected Response:
{
  "qr_string": "00020101021230820016khqr.aba@ababank...",
  "qr_image": "data:image/png;base64,iVBORw0KG...",
  "deeplink": "https://bakong.nbc.gov.kh/qr?data=...",
  "md5_hash": "5f4dcc3b5aa765d61d8327deb882cf99",
  "expires_at": "2025-01-01T10:15:00Z"
}

Error Response (if API fails):
{
  "error": {
    "type": "invalid_merchant",
    "message": "Merchant ID not registered",
    "code": "ERR_MERCHANT_001"
  }
}

Next Node (Error Check):
Add an IF node after HTTP Request:
- Condition: {{ $json.error }} exists
- True branch → Error handler
- False branch → Store KHQR data

Expression Examples:
// Access QR string
{{ $json.qr_string }}

// Access from specific node
{{ $node["HTTP Request"].json.md5_hash }}

// Check if error exists
{{ $json.error !== undefined }}

Testing:
1. Execute node manually
2. Check execution data (bottom panel)
3. Verify response structure matches expected
4. Test error case (use invalid merchant_id)
```

### Example 2: Function Node for VAT Calculation

**Prompt:**
```
Write a Function node in JavaScript to calculate VAT (10%) for an order with
multiple line items. Input is an array of items with quantity and unit_price.
```

**Expected Response:**
```
Function Node: Calculate VAT for Order

Language: JavaScript

Code:
```javascript
// Input: Array of line items from previous node
// Each item has: { product_name, quantity, unit_price }

const items = $input.all();

// Calculate line item totals
const lineItems = items.map(item => {
  const data = item.json;
  const subtotal = data.quantity * data.unit_price;
  const vatAmount = subtotal * 0.10;  // 10% VAT
  const total = subtotal + vatAmount;

  return {
    product_name: data.product_name,
    product_id: data.product_id,
    quantity: data.quantity,
    unit_price: parseFloat(data.unit_price.toFixed(2)),
    subtotal: parseFloat(subtotal.toFixed(2)),
    vat_rate: 0.10,
    vat_amount: parseFloat(vatAmount.toFixed(2)),
    total: parseFloat(total.toFixed(2))
  };
});

// Calculate order totals
const orderSubtotal = lineItems.reduce((sum, item) => sum + item.subtotal, 0);
const orderVatTotal = lineItems.reduce((sum, item) => sum + item.vat_amount, 0);
const orderGrandTotal = lineItems.reduce((sum, item) => sum + item.total, 0);

// Return structured result
return {
  json: {
    line_items: lineItems,
    totals: {
      subtotal: parseFloat(orderSubtotal.toFixed(2)),
      vat_total: parseFloat(orderVatTotal.toFixed(2)),
      grand_total: parseFloat(orderGrandTotal.toFixed(2))
    },
    item_count: lineItems.length,
    calculated_at: new Date().toISOString()
  }
};
```

Input Example:
```json
[
  { "product_name": "Num Pang Classic", "product_id": "P001", "quantity": 2, "unit_price": 3.50 },
  { "product_name": "Iced Coffee", "product_id": "P002", "quantity": 1, "unit_price": 2.00 }
]
```

Output:
```json
{
  "line_items": [
    {
      "product_name": "Num Pang Classic",
      "product_id": "P001",
      "quantity": 2,
      "unit_price": 3.50,
      "subtotal": 7.00,
      "vat_rate": 0.10,
      "vat_amount": 0.70,
      "total": 7.70
    },
    {
      "product_name": "Iced Coffee",
      "product_id": "P002",
      "quantity": 1,
      "unit_price": 2.00,
      "subtotal": 2.00,
      "vat_rate": 0.10,
      "vat_amount": 0.20,
      "total": 2.20
    }
  ],
  "totals": {
    "subtotal": 9.00,
    "vat_total": 0.90,
    "grand_total": 9.90
  },
  "item_count": 2,
  "calculated_at": "2025-01-01T10:00:00.000Z"
}
```

Configuration in n8n:
1. Add Function node after item query
2. Select "Run Once for All Items" mode
3. Paste code above
4. Test with sample data
5. Verify output structure

Usage in Next Node (PostgreSQL):
```sql
UPDATE orders
SET subtotal = {{ $json.totals.subtotal }},
    vat_total = {{ $json.totals.vat_total }},
    grand_total = {{ $json.totals.grand_total }}
WHERE order_id = '{{ $('Order').item.json.order_id }}';
```

Error Handling Enhancement:
```javascript
try {
  const items = $input.all();

  // Validate input
  if (!items || items.length === 0) {
    throw new Error('No line items provided');
  }

  // Validate each item has required fields
  items.forEach((item, index) => {
    if (!item.json.quantity || !item.json.unit_price) {
      throw new Error(`Item ${index} missing quantity or unit_price`);
    }
  });

  // ... calculation code ...

  return { json: result };

} catch (error) {
  return {
    json: {
      error: true,
      error_message: error.message,
      error_timestamp: new Date().toISOString()
    }
  };
}
```
```

---

## Best Practices

1. **Use Descriptive Node Names**
   - ✅ "HTTP Request - Generate KHQR"
   - ❌ "HTTP Request"

2. **Enable "Continue on Fail" for Error Handling**
   - Allows error branches in workflow
   - Prevents entire workflow crash

3. **Set Appropriate Timeouts**
   - HTTP requests: 10-30 seconds
   - Database queries: 5-10 seconds
   - External APIs: 15-60 seconds

4. **Use Credentials, Never Hardcode Secrets**
   - Store API keys in n8n credentials
   - Reference with {{ $credentials }}
   - Never commit credentials to version control

5. **Test with Real Data**
   - Use production-like test data
   - Test error scenarios
   - Validate all branches

6. **Add Retry Logic for Network Calls**
   - Max 3 retries recommended
   - Exponential backoff (1s, 2s, 4s)
   - Log failures after retries exhausted

7. **Use Expression Syntax Correctly**
   - {{ $json.field }} for current item
   - {{ $node["Name"].json.field }} for specific node
   - {{ $input.all() }} for all items in Function node

8. **Implement Proper Error Logging**
   - Log to database or file
   - Include timestamp, error type, context
   - Alert on critical errors

---

## Common Issues & Solutions

**Issue 1: Expression syntax error "Cannot read property"**
- **Cause:** Field doesn't exist or wrong node reference
- **Solution:** Use {{ $json?.field }} (optional chaining) or check node name

**Issue 2: Function node times out**
- **Cause:** Infinite loop or expensive operation
- **Solution:** Add timeout, optimize code, use streaming for large datasets

**Issue 3: HTTP Request returns 401 Unauthorized**
- **Cause:** Missing or invalid credentials
- **Solution:** Verify credential configuration, check API key validity

**Issue 4: Workflow execution skipped**
- **Cause:** Previous node returned no data
- **Solution:** Check IF node conditions, add default/fallback paths

**Issue 5: Database connection errors**
- **Cause:** Network issues or wrong credentials
- **Solution:** Verify connection string, check firewall, test credentials

---

## Related Documentation

- n8n Documentation: `https://docs.n8n.io`
- Expression Reference: `https://docs.n8n.io/code/expressions/`
- Node Reference: `https://docs.n8n.io/integrations/builtin/`
- All Workflows: `/workflows/g01-g09/`
- Validation Script: `/scripts/validate-workflows.sh`

---

**Last Updated:** December 2024
**Maintained by:** OmniDM.ai n8n Engineering Team
