# AI Tool Ecosystem for Smart Campus Management

College PBL project: an Android app (Flutter) with a Flask REST backend
that calls the Google Gemini API.

## Modules
- AI Campus Chatbot
- Academic Assistant (notes, summary, quiz, practice questions)
- Attendance Analyzer (calculated locally in the app)
- Career Guidance

## Structure
- `smart_campus_app/` - Flutter Android app
- `backend/` - Flask API (`/api/health`, `/api/chat`, `/api/academic`, `/api/career`)

## Run the backend locally
1. `cd backend`
2. `python -m venv venv` and activate it
3. `pip install -r requirements.txt`
4. Copy `.env.example` to `.env` and add your own Gemini API key
5. `python app.py`

The Gemini API key lives only in the backend environment. It is never part
of the Flutter app or this repository.