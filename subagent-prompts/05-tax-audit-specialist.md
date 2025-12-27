# Tax & Audit Specialist

## Subagent Role

**Expert in Cambodia tax compliance, CamInvoice integration, and CamDL audit trail implementation.**

This subagent specializes in:
- CamInvoice API integration (e-invoice generation, submission)
- VAT/tax calculation for Cambodia (10% VAT standard)
- CamDL blockchain audit trail design
- NBC/MEF compliance reporting
- Invoice lifecycle management (draft → issued → paid → archived)

---

## Invocation Pattern

Copy-paste this prompt to invoke the Tax & Audit Specialist:

```
You are a Cambodia Tax & Audit Specialist with expertise in CamInvoice integration
and CamDL audit trail implementation. Your role is to design tax-compliant workflows
that generate e-invoices, calculate VAT, and maintain immutable audit logs.

I need help with: [DESCRIBE YOUR TAX/AUDIT REQUIREMENT]

Current context:
- Transaction types: [e.g., B2C, B2B, B2G]
- Tax obligations: [e.g., VAT registration, monthly reporting]
- Invoice requirements: [e.g., CamInvoice mandatory, paper backup]
- Audit requirements: [e.g., 7-year retention, blockchain anchoring]

Please provide:
1. CamInvoice integration design (invoice structure, API endpoints)
2. Tax calculation workflow (VAT, WHT, specific goods tax)
3. CamDL audit trail implementation (event logging, hash chains)
4. Compliance reporting automation (monthly VAT, annual tax)
5. Invoice lifecycle management (states, transitions, archival)
```

---

## Input Checklist

Before invoking, gather this information:

- [ ] **Business Context**
  - Business type? (sole proprietor, LLC, corporation)
  - VAT registered? (mandatory if revenue > $62,500/year)
  - Industry? (some industries have specific tax rates)
  - Annual revenue estimate?

- [ ] **Transaction Details**
  - Transaction types? (B2C, B2B, B2G, cross-border)
  - Invoice frequency? (per transaction, batch, monthly)
  - Average transaction value?
  - Currency? (USD, KHR, both)

- [ ] **Tax Requirements**
  - VAT rate applicable? (standard 10%, or exempt)
  - Withholding tax obligations?
  - Specific goods tax? (alcohol, tobacco, luxury items)
  - Tax filing frequency? (monthly, quarterly, annually)

- [ ] **Compliance Context**
  - CamInvoice mandate date? (May 2025 for large businesses)
  - Audit retention period? (7 years for financial)
  - Industry regulator? (NBC for finance, MEF for general)
  - Data residency requirements?

- [ ] **Technical Context**
  - Integration platform (n8n, custom backend)
  - Existing accounting system? (QuickBooks, Xero, custom)
  - Invoice storage approach (database, file system, cloud)

---

## Expected Deliverables

The Tax & Audit Specialist will provide:

1. **CamInvoice Integration Design**
   ```javascript
   // Invoice Generation
   POST https://caminvoice.mef.gov.kh/api/v1/invoices
   {
     "invoice_type": "tax_invoice",
     "seller": {
       "tin": "K001-901234567",  // Tax Identification Number
       "name": "Num Pang Express",
       "address": "Street 240, Phnom Penh",
       "vat_registration": "VAT-20240001"
     },
     "buyer": {
       "tin": "K001-987654321",  // If B2B
       "name": "Chan Sokha",
       "address": "Street 51, Phnom Penh"
     },
     "line_items": [
       {
         "description": "Num Pang Classic",
         "quantity": 2,
         "unit_price": 3.50,
         "subtotal": 7.00,
         "vat_rate": 0.10,
         "vat_amount": 0.70
       }
     ],
     "totals": {
       "subtotal": 7.00,
       "vat_total": 0.70,
       "grand_total": 7.70
     },
     "payment_method": "bakong_khqr",
     "payment_reference": "PI-20250101-0001",
     "invoice_date": "2025-01-01",
     "due_date": "2025-01-01"
   }

   // Response
   {
     "invoice_id": "INV-20250101-0001",
     "caminvoice_reference": "MEF-INV-2025-001234",
     "qr_code": "data:image/png;base64,iVBORw...",  // For verification
     "pdf_url": "https://caminvoice.mef.gov.kh/invoices/MEF-INV-2025-001234.pdf",
     "status": "issued",
     "issued_at": "2025-01-01T10:00:00Z"
   }
   ```

2. **Tax Calculation Workflow**
   - VAT calculation logic (10% standard, exempt items)
   - Withholding tax rules (e.g., 15% on services)
   - Tax rounding rules (to nearest 100 KHR)
   - Multi-currency handling

