# Deployment Guide

## Backend Deployment

### Option 1: Heroku (Recommended for Free)

#### Prerequisites
- Heroku account (free tier available)
- Heroku CLI installed

#### Steps

1. **Create Heroku App**
```bash
cd backend
heroku create expense-tracker-backend
```

2. **Set Environment Variables**
```bash
heroku config:set OPENROUTER_API_KEY=your_key_here
heroku config:set NODE_ENV=production
```

3. **Deploy**
```bash
git push heroku main
```

4. **Verify**
```bash
heroku logs --tail
curl https://expense-tracker-backend.herokuapp.com/health
```

---

### Option 2: Railway.app

1. Connect GitHub repo
2. Add environment variables
3. Deploy automatically

---

### Option 3: DigitalOcean App Platform

1. Connect GitHub
2. Set environment variables
3. Deploy

---

### Option 4: Self-Hosted (VPS)

#### Prerequisites
- VPS with Node.js installed
- Domain name (optional)
- SSL certificate (recommended)

#### Steps

1. **SSH into VPS**
```bash
ssh root@your_vps_ip
```

2. **Clone Repository**
```bash
git clone <your_repo> /var/www/expense-tracker
cd /var/www/expense-tracker/backend
```

3. **Install Dependencies**
```bash
npm install --production
```

4. **Create .env**
```bash
cat > .env << EOF
OPENROUTER_API_KEY=your_key_here
PORT=3000
NODE_ENV=production
EOF
```

5. **Setup PM2 (Process Manager)**
```bash
npm install -g pm2
pm2 start server.js --name "expense-tracker"
pm2 startup
pm2 save
```

6. **Setup Nginx Reverse Proxy**
```bash
sudo apt-get install nginx
```

Create `/etc/nginx/sites-available/expense-tracker`:
```nginx
server {
    listen 80;
    server_name your_domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Enable site:
```bash
sudo ln -s /etc/nginx/sites-available/expense-tracker /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

