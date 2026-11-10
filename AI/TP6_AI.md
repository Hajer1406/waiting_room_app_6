# 🤖 Utilisation de l'Intelligence Artificielle — TP6

Ce document décrit comment l'intelligence artificielle a été utilisée comme assistant de développement et pair-programmeur au cours du **Workshop 6 : Building a Resilient Single-Room Waiting Queue with Flutter and Supabase** sur l'application **Waiting Room**.

---

## 1. Informations sur l'Agent et l'Environnement

| Champ | Valeur |
| :--- | :--- |
| **Agent IA** | Antigravity (Google DeepMind) |
| **Modèles utilisés** | Gemini 3.8 Flash & Claude Sonnet 4.6 (Thinking) |
| **Environnement / IDE** | Antigravity IDE (Architecture VS Code) sur Windows 11 |
| **Projet** | `waiting_room_app` (Flutter 3.x / Dart) |
| **Backend** | Supabase (PostgreSQL, Auth anonyme, Realtime, RPC) |
| **Date de réalisation** | 10 novembre 2026 |

---

## 2. Objectifs du Workshop 6

Le Workshop 6 a pour but de consolider l'application de salle d'attente partagée unique (*Single-Room*) pour la rendre hautement résiliente, modulaire et prête pour la production à grande échelle :

1. **Intégration de la géolocalisation** : Récupération de la position GPS (`lat`, `lng`, `accuracy`), purement informative et n'empêchant jamais l'inscription en cas de refus.
2. **Surveillance réseau fine (Connectivité à double niveau)** : Distinction nette entre la présence d'une connexion réseau physique (Wi-Fi/Cellulaire) et la joignabilité effective des serveurs backend Supabase, avec debouncing de 700 ms.
3. **Persistance locale et gestion d'état de synchronisation** : Stockage embarqué SQLite (`LocalQueueStorage`) avec suivi strict du cycle de vie des enregistrements (`SyncStatus` : `pending`, `syncing`, `synced`, `failed`).
4. **Moteur de synchronisation transactionnel** : Synchronisation automatique des entrées locales en attente ou échouées lors du retour réseau, via une fonction PostgreSQL RPC (`register_queue_client`) avec clause `ON CONFLICT` anti-doublon.
5. **Gestion avancée des états de l'interface** : États explicites (`initial`, `loading`, `loaded`, `empty`, `refreshing`, `loadingMore`, `error`) avec widgets dédiés (`LoadingWidget`, `QueueEmptyWidget`, `OfflineBanner`).
6. **Optimisation par pagination et réconciliation temps réel** : Défilement infini paginé par tranches de 20 clients (`fetchPage`, `loadMore`) et déduplication des événements Supabase Realtime (`handleRealtimeInsert`).
7. **Stratégie de test TDD** : Application stricte du cycle Red → Green → Refactor sur l'ensemble des couches (modèles, stockage SQLite, services, providers et widgets UI).

---

## 3. Architecture en Couches Implémentée

L'application a été restructurée selon une architecture en couches claire et découplée :

```
lib/
├── main.dart                               # Initialisation Supabase, MultiProvider et injection de dépendances
├── models/
│   ├── client.dart                         # Modèle métier Client (lat, lng, accuracy, toSupabaseMap, toLocalMap)
│   ├── sync_status.dart                    # Enum SyncStatus (pending, syncing, synced, failed)
│   ├── app_connectivity.dart               # Enum AppConnectivity (checking, online, offline, backendUnavailable)
│   └── queue_state.dart                    # Enum QueueState (initial, loading, loaded, empty, error...)
├── providers/
│   ├── queue_provider.dart                 # Gestion d'état de la file, pagination, Realtime, FIFO queue
│   └── connectivity_provider.dart          # Surveillance réseau, debounce 700ms, ping Supabase
├── services/
│   ├── geolocation_service.dart            # Gestion GPS, permissions et tolérance aux refus
│   ├── connectivity_service.dart           # Détection réseau et ping applicatif Supabase
│   └── sync_service.dart                   # Moteur de synchronisation des enregistrements en attente
├── repositories/
│   └── queue_repository.dart               # Coordination Supabase (RPC/Upsert) et stockage local
├── storage/
│   └── local_queue_storage.dart            # Persistance SQLite locale avec fallback Web transparent
├── screens/
│   └── queue_screen.dart                   # Écran principal avec bannières, liste paginée et Next Client
└── widgets/
    ├── client_card.dart                    # Carte client avec coordonnées et icônes d'état GPS
    ├── offline_banner.dart                 # Bannière d'alerte dynamique selon l'état de connectivité
    ├── loading_widget.dart                 # Indicateur de chargement centralisé
    └── queue_empty_widget.dart             # Vue d'état vide
```

---

## 4. Résumé Chronologique des Discussions et Échanges avec Antigravity

