# Revenue Calculation & Debt Reporting Changes

## Overview
This document describes the changes made to the sales revenue calculation and debt reporting system.

## Changes Made

### 1. Revenue Calculation Update

**Previous Behavior:**
- Sales reports showed total sales amount (including unpaid/outstanding amounts)
- Revenue included money that hadn't been received yet

**New Behavior:**
- Sales reports now show only cash received (paid amounts)
- Outstanding amounts are tracked separately as debts
- Revenue = Sum of `paid` amounts, not `total` amounts

### 2. Files Modified

#### Backend (PHP)
- **File:** `backend-php/routes/reports.php`
  - **Line 31:** Changed `SUM(total)` to `SUM(paid)` in `sales_summary()` function
  - **Added:** Debt reporting endpoints:
    - `GET /reports/debts/daily?date=YYYY-MM-DD`
    - `GET /reports/debts/weekly?week_start=YYYY-MM-DD`
    - `GET /reports/debts/monthly?month=M&year=YYYY`

#### Backend (Python/Flask)
- **File:** `backend/app/routes/reports.py`
  - **Lines 30, 56, 111:** Changed `func.sum(Sale.total)` to `func.sum(Sale.paid)`
  - **Lines 69, 120:** Changed product breakdown to use `Sale.paid` instead of `Sale.total`
  - **Added:** Debt reporting endpoints:
    - `GET /reports/debts/daily?date=YYYY-MM-DD`
    - `GET /reports/debts/weekly?week_start=YYYY-MM-DD`
    - `GET /reports/debts/monthly?month=M&year=YYYY`

## New Debt Reporting Endpoints

### Daily Debt Report
```
GET /reports/debts/daily?date=2026-03-10
```

**Response:**
```json
{
  "date": "2026-03-10",
  "sales": [...],
  "total_debt_created": 50000.00,
  "total_paid": 30000.00,
  "total_amount": 80000.00,
  "debt_count": 5
}
```

### Weekly Debt Report
```
GET /reports/debts/weekly?week_start=2026-03-03
```

**Response:**
```json
{
  "week_start": "2026-03-03",
  "week_end": "2026-03-09",
  "sales": [...],
  "total_debt_created": 150000.00,
  "total_paid": 100000.00,
  "total_amount": 250000.00,
  "debt_count": 15
}
```

### Monthly Debt Report
```
GET /reports/debts/monthly?month=3&year=2026
```

**Response:**
```json
{
  "month": 3,
  "year": 2026,
  "sales": [...],
  "total_debt_created": 500000.00,
  "total_paid": 350000.00,
  "total_amount": 850000.00,
  "debt_count": 45
}
```

## Database Schema

The `sales` table already has the necessary columns:
- `total` - Total sale amount (quantity × price - discount)
- `paid` - Amount customer paid in cash
- `debt` - Outstanding balance (total - paid)

**Constraint:** `debt = total - paid` (enforced by database)

## Impact on Reports

### Sales Reports
- **Daily/Weekly/Monthly Sales Reports:** Now show cash received instead of total sales
- **Revenue figures:** Reflect actual money received, not promised amounts
- **Outstanding amounts:** Tracked separately in debt reports

### Debt Reports
- **New reports available:** Daily, weekly, and monthly debt summaries
- **Track:** Debt creation, payments received, and outstanding balances
- **Filter by:** Date ranges to analyze debt trends

## Migration Notes

- No database schema changes required
- Existing data remains intact
- Reports will automatically reflect new calculation method
- Mobile app may need updates to display new debt reports

## Testing Recommendations

1. **Test revenue calculations:**
   - Create a sale with partial payment
   - Verify revenue shows only paid amount
   - Verify debt shows outstanding balance

2. **Test debt reports:**
   - Access daily/weekly/monthly debt endpoints
   - Verify totals match expected values
   - Check date filtering works correctly

3. **Compare with old reports:**
   - Run reports for historical data
   - Verify numbers make sense
   - Document any discrepancies

## API Endpoints Summary

### Sales Reports (Updated)
- `GET /reports/daily?date=YYYY-MM-DD` - Shows cash received
- `GET /reports/weekly?week_start=YYYY-MM-DD` - Shows cash received
- `GET /reports/monthly?month=M&year=YYYY` - Shows cash received

### Debt Reports (New)
- `GET /reports/debts/daily?date=YYYY-MM-DD` - Daily debt summary
- `GET /reports/debts/weekly?week_start=YYYY-MM-DD` - Weekly debt summary
- `GET /reports/debts/monthly?month=M&year=YYYY` - Monthly debt summary

## Notes

- All endpoints require manager authentication
- Dates should be in ISO format (YYYY-MM-DD)
- Week starts on Monday by default
- All amounts are in the system's base currency
