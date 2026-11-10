# 🤖 Répertoire AI — Documentation de l'Assistance par Intelligence Artificielle

Ce répertoire regroupe la documentation relative à l'utilisation de l'intelligence artificielle comme assistant de développement au cours des différents travaux pratiques de l'application **Waiting Room**.

---

## 📌 Vue d'ensemble des sessions d'assistance IA

| Travail Pratique | Sujet abordé | Agent IA | Modèle(s) | Date(s) | Fiche Markdown | Document Word (.docx) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Workshop 3** | Gestion d'état scalable avec Provider & TDD | Antigravity (Google DeepMind) | Gemini Flash → Claude Sonnet 4.6 | 06/10/2026 | [TP3_AI.md](file:///c:/Users/user/waiting_room_app/AI/TP3_AI.md) | [TP3_AI.docx](file:///c:/Users/user/waiting_room_app/AI/TP3_AI.docx) |
| **Workshop 4** | Synchronisation temps réel avec Supabase | Antigravity (Google DeepMind) | Gemini 3.8 Flash (High) | 15-16/10/2026 | [TP4_AI.md](file:///c:/Users/user/waiting_room_app/AI/TP4_AI.md) | [TP4_AI.docx](file:///c:/Users/user/waiting_room_app/AI/TP4_AI.docx) |
| **Workshop 5** | Architecture Offline-First & Géolocalisation GPS | Antigravity (Google DeepMind) | Claude Sonnet 4.6 & Gemini 3.8 Flash | 31/10/2026 | [TP5_AI.md](file:///c:/Users/user/waiting_room_app/AI/TP5_AI.md) | [TP5_AI_Complet.docx](file:///c:/Users/user/waiting_room_app/AI/TP5_AI_Complet.docx) |
| **Workshop 6** | File d'attente résiliente, Offline, Sync & Pagination | Antigravity (Google DeepMind) | Gemini 3.8 Flash & Claude Sonnet 4.6 (Thinking) | 10/11/2026 | [TP6_AI.md](file:///c:/Users/user/waiting_room_app/AI/TP6_AI.md) | [TP6_AI.docx](file:///c:/Users/user/waiting_room_app/AI/TP6_AI.docx) |

---

## 📂 Contenu du dossier `AI/`

1. **Documents pour le Workshop 3** :
   - Markdown : [**`AI/TP3_AI.md`**](file:///c:/Users/user/waiting_room_app/AI/TP3_AI.md)
   - Fichier Word : [**`AI/TP3_AI.docx`**](file:///c:/Users/user/waiting_room_app/AI/TP3_AI.docx)
   - *Contenu* : Présentation de l'agent, concepts de `ChangeNotifier` et `Provider`, cycle TDD (Red/Green/Refactor), résolution des erreurs de syntaxe et tests de widgets.

2. **Documents pour le Workshop 4** :
   - Markdown : [**`AI/TP4_AI.md`**](file:///c:/Users/user/waiting_room_app/AI/TP4_AI.md)
   - Fichier Word : [**`AI/TP4_AI.docx`**](file:///c:/Users/user/waiting_room_app/AI/TP4_AI.docx)
   - *Contenu* : Présentation de l'agent, intégration de Supabase, modèle `Client`, diagnostic et déblocage de l'erreur PostgreSQL RLS `code: 42501 Unauthorized`, optimisation non-bloquante du démarrage web, validation des 16 tests automatisés.

3. **Documents pour le Workshop 5** :
   - Markdown : [**`AI/TP5_AI.md`**](file:///c:/Users/user/waiting_room_app/AI/TP5_AI.md)
   - Fichier Word complet : [**`AI/TP5_AI_Complet.docx`**](file:///c:/Users/user/waiting_room_app/AI/TP5_AI_Complet.docx)
   - *Contenu* : Résumé chronologique détaillé des discussions avec Antigravity, persistance locale SQLite (`sqflite`), synchronisation Supabase en arrière-plan, service de géolocalisation (`geolocator`), gestion multiplateforme (Android, Windows, Chrome Web), résolution des blocages (liens symboliques Windows, timeout GPS, suppression réseau Supabase) et 10 tests TDD unitaires passés à 100%.

4. **Documents pour le Workshop 6** :
   - Markdown : [**`AI/TP6_AI.md`**](file:///c:/Users/user/waiting_room_app/AI/TP6_AI.md)
   - Fichier Word complet : [**`AI/TP6_AI.docx`**](file:///c:/Users/user/waiting_room_app/AI/TP6_AI.docx)
   - *Contenu* : Architecture en couches complète (UI, Providers, Services, Repository, Storage), distinction réseau/backend avec debouncing de 700ms (`ConnectivityProvider`), persistance SQLite et gestion d'état (`SyncStatus`), moteur de synchronisation asynchrone (`SyncService`), fonction RPC PostgreSQL Supabase `register_queue_client`, résolution de l'incompatibilité `sqflite` sur Chrome Web via fallback mémoire transparent, maintien de l'ordre FIFO de la file d'attente, réconciliation temps réel Supabase sans doublons et validation à 100% des 45 tests TDD automatisés.

---

## 🛡️ Note d'intégrité et posture pédagogique

L'intelligence artificielle a été utilisée comme un **accélérateur d'apprentissage et un outil de pair-programming**. Elle a permis d'obtenir des explications conceptuelles détaillées, de diagnostiquer rapidement des erreurs cryptiques (comme le blocage de sécurité PostgreSQL RLS ou les particularités du Web sous Flutter) et d'assurer une couverture de tests rigoureuse. L'étudiant a conservé la pleine maîtrise de l'architecture, de l'exécution des commandes dans son environnement et de l'administration de ses services cloud.