3. **CamDL Audit Trail Design**
   ```javascript
   // Event Structure
   {
     "event_id": "EVT-20250101-0001",
     "event_type": "invoice.issued",
     "event_timestamp": "2025-01-01T10:00:00Z",
     "actor": {
       "type": "system",
       "identifier": "n8n-workflow-g08"
     },
     "resource": {
       "type": "invoice",
       "id": "INV-20250101-0001",
       "caminvoice_reference": "MEF-INV-2025-001234"
     },
     "event_data": {
       "seller_tin": "K001-901234567",
       "buyer_tin": "K001-987654321",
       "grand_total": 7.70,
       "vat_total": 0.70,
       "payment_status": "pending"
     },
     "event_hash": "sha256:abc123...",
     "previous_event_hash": "sha256:def456...",  // Hash chain
     "blockchain_anchor": {
       "network": "camdl",
       "transaction_id": "0x123abc...",
       "block_number": 1234567,
       "confirmed_at": "2025-01-01T10:00:05Z"
     }
   }
   ```

4. **Compliance Reporting Automation**
   - Monthly VAT report generation
   - Annual tax summary
   - Transaction log exports (CSV, JSON)
   - MEF e-filing integration

5. **n8n Workflow Design**
   - HTTP Request nodes for CamInvoice API
   - Function nodes for tax calculations
   - PostgreSQL nodes for audit log storage
   - Cron nodes for scheduled reporting
   - Blockchain nodes for CamDL anchoring

---

## Skills to Use

When working with the Tax & Audit Specialist, leverage:

- **n8n-node-configuration** - For CamInvoice HTTP Request nodes
- **n8n-code-javascript** - For tax calculation logic, hash generation
- **n8n-workflow-patterns** - For audit trail and reporting patterns

---

## Common Patterns

### Pattern 1: Real-Time Invoice with VAT

**Scenario:** Generate tax invoice immediately after payment confirmed

**Flow:**
```
1. Payment settled (from G07 settlement workflow)
2. Calculate VAT:
   - Subtotal = $7.00
   - VAT (10%) = $0.70
   - Grand total = $7.70
3. Call CamInvoice API:
   - Submit invoice with line items
   - Include payment reference (KHQR md5_hash)
   - Set status = issued
4. Store invoice reference in database
5. Log event to CamDL:
   - Event type: invoice.issued
   - Generate SHA256 hash
   - Link to previous event (hash chain)
   - Anchor to blockchain
6. Send invoice to customer:
   - Telegram PDF attachment
   - QR code for verification
7. Update order status → fulfilled
```

**n8n Nodes:**
- Function (VAT calculation)
- HTTP Request (CamInvoice)
- PostgreSQL (store invoice reference)
- Function (generate event hash)
- HTTP Request (CamDL anchor)
- Telegram Send Document

### Pattern 2: Batch Monthly Invoicing

**Scenario:** B2B customer receives monthly consolidated invoice

**Flow:**
```
1. Cron trigger (1st of each month, 9 AM)
2. Query all transactions for customer in previous month
3. Group by product/service
4. Calculate totals:
   - Sum all subtotals
   - Calculate total VAT (10%)
   - Add any discounts/adjustments
5. Generate consolidated invoice via CamInvoice
6. Send to customer email + Telegram
7. Log to CamDL
8. Schedule payment reminder (due date - 7 days)
```

### Pattern 3: Tax Reporting Automation

**Scenario:** Submit monthly VAT report to MEF automatically

**Flow:**
```
1. Cron trigger (20th of each month for previous month)
2. Query audit_logs for all invoice.issued events
3. Aggregate:
   - Total sales (excluding VAT)
   - Total VAT collected
   - Number of invoices
4. Generate VAT report:
   POST https://mef.gov.kh/api/v1/vat-reports
   {
     "period": "2025-01",
     "tin": "K001-901234567",
     "total_sales": 45000.00,
     "total_vat": 4500.00,
     "invoice_count": 1234
   }
5. Receive confirmation from MEF
6. Store report reference
7. Notify accountant via email
```

---

## Example Usage

### Example 1: Simple B2C Invoice with VAT

**Prompt:**
```
I need to generate a tax invoice for a $3.50 sandwich order. Customer paid via
Bakong KHQR. How do I integrate CamInvoice and calculate VAT correctly?
```

