# AI Tool Ecosystem for Smart Campus Management

A college PBL project: a native Android app built with Flutter, backed by a Flask REST API that uses the Google Gemini API.

## Architecture

Flutter Android app -> (JSON over HTTPS) -> Flask API on Render -> Google Gemini API

- Mobile frontend: Flutter (Android)
- Backend: Python Flask, served with Gunicorn on Render
- AI: Google Gemini through the Google GenAI Python SDK
- The Gemini API key exists only as an environment variable on the backend. It is not in the app, the APK, or this repository.

## Modules

1. AI Campus Chatbot: answers general student questions. It does not invent college-specific fees, dates, exam schedules, faculty details, or policies.
2. Academic Assistant: generates notes, summaries, five-question MCQ quizzes with an answer key, and practice questions.
3. Attendance Analyzer: calculates attendance % = attended / total x 100 locally in the app. 75% or more is Satisfactory; below 75% shows a Low Attendance Warning.
4. Career Guidance: suggests three careers with reasons, missing skills, and a short learning roadmap, labelled as general AI-generated guidance.

## API

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | /api/health | Check that the server is running |
| POST | /api/chat | Campus chatbot |
| POST | /api/academic | Notes, summary, quiz, practice questions |
| POST | /api/career | Career guidance |

Success: {"success": true, "answer": "..."}
Failure: {"success": false, "error": "..."}

Live health check: https://android-smart-campus-management.onrender.com/api/health

The backend runs on the Render free tier, which sleeps after about 15 minutes of inactivity. The first request after that can take about a minute.

## Install the app

Download `SmartCampus-release.apk` from the Releases page of this repository and open it on an Android phone. Allow installation from unknown sources if asked. The app needs an internet connection.

The release APK is signed with the default Flutter debug key. It is meant for demonstration and is not prepared for Play Store publishing.

## Repository structure

- `smart_campus_app/` - Flutter Android app
- `backend/` - Flask API (app.py, requirements.txt, gunicorn.conf.py)
- `docs/TEST_CASES.md` - test-case summary

## Run the backend locally

1. cd backend
2. python -m venv venv, then activate it (Git Bash: source venv/Scripts/activate)
3. pip install -r requirements.txt
4. Copy .env.example to .env and add your own Gemini API key
5. python app.py

Render settings: Root Directory backend, Build Command `pip install -r requirements.txt`, Start Command `gunicorn app:app`, environment variables GEMINI_API_KEY, GEMINI_MODEL, GEMINI_FALLBACK_MODEL, PYTHON_VERSION.

## Build the app

1. cd smart_campus_app
2. flutter pub get
3. Set `kBaseUrl` in lib/services/api_service.dart to your backend URL
4. flutter run, or flutter build apk --release

## Testing

See docs/TEST_CASES.md.

## Limitations

- Answers come from a general AI model and can contain mistakes. They are not official college information.
- The free hosting tier has cold starts, and the free Gemini tier has usage limits and occasional busy periods. The backend retries and falls back to a second model automatically.
- There is no login, so there is no per-student data.

## Future Scope

- Login and authentication
- Multiple user roles (student, faculty, admin)
- A database (SQLite or MySQL) for stored records
- Resource booking
- Student-performance prediction
- Feedback analysis
- Event registration
- Machine-learning model training on campus data
- Support for multiple AI providers
- Google Play Store publishing
- Advanced state management in the app
