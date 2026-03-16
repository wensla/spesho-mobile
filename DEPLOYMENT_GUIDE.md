# Spesho Deployment Guide

## Backend Deployment (Render.com)

### Prerequisites
- GitHub account
- Render.com account
- PostgreSQL database (Render provides free tier)

### Steps:

#### 1. Push Code to GitHub
```bash
cd spesho/backend
git init
git add .
git commit -m "Add paid/debt tracking feature"
git remote add origin https://github.com/YOUR_USERNAME/spesho-backend.git
git push -u origin main
```

#### 2. Deploy on Render.com

1. **Login to Render**: https://render.com
2. **Create New PostgreSQL Database**:
   - Click "New +" → "PostgreSQL"
   - Name: `spesho-db`
   - Plan: Free
   - Click "Create Database"
   - **Save the connection string** (Internal Database URL)

3. **Create Web Service**:
   - Click "New +" → "Web Service"
   - Connect your GitHub repository
   - Settings:
     - Name: `spesho-api`
     - Runtime: Python 3
     - Build Command: `pip install -r requirements.txt`
     - Start Command: `gunicorn run:app --bind 0.0.0.0:$PORT --workers 2 --timeout 120`
   
4. **Environment Variables**:
   Add these in Render dashboard:
   ```
   FLASK_ENV=production
   SECRET_KEY=<auto-generate>
   JWT_SECRET_KEY=<auto-generate>
   DATABASE_URL=<paste your PostgreSQL connection string>
   JWT_ACCESS_TOKEN_EXPIRES=86400
   ```

5. **Deploy**: Click "Create Web Service"

#### 3. Run Database Migration

After deployment, connect to your database and run:

```bash
# Option 1: Using Render Shell
# Go to your database → Connect → External Connection
psql -h <hostname> -U <username> -d <database> -f migrations/add_paid_debt_to_sales.sql

# Option 2: Using Render Dashboard
# Go to database → Query → Paste contents of add_paid_debt_to_sales.sql
```

#### 4. Test API
```bash
# Your API will be at: https://spesho-backend.onrender.com
curl https://spesho-backend.onrender.com/health
```

---

## Frontend Deployment (Flutter Web)

### Build Flutter Web App
```bash
cd spesho/mobile/spesho_app
flutter build web --release
```

### Deploy to Netlify/Vercel

#### Option A: Netlify
1. Install Netlify CLI:
   ```bash
   npm install -g netlify-cli
   ```

2. Deploy:
   ```bash
   cd build/web
   netlify deploy --prod
   ```

#### Option B: Vercel
1. Install Vercel CLI:
   ```bash
   npm install -g vercel
   ```

2. Deploy:
   ```bash
   cd build/web
   vercel --prod
   ```

### Update API URL in Flutter
Before building, update the API base URL in:
```dart
// lib/core/network/api_client.dart
static const String baseUrl = 'https://spesho-backend.onrender.com';
```

---

## Mobile App Deployment (Android)

### Build APK
```bash
cd spesho/mobile/spesho_app
flutter build apk --release
```

The APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

### Distribute
- **Google Play Store**: Follow [official guide](https://docs.flutter.dev/deployment/android)
- **Direct Distribution**: Share the APK file directly

---

## Post-Deployment Checklist

- [ ] Backend API is accessible
- [ ] Database migration applied successfully
- [ ] Test sale with partial payment (e.g., 50,000 total, 40,000 paid)
- [ ] Verify debt (10,000) is recorded correctly
- [ ] Frontend connects to backend API
- [ ] Mobile app connects to backend API
- [ ] Create admin user: `flask seed` (if needed)

---

## Troubleshooting

### Backend Issues
- **500 Error**: Check Render logs
- **Database Connection**: Verify DATABASE_URL
- **Migration Failed**: Run migration manually via psql

### Frontend Issues
- **CORS Error**: Add your frontend domain to backend CORS settings
- **API Not Found**: Check API base URL in Flutter code

---

## Quick Deploy Commands

```bash
# Backend
cd spesho/backend
git add .
git commit -m "Update"
git push origin main
# Render auto-deploys on push

# Frontend Web
cd spesho/mobile/spesho_app
flutter build web --release
cd build/web
netlify deploy --prod

# Mobile APK
flutter build apk --release
```

---

## Support
For issues, check:
- Backend logs: Render Dashboard → spesho-api → Logs
- Database: Render Dashboard → spesho-db → Query
- Flutter errors: Run `flutter doctor`
