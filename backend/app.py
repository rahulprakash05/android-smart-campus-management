import logging
import os
import time

from dotenv import load_dotenv
from flask import Flask, jsonify, request
from flask_cors import CORS
from google import genai
from google.genai import errors, types
from werkzeug.exceptions import HTTPException

load_dotenv()

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger("smart_campus")

app = Flask(__name__)
CORS(app)

GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")
GEMINI_MODEL = os.environ.get("GEMINI_MODEL", "gemini-3.5-flash")
GEMINI_FALLBACK_MODEL = os.environ.get("GEMINI_FALLBACK_MODEL", "gemini-3.1-flash-lite")
RETRYABLE_CODES = {429, 500, 503}

client = None
if GEMINI_API_KEY:
    client = genai.Client(
        api_key=GEMINI_API_KEY,
        http_options=types.HttpOptions(timeout=55000),  # 55 seconds, in milliseconds
    )
else:
    logger.warning("GEMINI_API_KEY is not set. AI endpoints will return an error.")

PLAIN_TEXT_RULE = (
    "Write in plain text only. Do not use Markdown symbols such as asterisks, "
    "hash signs, or backticks. Use short paragraphs, numbered lines, or hyphens."
)

CHAT_SYSTEM = (
    "You are a friendly assistant for college students. Answer in simple, clear words "
    "and keep answers short, ideally under 200 words. You do NOT know any specific "
    "college's fees, dates, examination schedules, timetables, faculty details, or "
    "policies. Never invent them. If asked about such things, say you do not have that "
    "information and suggest checking the college office, notice board, or official "
    "portal. " + PLAIN_TEXT_RULE
)

ACADEMIC_SYSTEM = (
    "You are an academic assistant for college students. Be accurate and clear. "
    "If you are not sure about a fact, say so rather than guessing. " + PLAIN_TEXT_RULE
)

CAREER_SYSTEM = (
    "You are a career guidance assistant for college students. Give practical, "
    "honest, general guidance. Do not promise jobs, salaries, or outcomes. "
    + PLAIN_TEXT_RULE
)

MODE_PROMPTS = {
    "notes": (
        "Write clear, well-organised study notes on the topic: {topic}. Include key "
        "definitions, the main points, and one simple example. Keep it under 350 words."
    ),
    "summary": (
        "Write a concise summary of the topic: {topic} in about 150 words, followed by "
        "5 key takeaways."
    ),
    "quiz": (
        "Create exactly 5 multiple-choice questions on the topic: {topic}. Each question "
        "must have exactly four choices labelled A, B, C and D, with only one correct "
        "choice. After all five questions, add a section titled Answer Key that lists "
        "the correct letter for each question with a one-line explanation."
    ),
    "practice": (
        "Create 6 practice questions on the topic: {topic}. Mix short-answer and "
        "descriptive questions. Do not give the answers."
    ),
}

CAREER_PROMPT = (
    "A student has these skills: {skills}\n"
    "And these interests: {interests}\n\n"
    "Suggest exactly three suitable career options. For each career give:\n"
    "1. Career title\n"
    "2. Why it suits this student\n"
    "3. Missing skills the student should build\n"
    "4. A short learning roadmap of 3 to 4 steps\n"
    "Keep the whole answer under 450 words."
)

CAREER_DISCLAIMER = (
    "\n\nNote: This is general AI-generated guidance, not professional career "
    "counselling. Please verify details with a qualified advisor."
)


def success(answer):
    return jsonify({"success": True, "answer": answer}), 200


def failure(message, status=400):
    return jsonify({"success": False, "error": message}), status


def get_body():
    data = request.get_json(silent=True)
    return data if isinstance(data, dict) else {}