### 4.1 Cadrage initial et implémentation du sujet
* **Demande de l'étudiant** : Soumission du cahier des charges complet du Workshop 6 (*« appliquer ce tp correctement sur mon projet en respectant la structure du projet donné »*).
* **Action d'Antigravity** :
  - Analyse de l'arborescence existante et du fichier `pubspec.yaml`.
  - Ajout des dépendances requises : `connectivity_plus` et `mocktail`.
  - Création des modèles (`client.dart`, `sync_status.dart`, `app_connectivity.dart`, `queue_state.dart`).
  - Implémentation des services (`GeolocationService`, `ConnectivityService`, `SyncService`).
  - Développement de la couche données (`LocalQueueStorage`, `QueueRepository`).
  - Refonte des providers et de l'interface utilisateur (`QueueScreen`, `ClientCard`, `OfflineBanner`, etc.).
  - Configuration des permissions dans `AndroidManifest.xml` et `Info.plist`.

### 4.2 Diagnostic de l'erreur Web « Failed to load queue » (Capture d'écran 1)
* **Constat de l'étudiant** : Partage d'une capture d'écran de l'application sur Chrome Web affichant l'erreur rouge centrée : `Failed to load queue` avec un bouton `Retry`.
* **Diagnostic technique de l'IA** :
  1. Le plugin `sqflite` ne supporte pas nativement l'exécution sur Chrome Web (`MissingPluginException` lors de l'appel à `getDatabasesPath()`).
  2. L'absence de gestion de ce cas dans `LocalQueueStorage` provoquait l'échec immédiat de la mise en cache locale et du fallback hors ligne lors du `fetchPage()`.
* **Solution apportée** :
  - Intégration d'un mécanisme de détection `kIsWeb` dans `LocalQueueStorage` avec un magasin mémoire de repli (*in-memory fallback*), garantissant une exécution fluide à la fois sur Web et sur plateformes natives (Android/Desktop).

### 4.3 Diagnostic de la base Supabase et des colonnes manquantes (Capture d'écran 2)
* **Constat de l'étudiant** : Partage d'un lien et d'une capture d'écran du **Table Editor** de Supabase (`clients`), montrant uniquement les colonnes `id`, `name` et `created_at`.
* **Diagnostic d'Antigravity via requêtes directes** :
  - Test de l'API Supabase via commande cURL : réponse PostgreSQL `PGRST204 : Could not find the 'lat' column of 'clients' in the schema cache`.
  - Confirmation que les instructions SQL des phases 1.2 et 4.2 n'avaient pas encore été exécutées dans la base de données distante.
* **Résolution** :
  - Fourniture du script SQL complet comprenant l'ajout des colonnes géographiques (`lat`, `lng`, `location_accuracy_m`, `location_captured_at`), les contraintes de validation `CHECK` de coordonnées, et la fonction PostgreSQL RPC sécurisée `register_queue_client`.

### 4.4 Validation visuelle du résultat final (Capture d'écran 3)
* **Action de l'étudiant** : Exécution du script SQL dans Supabase et rafraîchissement de l'application. Envoi d'une capture d'écran montrant l'application fonctionnelle avec 6 clients et demande : *« est ce que ça le resultat final ?? »*.
* **Validation par Antigravity** :
  - Confirmation du résultat final réussi :
    - Le client **"mohamed"** apparaît avec ses coordonnées réelles capturées : `Location available (36.4400, 10.6800)` et l'icône verte `location_on`.
    - Les autres clients affichent correctement `Location not captured` avec l'icône grise `location_off`.
    - Le compteur affiche `Clients: 6` et le bouton `Next Client` est fonctionnel selon l'ordre FIFO (First-In, First-Out).

### 4.5 Explication et guidage pour la Partie 7 (Testing & 3 cas de connectivité)
* **Question de l'étudiant** : *« pour Partie 7 comment le tester »* puis *« je veux tester ces 3 cas »*.
* **Explications fournies par Antigravity** :
  - Présentation de la double approche : tests automatisés TDD (`flutter test test/widgets/offline_banner_test.dart`) et manipulation manuelle dans les DevTools Chrome.
  - Démonstration guidée des 3 états du widget `OfflineBanner` :
    1. **`AppConnectivity.offline`** : Simulation *Offline* dans l'onglet Network de Chrome → affichage de la bannière rouge *"No network connection"*.
    2. **`AppConnectivity.online`** : Rétablissement du réseau → masquage automatique de la bannière.
    3. **`AppConnectivity.backendUnavailable`** : Simulation d'une URL Supabase erronée dans `.env` avec réseau actif → affichage de la bannière orange *"Waiting-room server unavailable"*.