**Expected Response:**
```
CamInvoice Integration for B2C Transaction:

Step 1: Calculate VAT
Subtotal: $3.50
VAT (10%): $3.50 × 0.10 = $0.35
Grand Total: $3.50 + $0.35 = $3.85

Note: Customer already paid $3.50 (VAT-inclusive pricing assumed).
If VAT was not included in price, charge $3.85.

Step 2: Generate Invoice via CamInvoice
POST https://caminvoice.mef.gov.kh/api/v1/invoices

Request Body:
{
  "invoice_type": "simplified_tax_invoice",  // B2C allows simplified
  "seller": {
    "tin": "{{ $('Config').item.json.seller_tin }}",
    "name": "Num Pang Express",
    "address": "Street 240, Phnom Penh",
    "vat_registration": "VAT-20240001"
  },
  "buyer": {
    "name": "Sokha Chen",  // TIN optional for B2C
    "phone": "+855 12 345 678"
  },
  "line_items": [
    {
      "description": "Num Pang Classic",
      "quantity": 1,
      "unit_price": 3.50,
      "vat_rate": 0.10,
      "vat_amount": 0.35,
      "total": 3.85
    }
  ],
  "totals": {
    "subtotal": 3.50,
    "vat_total": 0.35,
    "grand_total": 3.85
  },
  "payment_method": "bakong_khqr",
  "payment_reference": "{{ $('Settlement').item.json.khqr_md5_hash }}",
  "payment_status": "paid",
  "invoice_date": "{{ $now.format('YYYY-MM-DD') }}"
}

Step 3: Store Invoice Reference
UPDATE orders
SET invoice_id = '{{ $json.invoice_id }}',
    caminvoice_reference = '{{ $json.caminvoice_reference }}',
    invoice_pdf_url = '{{ $json.pdf_url }}'
WHERE order_id = '{{ $('Order').item.json.order_id }}';

Step 4: Log to CamDL Audit Trail
Function Node (Generate Event Hash):
const crypto = require('crypto');

const event = {
  event_type: 'invoice.issued',
  invoice_id: $input.item.json.invoice_id,
  caminvoice_reference: $input.item.json.caminvoice_reference,
  grand_total: 3.85,
  vat_total: 0.35,
  timestamp: new Date().toISOString()
};

const eventString = JSON.stringify(event, Object.keys(event).sort());
const eventHash = crypto.createHash('sha256').update(eventString).digest('hex');

return {
  event,
  event_hash: `sha256:${eventHash}`
};

PostgreSQL Node (Store in audit_logs):
INSERT INTO audit_logs (event_type, event_data, event_hash, created_at)
VALUES (
  'invoice.issued',
  '{{ $json.event }}',
  '{{ $json.event_hash }}',
  CURRENT_TIMESTAMP
);

Step 5: Send Invoice to Customer
Telegram Send Document Node:
- Document: {{ $('CamInvoice').item.json.pdf_url }}
- Caption:
"📄 Tax Invoice

Invoice: {{ $json.caminvoice_reference }}
Amount: $3.50 + VAT $0.35 = $3.85

Status: PAID ✅

Download: [Tap to view invoice]

Thank you for your order!"

VAT Calculation Notes:
- Cambodia standard VAT: 10%
- Exempt items: Unprocessed food, medicines, educational services
- For Num Pang (prepared food): 10% VAT applies
- VAT must be shown separately on invoice
```

### Example 2: B2B Monthly Invoice with Multiple Line Items

**Prompt:**
```
I have a corporate client who orders catering monthly (10-20 orders). I need to
send them one consolidated invoice at month-end with all orders. Show me the workflow.
```

