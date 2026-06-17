# DevPulse — Commandes

## Backend (FastAPI)

```bash
# Installer les dépendances
cd backend
pip install -r requirements.txt

# Peupler la base de données
python seed.py

# Lancer le serveur
uvicorn main:app --reload

# Accéder à la documentation interactive
# http://localhost:8000/docs
```

## Backoffice (React)

```bash
cd backoffice

# Installer les dépendances
npm install

# Lancer en développement
npm run dev

# Build production
npm run build

# Linter
npm run lint
```

## Application mobile (Flutter)

```bash
cd devpulse

# Installer les dépendances
flutter pub get

# Lancer sur un appareil/émulateur
flutter run

# Lancer en mode web
flutter run -d chrome

# Lancer les tests
flutter test

# Analyser le code
flutter analyze

# Build Android
flutter build apk

# Build iOS
flutter build ios

# Build web
flutter build web
```

## Base de données (Neon/PostgreSQL)

```bash
# Connexion directe (utiliser l'URL dans .env)
psql "postgresql://neondb_owner:npg_bXquB9skcJ4L@ep-mute-field-apuhqssx-pooler.c-7.us-east-1.aws.neon.tech/neondb?sslmode=require"

# Seed (re-créer les tables + données)
cd backend && python seed.py
```

## Credentials de test

| Rôle | Email | Mot de passe |
|------|-------|-------------|
| Admin | admin@devpulse.io | devpulse2024 |
| User | dev@pulse.io | password123 |
| Backoffice | admin | devpulse2024 |
