# Telegraph E-Commerce Database

This directory contains the PostgreSQL database schema for the Telegraph E-Commerce platform, a Cambodia GaaP-compliant Telegram commerce system.

## Files

- **schema.sql** - Complete database schema with all tables, types, indexes, and triggers
- **migrations/** - Database migration files (for schema updates)

## Database Structure

### Custom Types

- `order_status` - Order lifecycle states (pending, confirmed, paid, fulfilled, completed, cancelled, refunded)
- `payment_status` - Payment states (pending, authorized, captured, settled, failed, expired, refunded)
- `identity_level` - Customer identity verification levels (anonymous, basic, verified, high_assurance)
- `amount_band` - GaaP amount bands for policy decisions (A: ≤$10, B: $10-100, C: $100-1K, D: >$1K)

### Core Tables

1. **merchants** - Merchant/vendor information
2. **customers** - Customer profiles with CamDigiKey integration
3. **products** - Product catalog with GaaP amount bands
4. **orders** - Customer orders from Telegram
5. **order_items** - Line items for each order
6. **payment_intents** - CamDX payment intents with KHQR codes
7. **settlements** - Bakong settlement verification
8. **fulfillments** - Grab delivery fulfillment tracking
9. **audit_logs** - CamDL blockchain audit trail

## Setup Instructions

### Prerequisites

- PostgreSQL 13+ installed
- Database user with CREATE privileges
- `psql` command-line tool

### Installation

#### 1. Install PostgreSQL

**macOS (Homebrew):**
```bash
brew install postgresql@15
brew services start postgresql@15
```

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
```

**Windows:**
Download from https://www.postgresql.org/download/windows/

#### 2. Create Database

```bash
# Connect to PostgreSQL
psql -U postgres

# Create database
CREATE DATABASE telegraph_commerce;

# Create user (optional)
CREATE USER telegraph_user WITH PASSWORD 'your_password_here';

# Grant privileges
GRANT ALL PRIVILEGES ON DATABASE telegraph_commerce TO telegraph_user;

# Exit
\q
```

#### 3. Load Schema

```bash
# From the project root directory
psql -U postgres -d telegraph_commerce -f database/schema.sql

# Or with custom user
psql -U telegraph_user -d telegraph_commerce -f database/schema.sql
```

#### 4. Verify Installation

```bash
# Connect to database
psql -U postgres -d telegraph_commerce

# List tables
\dt

# Check data
SELECT * FROM merchants;
SELECT * FROM products;

# Exit
\q
```

### Expected Output

You should see 8 tables created:
- merchants
- customers
- products
- orders
- order_items
- payment_intents
- settlements
- fulfillments
- audit_logs

And default data:
- 1 merchant (Num Pang Express)
- 5 products (P001-P005)

## Configuration for n8n

### PostgreSQL Node Configuration

In your n8n workflows, configure the PostgreSQL node with these credentials:

```
Host: localhost (or your database host)
Port: 5432
Database: telegraph_commerce
User: telegraph_user (or postgres)
Password: your_password_here
SSL: Disable (for local development)
```

### Connection String

Alternative connection string format:
```
postgresql://telegraph_user:your_password_here@localhost:5432/telegraph_commerce
```

## Database Views

The schema includes two helpful views:

### active_orders
Shows all orders that are not completed, cancelled, or refunded.

```sql
SELECT * FROM active_orders;
```

### pending_settlements
Shows payment intents awaiting settlement with expiry countdown.

```sql
SELECT * FROM pending_settlements;
```

## Maintenance

### Backup Database

```bash
pg_dump -U postgres telegraph_commerce > backup_$(date +%Y%m%d).sql
```

### Restore Database

```bash
psql -U postgres -d telegraph_commerce < backup_20250101.sql
```

### Reset Database

```bash
# Drop and recreate
psql -U postgres -c "DROP DATABASE telegraph_commerce;"
psql -U postgres -c "CREATE DATABASE telegraph_commerce;"
psql -U postgres -d telegraph_commerce -f database/schema.sql
```

## Migrations

Future schema changes will be stored in the `migrations/` directory with numbered files:

```
migrations/
  001_add_customer_preferences.sql
  002_add_product_inventory.sql
  ...
```

## Security Notes

- Never commit database credentials to Git
- Use strong passwords in production
- Enable SSL for remote connections
- Restrict database user permissions in production
- Regular backups are essential

## GaaP Compliance

This database schema is designed to support Cambodia GaaP framework:

- **Layer 1 (Identity):** `customers.identity_level`, `customers.camdigi_key_id`
- **Layer 2 (Interoperability):** `payment_intents.camdx_correlation_id`
- **Layer 3 (Payments):** `payment_intents.khqr_*`, `settlements.bakong_tx_id`
- **Layer 4 (Compliance):** `audit_logs.camdl_*`, SHA256 event hashing
- **Layer 6 (Sectoral):** `fulfillments.grab_delivery_id`

## Troubleshooting

### Connection Refused
```bash
# Check if PostgreSQL is running
sudo systemctl status postgresql

# Start PostgreSQL
sudo systemctl start postgresql
```

### Permission Denied
```bash
# Grant privileges to user
psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE telegraph_commerce TO telegraph_user;"
```

### Table Already Exists
The schema.sql includes `DROP TABLE IF EXISTS` statements, so you can safely re-run it to reset the database.

## Support

For issues or questions:
- Email: contact@omnidm.ai
- GitHub Issues: https://github.com/myownipgit/Omnidm-Telegram-GaaP-Compliant-Workflow/issues