def ask_gemini(system_instruction, prompt):
    if client is None:
        raise RuntimeError("GEMINI_API_KEY is not configured on the server.")

    # Try the main model twice, then the fallback model once.
    models_to_try = [GEMINI_MODEL, GEMINI_MODEL, GEMINI_FALLBACK_MODEL]

    for attempt, model in enumerate(models_to_try):
        try:
            response = client.models.generate_content(
                model=model,
                contents=prompt,
                config=types.GenerateContentConfig(
                    system_instruction=system_instruction,
                    temperature=0.5,
                ),
            )
            text = (response.text or "").strip()
            if not text:
                raise ValueError("Gemini returned an empty response.")
            return text
        except errors.APIError as e:
            code = getattr(e, "code", None)
            is_last = attempt == len(models_to_try) - 1
            if code in RETRYABLE_CODES and not is_last:
                logger.warning(
                    "Gemini %s on model %s (attempt %d). Retrying...", code, model, attempt + 1
                )
                time.sleep(1.5)
                continue
            raise


def run_ai(system_instruction, prompt, suffix=""):
    try:
        answer = ask_gemini(system_instruction, prompt)
        return success(answer + suffix)
    except errors.APIError as e:
        logger.error("Gemini API error (code %s): %s", getattr(e, "code", "?"), e)
        code = getattr(e, "code", None)
        if code == 429:
            return failure(
                "The AI service is busy or the usage limit was reached. "
                "Please wait a minute and try again.",
                429,
            )
        if code == 503:
            return failure(
                "The AI service is very busy right now. Please wait a few seconds and tap Retry.",
                503,
            )
        if code in (401, 403):
            return failure("The AI service is not set up correctly. Please contact the developer.", 502)
        if code == 404:
            return failure("The AI model is unavailable. Please contact the developer.", 502)
        return failure("The AI service could not process your request. Please try again.", 502)
    except RuntimeError as e:
        logger.error("Configuration error: %s", e)
        return failure("The AI service is not configured on the server.", 500)
    except Exception as e:
        logger.exception("Unexpected error while calling Gemini")
        if "timeout" in type(e).__name__.lower() or "timed out" in str(e).lower():
            return failure("The AI took too long to respond. Please try again.", 504)
        return failure("Something went wrong while generating the answer. Please try again.", 500)


@app.route("/api/health", methods=["GET"])
def health():
    return success("Smart Campus API is running.")


@app.route("/api/chat", methods=["POST"])
def chat():
    data = get_body()
    question = str(data.get("question", "")).strip()
    if not question:
        return failure("Please enter a question.")
    if len(question) > 1000:
        return failure("Your question is too long. Please keep it under 1000 characters.")
    return run_ai(CHAT_SYSTEM, question)


@app.route("/api/academic", methods=["POST"])
def academic():
    data = get_body()
    topic = str(data.get("topic", "")).strip()
    mode = str(data.get("mode", "notes")).strip().lower()
    if not topic:
        return failure("Please enter a subject or topic.")
    if len(topic) > 200:
        return failure("The topic is too long. Please keep it under 200 characters.")
    if mode not in MODE_PROMPTS:
        return failure("Invalid mode. Choose notes, summary, quiz, or practice.")
    prompt = MODE_PROMPTS[mode].format(topic=topic)
    return run_ai(ACADEMIC_SYSTEM, prompt)


@app.route("/api/career", methods=["POST"])
def career():
    data = get_body()
    skills = str(data.get("skills", "")).strip()
    interests = str(data.get("interests", "")).strip()
    if not skills or not interests:
        return failure("Please enter both your skills and your interests.")
    if len(skills) > 500 or len(interests) > 500:
        return failure("Skills and interests must each be under 500 characters.")
    prompt = CAREER_PROMPT.format(skills=skills, interests=interests)
    return run_ai(CAREER_SYSTEM, prompt, suffix=CAREER_DISCLAIMER)


@app.errorhandler(Exception)
def handle_any_error(e):
    if isinstance(e, HTTPException):
        return failure(e.description or "Request failed.", e.code or 400)
    logger.exception("Unhandled server error")
    return failure("Something went wrong on the server. Please try again.", 500)


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port, debug=False)