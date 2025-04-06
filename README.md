# 💡 Idea Bank

**Idea Bank** is a mobile-first app for capturing, organizing, and evolving creative ideas — quickly, privately, and offline-first.

Built with Flutter and Supabase, it empowers users to jot down thoughts, startup concepts, or brainstorms with speed and structure — whether online or off.

---

## 🚀 MVP Features

- 📝 Create, edit, and delete ideas (title + description)
- 🏷 Tag and categorize ideas with custom labels
- 🔍 Search and filter ideas by keywords or tags
- 🎙 Voice-to-text input using device microphone
- 📡 Offline-first data storage using Drift (local SQL)
- ⚙️ User preferences: light/dark theme toggle
- 🔐 Per-user authentication and secure Supabase sync

---

## 🛠 Tech Stack

| Layer        | Technology         | Purpose                                   |
|--------------|--------------------|-------------------------------------------|
| Frontend     | Flutter             | Cross-platform UI (mobile-first + web)    |
| Local DB     | Drift (Moor)        | Offline-first idea and tag storage        |
| Preferences  | Hive                | Lightweight settings (theme, etc.)        |
| Voice Input  | speech_to_text      | On-device speech recognition              |
| Backend      | Supabase            | Auth, PostgreSQL, sync, hosting           |

---

<details>
    <summary>Click to expand</summary>
lib/
├── db/                  # Drift database setup and queries
│   └── idea_database.dart
│
├── models/              # Data models (Idea, Tag, etc.)
│
├── screens/             # UI screens (Login, Signup, Home, Edit, etc.)
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── reset_password_screen.dart
│   ├── home_screen.dart
│   └── edit_screen.dart
│
├── services/            # Business logic & integrations
│   ├── auth_service.dart       # Supabase auth wrapper
│   ├── supabase_service.dart   # Supabase client logic
│   ├── sync_service.dart       # Sync manager for cloud/local
│
├── state/               # Providers and state notifiers
│   ├── idea_provider.dart
│   ├── theme_notifier.dart
│
├── theme/               # Theme configuration (light/dark)
│   └── app_theme.dart
│
├── widgets/             # Reusable UI components (optional/future)
│
├── routes.dart          # Named route generator
└── main.dart            # App entry point, setup, and providers
</details>

---

## 🔐 Data Security

- ✅ Row-Level Security (RLS) enforced in Supabase
- ✅ All data is scoped to `user_id = auth.uid()`
- ✅ Voice transcription is handled **on-device only**

---

## 📱 Platform Support

- ✅ Android (stable)
- ✅ iOS (TestFlight-ready)
- ✅ Web (PWA via Supabase hosting)
- ❌ Desktop (experimental only)

---

## 🔮 Future Enhancements

- 🤖 AI: idea summarization, validation, market overlap
- 🧠 Peer feedback & collaborative review
- 📤 Export to PDF, Markdown, Notion
- 🧾 Idea templates: Lean Canvas, Business Model Canvas
- 💰 Pro tier with advanced features and monetization

---

## 🧪 Coming Soon

```text
🔧 Setup Instructions
📦 Dependencies & Versions
🔐 Supabase Project & Env Config
🌐 Deployment Guide (Web & Mobile)