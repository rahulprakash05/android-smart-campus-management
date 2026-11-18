# Gunicorn loads this file automatically from the folder it starts in,
# so the Render start command can stay exactly: gunicorn app:app
workers = 1
threads = 4
timeout = 120  # Gemini answers can take longer than Gunicorn's 30 s default