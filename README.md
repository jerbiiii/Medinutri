# 🏥 MediNutri IA — L'Assistant de Santé Intelligent

MediNutri est une application mobile **Flutter** de pointe qui fusionne l'intelligence artificielle, la nutrition personnalisée et la télémédecine. Conçue avec une approche "AI-First", elle offre une expérience utilisateur premium pour la gestion proactive de la santé.

---

## ✨ Fonctionnalités Clés

### 🤖 Docteur IA & Diagnostic
*   **Analyse de symptômes** : Un chat intelligent propulsé par **Llama 3** pour une pré-analyse rapide et bienveillante.
*   **Télémédecine Vocale Immersive** : Consultation vocale avec un avatar 3D synchronisé (lip-sync) pour un échange naturel et humain.

### 🥗 Nutrition Personnalisée (IA)
*   **Génération de plans 7 jours** : Création automatique de programmes nutritionnels basés sur la cuisine tunisienne (Bssissa, Couscous, etc.).
*   **Adaptation Intelligente** : Les plans s'ajustent selon l'IMC, le poids, les allergies et les objectifs de l'utilisateur.

### 💊 Gestion des Traitements
*   **Rappels Intelligents** : Système d'alarmes plein écran (Full-screen intent) pour ne plus jamais rater un médicament.
*   **Suivi de santé** : Tableau de bord en temps réel (Poids, IMC, Prochain repas).

### 📍 Services de Proximité
*   **Carte interactive** : Localisation instantanée des pharmacies et services d'urgence à proximité.

---

## 🛠 Stack Technique

*   **Frontend** : Flutter & Provider (Gestion d'état)
*   **Design System** : Thème Premium (Mode Sombre/Clair), Google Fonts (Outfit), Flutter Animate
*   **Backend** : Supabase (Authentification, Base de données temps réel, Storage)
*   **IA Engine** : Groq API (Modèles Llama 3.3 70B & 3.1 8B)
*   **Services** : Flutter TTS (Synthèse vocale), Speech To Text (Reconnaissance vocale)

---

## 🚀 Installation & Configuration

### 1. Prérequis
*   Flutter SDK (dernière version stable)
*   Un projet Supabase actif
*   Une clé API Groq

### 2. Configuration
Créez un fichier `.env` à la racine du projet :
```env
SUPABASE_URL=votre_url_supabase
SUPABASE_ANON_KEY=votre_cle_anonyme
GROQ_API_KEY=votre_cle_groq
```

### 3. Lancement
```bash
flutter pub get
flutter run
```

---

## 🛡️ Sécurité & Confidentialité
*   **Données chiffrées** : Toutes les communications avec Supabase sont sécurisées via HTTPS/SSL.
*   **Protection RLS** : La base de données utilise le *Row Level Security* pour garantir que seul l'utilisateur peut accéder à ses propres données de santé.

---

## 👨‍💻 Architecture du Projet
L'application suit une structure modulaire :
- `lib/screens` : Interfaces utilisateur réactives et animées.
- `lib/services` : Logique métier (Auth, Santé, Notifications, IA).
- `lib/models` : Modèles de données typés (Patient, Médicament, Plan Nutrition).
- `lib/widgets` : Composants UI réutilisables et widgets 3D.

---

## 📄 Licence
Ce projet est distribué sous licence MIT.