**Expected Response:**
```
B2B Consolidated Monthly Invoice Workflow:

Step 1: Cron Trigger (Monthly)
Schedule: 1st of month, 9:00 AM
Workflow: G08 Tax Invoice

Step 2: Query Previous Month's Orders
PostgreSQL Node:
SELECT
  o.order_id,
  o.created_at,
  oi.product_id,
  p.name AS product_name,
  oi.quantity,
  oi.unit_price,
  oi.subtotal
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.customer_id = 'B2B-CORP-001'
  AND o.created_at >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
  AND o.created_at < DATE_TRUNC('month', CURRENT_DATE)
  AND o.order_status = 'delivered'
ORDER BY o.created_at;

Result Example:
[
  { order_id: 'ORD-001', product_name: 'Catering Package A', quantity: 50, unit_price: 5.00, subtotal: 250.00 },
  { order_id: 'ORD-002', product_name: 'Catering Package B', quantity: 100, unit_price: 7.00, subtotal: 700.00 },
  ...
]

Step 3: Aggregate Line Items
Function Node:
const orders = $input.all();

// Group by product
const grouped = orders.reduce((acc, order) => {
  const key = order.json.product_id;
  if (!acc[key]) {
    acc[key] = {
      product_id: order.json.product_id,
      product_name: order.json.product_name,
      quantity: 0,
      unit_price: order.json.unit_price,
      subtotal: 0
    };
  }
  acc[key].quantity += order.json.quantity;
  acc[key].subtotal += order.json.subtotal;
  return acc;
}, {});

const lineItems = Object.values(grouped);

// Calculate totals
const subtotal = lineItems.reduce((sum, item) => sum + item.subtotal, 0);
const vatTotal = subtotal * 0.10;
const grandTotal = subtotal + vatTotal;

return {
  line_items: lineItems,
  subtotal,
  vat_total: vatTotal,
  grand_total: grandTotal,
  period: '2025-01',
  order_count: orders.length
};

Step 4: Generate Consolidated Invoice
HTTP Request Node (CamInvoice):
POST https://caminvoice.mef.gov.kh/api/v1/invoices

Body:
{
  "invoice_type": "tax_invoice",
  "seller": {
    "tin": "K001-901234567",
    "name": "Num Pang Express",
    "vat_registration": "VAT-20240001"
  },
  "buyer": {
    "tin": "K001-555555555",
    "name": "ABC Corporation Ltd.",
    "address": "Building 123, Street 214, Phnom Penh"
  },
  "line_items": {{ $json.line_items.map(item => ({
    description: item.product_name,
    quantity: item.quantity,
    unit_price: item.unit_price,
    subtotal: item.subtotal,
    vat_rate: 0.10,
    vat_amount: item.subtotal * 0.10
  })) }},
  "totals": {
    "subtotal": {{ $json.subtotal }},
    "vat_total": {{ $json.vat_total }},
    "grand_total": {{ $json.grand_total }}
  },
  "period": "January 2025",
  "invoice_date": "{{ $now.format('YYYY-MM-DD') }}",
  "due_date": "{{ $now.plus({ days: 30 }).format('YYYY-MM-DD') }}",
  "payment_terms": "Net 30",
  "notes": "Consolidated invoice for {{ $('Aggregate').item.json.order_count }} catering orders in January 2025."
}

Step 5: Store Invoice Reference
UPDATE customers
SET last_invoice_id = '{{ $json.invoice_id }}',
    last_invoice_date = CURRENT_TIMESTAMP
WHERE customer_id = 'B2B-CORP-001';

Step 6: Send Invoice
Email Node:
To: accounting@abccorp.com
Subject: Invoice {{ $json.caminvoice_reference }} - January 2025
Body:
Dear ABC Corporation,

Please find attached your consolidated tax invoice for January 2025.

Period: January 1-31, 2025
Total Orders: {{ $('Aggregate').item.json.order_count }}
Subtotal: ${{ $('Aggregate').item.json.subtotal }}
VAT (10%): ${{ $('Aggregate').item.json.vat_total }}
Grand Total: ${{ $('Aggregate').item.json.grand_total }}

Payment Due: {{ $now.plus({ days: 30 }).format('MMMM DD, YYYY') }}

Download Invoice: {{ $json.pdf_url }}

Best regards,
Num Pang Express

Attachments:
- {{ $json.pdf_url }}

Step 7: Schedule Payment Reminder
Wait Node: 23 days (7 days before due date)

Then Send Reminder:
Email:
Subject: Payment Reminder - Invoice {{ $json.caminvoice_reference }}
Body: Your invoice is due in 7 days...
```

---

## Best Practices

1. **Always Calculate VAT Separately**
   - Show VAT as separate line item
   - Never hide VAT in price (B2B requirement)
   - Use exact 10% rate (0.10)

2. **Store CamInvoice References**
   - Always save caminvoice_reference
   - Link to order/payment records
   - Enable invoice lookup by reference

3. **Implement Hash Chains for Audit Trail**
   - Each event references previous event hash
   - Ensures immutability
   - Detects tampering

4. **Handle Tax Exemptions Correctly**
   - Unprocessed food: VAT exempt
   - Prepared food (Num Pang): 10% VAT
   - Check MEF guidelines for your products

5. **Automate Tax Reporting**
   - Monthly VAT reports (due 20th of following month)
   - Annual tax summary
   - Reduce manual accounting work

6. **Blockchain Anchoring for High-Value**
   - Anchor invoices >$1,000 to CamDL
   - Provides immutable proof
   - Required for audits

---

## Common Issues & Solutions

**Issue 1: VAT calculation rounding errors**
- **Solution:** Use fixed-point arithmetic, round to 2 decimals at end

**Issue 2: CamInvoice reference not received**
- **Solution:** Implement retry with exponential backoff, store draft locally

**Issue 3: Duplicate invoices generated**
- **Solution:** Check if invoice exists before creating, use idempotency keys

**Issue 4: Hash chain broken**
- **Solution:** Verify previous_event_hash exists, rebuild from last valid event

**Issue 5: Customer disputes invoice amount**
- **Solution:** Provide audit trail with CamDL proof, show hash chain integrity

---

## Related Documentation

- CamInvoice API: `https://caminvoice.mef.gov.kh/docs`
- Tax Invoice Workflow: `/workflows/g08-tax-invoice/`
- Audit Workflow: `/workflows/g09-audit/`
- Database Schema: `/database/schema.sql` (audit_logs table)
- MEF VAT Guidelines: `https://mef.gov.kh/vat`

---

**Last Updated:** December 2024
**Maintained by:** OmniDM.ai Tax & Compliance Team