7. **Setup SSL (Let's Encrypt)**
```bash
sudo apt-get install certbot python3-certbot-nginx
sudo certbot --nginx -d your_domain.com
```

---

## Flutter App Deployment

### Android

#### Prerequisites
- Android Studio
- Keystore file (for signing)

#### Build APK
```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-app/release/app-release.apk`

#### Build App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

#### Upload to Google Play Store
1. Create Google Play Developer account ($25 one-time)
2. Create app listing
3. Upload AAB file
4. Fill in store listing details
5. Submit for review

---

### iOS

#### Prerequisites
- Mac with Xcode
- Apple Developer account ($99/year)
- Provisioning profiles

#### Build IPA
```bash
flutter build ipa --release
```

#### Upload to App Store
1. Create App Store Connect account
2. Create app listing
3. Upload IPA using Transporter
4. Fill in app details
5. Submit for review

---

## Update Backend URL in Flutter

Before deploying, update the backend URL in `lib/services/api_service.dart`:

```dart
// Development
final String baseUrl = 'http://localhost:3000';

// Production
final String baseUrl = 'https://your-backend-domain.com';
```

---

## Environment-Specific Configuration

Create different configurations for dev/prod:

### `lib/config/app_config.dart`

```dart
class AppConfig {
  static const String devBackendUrl = 'http://localhost:3000';
  static const String prodBackendUrl = 'https://api.expensetracker.com';
  
  static String getBackendUrl() {
    const String env = String.fromEnvironment('FLUTTER_APP_ENV', defaultValue: 'dev');
    return env == 'prod' ? prodBackendUrl : devBackendUrl;
  }
}
```

Build with environment:
```bash
flutter run --dart-define=FLUTTER_APP_ENV=prod
flutter build apk --dart-define=FLUTTER_APP_ENV=prod --release
```

---

## Database Migration

### Backup SQLite Database

```dart
Future<void> backupDatabase() async {
  final dbPath = await getDatabasePath();
  final backup = File('${dbPath}_backup.db');
  await File(dbPath).copy(backup.path);
}
```

### Schema Updates

If you need to update the database schema:

1. Update `lib/database/database.dart`
2. Increment `schemaVersion`
3. Add migration logic in `onUpgrade`

```dart
@override
int get schemaVersion => 2;

@override
MigrationStrategy get migration => MigrationStrategy(
  onUpgrade: (m, from, to) async {
    if (from < 2) {
      // Add new column
      await m.addColumn(expenses, expenses.receiptImage);
    }
  },
);
```

---

## Monitoring

### Backend Monitoring

```bash
# Check logs
heroku logs --tail

# Monitor performance
pm2 monit

# Check uptime
curl -I https://your-backend-domain.com/health
```

### Error Tracking

Add Sentry for error tracking:

```bash
npm install @sentry/node
```

```javascript
import * as Sentry from "@sentry/node";

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,
});
```

---

## Performance Optimization

### Backend

1. **Enable Compression**
```javascript
import compression from 'compression';
app.use(compression());
```

2. **Rate Limiting**
```javascript
import rateLimit from 'express-rate-limit';

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100
});

app.use('/analyze', limiter);
```

3. **Caching**
```javascript
app.set('view cache', true);
```

### Flutter

1. **Lazy Loading**
- Load data only when needed
- Use `FutureProvider.family` for pagination

2. **Image Optimization**
- Compress images before upload
- Use appropriate image sizes

3. **Database Optimization**
- Create indexes on frequently queried columns
- Use pagination for large lists

---

## Security Checklist

- [ ] API key not exposed in code
- [ ] HTTPS enabled for backend
- [ ] CORS properly configured
- [ ] Input validation on backend
- [ ] Rate limiting enabled
- [ ] Error messages don't leak sensitive info
- [ ] Database backups configured
- [ ] Logs don't contain sensitive data

---

## Rollback Plan

### Backend Rollback
```bash
# Heroku
heroku releases
heroku rollback v123

# Self-hosted
git revert <commit_hash>
pm2 restart expense-tracker
```

### Flutter Rollback
- Remove new version from app store
- Previous version remains available
- Users can downgrade if needed

---

## Versioning

### Backend
```json
{
  "version": "1.0.0"
}
```

Increment:
- Major: Breaking changes
- Minor: New features
- Patch: Bug fixes

### Flutter
Update in `pubspec.yaml`:
```yaml
version: 1.0.0+1
```

Format: `major.minor.patch+buildNumber`

---

## CI/CD Pipeline

### GitHub Actions

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: akhileshns/heroku-deploy@v3.12.12
        with:
          heroku_api_key: ${{secrets.HEROKU_API_KEY}}
          heroku_app_name: "expense-tracker-backend"
          heroku_email: ${{secrets.HEROKU_EMAIL}}
          appdir: "backend"

  build-flutter:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build apk --release
      - uses: actions/upload-artifact@v2
        with:
          name: app-release.apk
          path: build/app/outputs/flutter-app/release/app-release.apk
```

---

## Post-Deployment Checklist

- [ ] Backend health check passes
- [ ] API endpoints responding
- [ ] Database connected
- [ ] OpenRouter API working
- [ ] Flutter app connects to backend
- [ ] Add expense works
- [ ] AI assistant responds
- [ ] No errors in logs
- [ ] Performance acceptable
- [ ] Monitoring configured

---

## Support & Troubleshooting

### Backend Issues
- Check logs: `heroku logs --tail`
- Verify environment variables
- Test API with curl
- Check OpenRouter API status

### Flutter Issues
- Check network connectivity
- Verify backend URL
- Check app logs: `flutter run -v`
- Test on different devices

---

## Costs

### Free Tier
- Heroku: $0 (with limitations)
- OpenRouter: Free tier available
- Firebase: Free tier available

### Paid Options
- Heroku: $7+/month
- DigitalOcean: $5+/month
- AWS: Variable pricing
- Google Play Store: $25 one-time
- App Store: $99/year

---

## Next Steps

1. Deploy backend
2. Update Flutter app with production URL
3. Build and deploy Flutter app
4. Monitor performance
5. Gather user feedback
6. Plan improvements

---

**Deployment successful! 🎉**