### 4.6 Captures d'écran et Compte-Rendu d'Exécution
Les 6 captures d'écran ci-dessous illustrent les états de validation obtenus lors des tests réels :
- **Figure 1 — État `AppConnectivity.backendUnavailable` :** Affichage de la bannière orange *"Waiting-room server unavailable"* lorsque l'appareil est connecté à Internet mais que le serveur backend Supabase ne répond pas.
- **Figure 2 — État `AppConnectivity.checking` :** Affichage de la bannière bleue *"Checking connection..."* lors de l'initialisation ou de la phase transitoire de vérification de la disponibilité réseau et backend (debouncing de 700 ms).
- **Figure 3 — État `AppConnectivity.offline` :** Affichage de la bannière rouge *"No network connection"* dès la déconnexion réseau simulée via l'option *Offline* des Outils de développement Chrome.
- **Figure 4 — Résilience hors ligne et géolocalisation :** Interception des échecs réseau dans les DevTools avec persistance locale active et affichage des clients enregistrés avec leurs coordonnées GPS (repères verts `location_on`).
- **Figure 5 — Base de données Supabase (`clients`) :** Validation de la migration SQL affichant les colonnes de géolocalisation (`lat`, `lng`, `location_accuracy_m`) avec les positions réelles persistées pour les clients enregistrés.
- **Figure 6 — Validation des tests automatisés TDD :** Exécution réussie du test unitaire du widget `OfflineBanner` (3/3 tests passés) et validation de l'intégralité de la suite de tests du projet (45/45 tests passés au vert).

---

## 5. Synthèse des Problèmes et Solutions Techniques

| Problème / Anomalie rencontrée | Cause identifiée | Solution technique appliquée |
| :--- | :--- | :--- |
| **`UnsupportedOperation` / blocage Web sur SQLite** | `sqflite` non pris en charge nativement sur Chrome Web. | Ajout d'un fallback in-memory automatique sous condition `kIsWeb` dans `LocalQueueStorage`. |
| **Erreur Supabase `PGRST204` sur `lat`** | La table distante `clients` n'avait pas encore les colonnes de géolocalisation. | Exécution du script SQL `ALTER TABLE` et création des contraintes `CHECK`. |
| **Erreur Supabase `PGRST202` sur l'inscription** | Fonction RPC PostgreSQL non définie. | Création de la fonction PL/pgSQL `register_queue_client` avec gestion de conflit `ON CONFLICT (id) DO UPDATE`. |
| **Incohérence d'ordre de la file d'attente (LIFO vs FIFO)** | `addClient` insérait en tête de liste (`insert(0, client)`) au lieu de la fin. | Rétablissement de l'ordre FIFO strict (`_clients.add(newClient)`) pour respecter le modèle d'une salle d'attente. |
| **Rupture de compatibilité sur les anciens tests** | L'ancien constructeur `QueueProvider()` sans arguments était attendu par les tests des TP précédents. | Introduction de constructeurs nommés de rétro-compatibilité (`QueueProvider.withDependencies`) et adaptation des mocks. |

---

## 6. Couverture et Validation des Tests TDD (45/45 ✅)

La totalité de la suite de tests automatisés s'exécute avec succès (`All tests passed!`) :

```text
00:00 +0:  Client Model Tests (sérialisation Supabase & SQLite)
00:01 +4:  LocalQueueStorage Tests (CRUD, pending & failed retry filter)
00:03 +10: ConnectivityProvider Tests (détection réseau, transitions, debounce 700ms)
00:05 +16: QueueProvider Geolocation Tests (GPS capturé, refus toléré, fallback)
00:08 +30: SyncService Tests (synchronisation atomique, résilience aux erreurs)
00:10 +35: QueueProvider Workshop 6 Tests (pagination loadMore, déduplication Realtime)
00:14 +39: Widget Tests (WaitingRoomApp, OfflineBanner 3 états, interactions UI)
00:20 +45: All tests passed!
```

---

## 7. Rôle et Valeur Ajoutée de l'IA

Au cours de ce Workshop 6, l'agent Antigravity a joué un rôle d'**architecte logiciel, mentor en débogage et garant de la qualité** :
- **Architecture modulaire** : Structuration rigoureuse du code en couches bien délimitées (UI, Provider, Service, Repository, Storage).
- **Résolution instantanée d'anomalies de plateforme** : Identification rapide de l'incompatibilité de SQLite sur Chrome Web et mise en place d'un fallback transparent sans dégrader le code natif.
- **Support SQL & Cloud** : Rédaction des scripts d'évolution de schéma et de fonctions stockées PostgreSQL pour Supabase.
- **Accompagnement interactif** : Explications didactiques des concepts complexes (debouncing réseau, synchronisation différentielle, déduplication Realtime).
- **Excellence TDD** : Maintien et enrichissement de 45 tests unitaires et d'intégration validés sans régression.

---

> **Note d'intégrité académique** : L'IA a servi d'outil d'assistance méthodologique, de pair-programming et de conseil technique. L'exécution des requêtes sur le tableau de bord Supabase, les vérifications dans le navigateur Chrome et la validation des fonctionnalités métier ont été entièrement réalisées par l'étudiant.

