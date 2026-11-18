# Test-Case Summary

Project: AI Tool Ecosystem for Smart Campus Management

- Build tested: release APK v1.0.0 (46.9 MB), installed with the USB cable disconnected
- Device: CPH2413, Android 15 (physical phone)
- Backend: Flask on Render (free tier, HTTPS), Gemini through the backend
- Test date: 2026-11-19

| ID | Module | Test | Input | Expected result | Result |
|----|--------|------|-------|-----------------|--------|
| TC-01 | App | Launch the installed APK without a cable | Open Smart Campus from the app drawer | Home dashboard with four module cards | Pass |
| TC-02 | Chatbot | General question | Explain artificial intelligence in simple words. | Simple plain-text explanation | Pass |
| TC-03 | Chatbot | Empty input | Blank question | Validation message, no request sent | Pass |
| TC-04 | Chatbot | College-specific question | What are the hostel fees at my college? | States it has no such information and points to the college office or portal | Pass |
| TC-05 | Academic Assistant | Five-question quiz | Machine Learning, Quiz | 5 MCQs, choices A to D, answer key | Pass |
| TC-06 | Academic Assistant | Notes, summary, practice questions | Machine Learning | Content generated for each mode | Pass |
| TC-07 | Academic Assistant | Empty topic | Blank topic | Validation message | Pass |
| TC-08 | Attendance Analyzer | Low attendance | 68 attended of 100 | 68% and Low Attendance Warning | Pass |
| TC-09 | Attendance Analyzer | Boundary value | 75 attended of 100 | 75% and Satisfactory | Pass |
| TC-10 | Attendance Analyzer | Invalid input | 120 attended of 100 | Error message, no result shown | Pass |
| TC-11 | Career Guidance | Demo case | Skills: Python, SQL, statistics. Interests: data and problem solving | Three careers with reasons, missing skills, roadmap, and a general-guidance label | Pass |
| TC-12 | Career Guidance | Empty fields | Both fields blank | Validation messages | Pass |
| TC-13 | Network | Mobile data only | Wi-Fi off, ask the chatbot | Answer received through Render | Pass |
| TC-14 | Network | No connection | Airplane mode, send a question | Friendly error message with a Retry button | Pass |
| TC-15 | Network | Retry | Airplane mode off, tap Retry | Answer received | Pass |
| TC-16 | Security | API key not in the APK | Binary scan of the release APK | Key not found | Pass |
| TC-17 | Security | API key not in the repository | Search of all tracked files | Key not found | Pass |

Notes:
- The first request after a period of inactivity can take about a minute, because the free Render instance sleeps and has to wake up.
- Attendance is calculated locally in the Flutter app.
