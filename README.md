# SPESHO Products Management System

Grain Stock & Sales Management System — Android Application

## Tech Stack
| Layer | Technology |
|---|---|
| Mobile | Flutter (Dart) — Clean Architecture |
| Backend | Python Flask REST API |
| Auth | JWT Token-Based |
| Database | PostgreSQL |
| Reports | ReportLab (PDF) |

---

## Project Structure

```
spesho/
├── backend/                  # Flask REST API
│   ├── app/
│   │   ├── models/           # SQLAlchemy models
│   │   ├── routes/           # API blueprints
│   │   ├── middleware/       # JWT auth decorators
│   │   └── utils/            # PDF generator
│   ├── migrations/
│   │   └── init.sql          # DB schema + indexes + stored procedures
│   ├── requirements.txt
│   ├── .env.example
│   └── run.py
└── mobile/spesho_app/        # Flutter Android App
    └── lib/
        ├── core/             # Constants, theme, networking
        ├── data/             # Models, repositories, datasources
        └── presentation/     # Providers (state) + Screens + Widgets
```

---

## Backend Setup

### 1. PostgreSQL
```bash
createdb spesho_db
psql -d spesho_db -f backend/migrations/init.sql
```

### 2. Python environment
```bash
cd backend
python -m venv venv
# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

pip install -r requirements.txt
```

### 3. Configure .env
```bash
cp .env.example .env
# Edit .env with your DB credentials and secret keys
```

### 4. Run migrations & seed
```bash
flask db init
flask db migrate -m "initial"
flask db upgrade
flask seed          # Creates admin/admin123 manager account
```

### 5. Start API server
```bash
python run.py
# API runs on http://localhost:5000
```

---

## API Endpoints

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| POST | /api/auth/login | — | Login |
| GET | /api/auth/me | Any | Current user |
| GET | /api/products/ | Any | List products |
| POST | /api/products/ | Manager | Create product |
| PUT | /api/products/:id | Manager | Update product |
| DELETE | /api/products/:id | Manager | Delete product |
| POST | /api/stock/in | Manager | Record stock in |
| GET | /api/stock/balance | Any | Stock balances |
| GET | /api/stock/movements | Any | Movement history |
| POST | /api/sales/ | Any | Record sale |
| GET | /api/sales/ | Any | List sales |
| GET | /api/dashboard/ | Manager | Dashboard data |
| GET | /api/reports/daily | Manager | Daily report |
| GET | /api/reports/monthly | Manager | Monthly report |
| GET | /api/reports/daily/pdf | Manager | Daily PDF |
| GET | /api/reports/monthly/pdf | Manager | Monthly PDF |
| GET | /api/reports/stock-movement/pdf | Manager | Stock PDF |
| GET | /api/reports/stock-balance/pdf | Manager | Balance PDF |
| GET | /api/users/ | Manager | List users |
| POST | /api/users/ | Manager | Create user |
| PUT | /api/users/:id | Manager | Update user |

---

## Flutter App Setup

### Requirements
- Flutter SDK >= 3.3.0
- Android Studio / VS Code
- Android device or emulator (API 21+)

### 1. Configure API URL
Edit [lib/core/constants/app_constants.dart](mobile/spesho_app/lib/core/constants/app_constants.dart):
```dart
static const String baseUrl = 'http://10.0.2.2:5000/api';  // Android emulator
// OR
static const String baseUrl = 'http://YOUR_LOCAL_IP:5000/api';  // Real device
```

### 2. Install dependencies
```bash
cd mobile/spesho_app
flutter pub get
```

### 3. Run
```bash
flutter run
```

### 4. Build APK
```bash
flutter build apk --release
```

---

## Default Login
| Username | Password | Role |
|---|---|---|
| admin | admin123 | Manager |

---

## Features

### Manager
- Dashboard with sales stats + bar chart
- Product management (add/edit/delete)
- Stock In recording
- Stock balance viewer
- Sales recording
- Sales history
- Reports: Daily, Monthly, Stock Movement, Stock Balance
- PDF export for all reports
- User management (add/edit salesperson accounts)

### Sales Person
- Record new sales (with stock validation)
- View available stock levels
- View own sales history

### Business Rules
- Stock balance = Total Stock In − Total Stock Out
- System prevents sale if stock is insufficient
- Sales person cannot delete records
- Sales person cannot access financial dashboard or reports

---

## Database Schema

```sql
users           → id, username, password_hash, role, full_name, is_active
products        → id, name, unit_price, is_active
stock_movements → id, product_id*, quantity_in, quantity_out, date*, movement_type
sales           → id, product_id*, quantity, price, discount, total, sold_by*, date*

* = indexed for performance
```
