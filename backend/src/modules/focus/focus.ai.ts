// AI-powered focus plan generation using Google Gemini Flash (free tier).
//
// This is a *drop-in upgrade* for the rule-based `buildFocusPlan`: it returns
// the exact same JSON shape the Flutter app already parses (FocusPlan.fromJson),
// so nothing on the client needs to change. The caller is responsible for
// falling back to the rule-based plan if this throws (no key, timeout, bad
// JSON, rate limit) — keeping the app fully functional without AI.

export interface FocusPlanResult {
  normalizedLabel: string;
  subject: string;
  subjects: string[];
  action: string;
  topic: string;
  clarityLevel: string; // 'vague' | 'medium' | 'detailed'
  focusMode: string;
  recommendedMinutes: number;
  pomodoroCount: number;
  advice: string;
  steps: string[];
  warnings: string[];
}

// Gemini Flash: fast, free tier, supports JSON output via responseMimeType.
// Note: gemini-2.0-flash is no longer on the free tier (limit: 0); 2.5 models are.
// We try these in order — if the first is overloaded (503), we fall to the next.
const MODELS = ['gemini-2.5-flash', 'gemini-2.5-flash-lite'];
const GEMINI_BASE = 'https://generativelanguage.googleapis.com/v1beta/models';
const TIMEOUT_MS = 15000; // free-tier Gemini can be slow; 8s was too tight
const MAX_ATTEMPTS_PER_MODEL = 2;

// Transient errors worth retrying / failing over to another model.
function isTransient(status: number): boolean {
  return status === 503 || status === 429 || status === 500;
}

export function isAiPlanEnabled(): boolean {
  return Boolean(process.env.GEMINI_API_KEY && process.env.GEMINI_API_KEY.trim());
}

const SYSTEM_PROMPT = `You are a study-focus planning assistant inside a Pomodoro app for students.
The user gives a learning goal (often short or vague, possibly in Vietnamese or English) plus an optional session length and task type.
Return a concrete, encouraging focus plan that fits ONE timer block.

Rules:
- Keep it realistic for a single sitting. Do not invent a multi-day curriculum.
- "recommendedMinutes" must be a positive integer (typically 25, 45, or 50); respect the user's selectedMinutes when sensible.
- "steps" should be 3 short, actionable lines that together fit within recommendedMinutes (prep / focus block / review).
- "warnings" should flag problems like a vague goal or too many subjects at once; use an empty array if none.
- "clarityLevel" is one of: "vague", "medium", "detailed".
- ALWAYS write all text fields (normalizedLabel, subject, subjects, topic, focusMode, advice, steps, warnings) in ENGLISH, even if the user's goal is written in another language. Translate the goal into English as needed.
- Respond with ONLY a JSON object matching the schema. No markdown, no commentary.`;

function buildUserPrompt(goal: string, selectedMinutes?: number, selectedTask?: string): string {
  return JSON.stringify({
    goal,
    selectedMinutes: selectedMinutes ?? null,
    selectedTask: selectedTask ?? null,
    schema: {
      normalizedLabel: 'string (short title for this session)',
      subject: 'string (main subject, or "General")',
      subjects: 'string[] (one or more detected subjects)',
      action: 'string (e.g. study, practice, read, write, review)',
      topic: 'string (the specific topic to focus on)',
      clarityLevel: '"vague" | "medium" | "detailed"',
      focusMode: 'string (e.g. "Focused Study", "Deep Focus")',
      recommendedMinutes: 'integer',
      pomodoroCount: 'integer (1 or 2)',
      advice: 'string (one or two sentences)',
      steps: 'string[] of exactly 3 items',
      warnings: 'string[] (possibly empty)',
    },
  });
}

function coerceToPlan(
  raw: unknown,
  goal: string,
  selectedMinutes?: number,
): FocusPlanResult {
  if (typeof raw !== 'object' || raw === null) {
    throw new Error('AI plan response was not an object');
  }
  const obj = raw as Record<string, unknown>;

  const asString = (v: unknown, fallback: string): string =>
    typeof v === 'string' && v.trim() ? v.trim() : fallback;
  const asStringArray = (v: unknown): string[] =>
    Array.isArray(v) ? v.map((item) => String(item)).filter((s) => s.trim()) : [];

  const recommendedMinutes = (() => {
    const n = Number(obj.recommendedMinutes);
    if (Number.isFinite(n) && n > 0) return Math.round(n);
    return selectedMinutes && selectedMinutes > 0 ? selectedMinutes : 45;
  })();

  const pomodoroCount = (() => {
    const n = Number(obj.pomodoroCount);
    if (Number.isFinite(n) && n >= 1) return Math.round(n);
    return recommendedMinutes > 25 ? 2 : 1;
  })();

  const clarity = asString(obj.clarityLevel, 'medium');
  const subjects = asStringArray(obj.subjects);

  return {
    normalizedLabel: asString(obj.normalizedLabel, goal.trim() || 'Focus'),
    subject: asString(obj.subject, subjects[0] ?? 'General'),
    subjects: subjects.length ? subjects : ['General'],
    action: asString(obj.action, 'study'),
    topic: asString(obj.topic, 'Focus Goal'),
    clarityLevel: ['vague', 'medium', 'detailed'].includes(clarity) ? clarity : 'medium',
    focusMode: asString(obj.focusMode, 'Focused Study'),
    recommendedMinutes,
    pomodoroCount,
    advice: asString(obj.advice, 'Focus on one clear task until the timer ends.'),
    steps: (() => {
      const s = asStringArray(obj.steps);
      return s.length ? s : ['Pick one target before starting.', 'Protect the timer from distractions.', 'Review what to do next before stopping.'];
    })(),
    warnings: asStringArray(obj.warnings),
  };
}

export async function buildFocusPlanWithAI(
  goal: string,
  selectedMinutes?: number,
  selectedTask?: string,
): Promise<FocusPlanResult> {
  const apiKey = process.env.GEMINI_API_KEY?.trim();
  if (!apiKey) {
    throw new Error('GEMINI_API_KEY is not configured');
  }

  const prompt = buildUserPrompt(goal, selectedMinutes, selectedTask);
  let lastError: unknown = new Error('No Gemini attempt was made');

  // Try each model; for each, retry on transient (503/429/500) errors. The
  // free tier of the primary model occasionally returns 503 "high demand", so
  // a quick retry + a lighter backup model keeps the feature reliable.
  for (const model of MODELS) {
    for (let attempt = 1; attempt <= MAX_ATTEMPTS_PER_MODEL; attempt++) {
      try {
        return await callGemini(apiKey, model, prompt, goal, selectedMinutes);
      } catch (error) {
        lastError = error;
        const status = error instanceof GeminiHttpError ? error.status : 0;
        // Retry the same model only on transient errors; otherwise move on.
        if (!isTransient(status)) break;
      }
    }
  }

  throw lastError;
}

class GeminiHttpError extends Error {
  constructor(public status: number, message: string) {
    super(message);
    this.name = 'GeminiHttpError';
  }
}

async function callGemini(
  apiKey: string,
  model: string,
  prompt: string,
  goal: string,
  selectedMinutes?: number,
): Promise<FocusPlanResult> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), TIMEOUT_MS);
  const url = `${GEMINI_BASE}/${model}:generateContent?key=${encodeURIComponent(apiKey)}`;

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: SYSTEM_PROMPT }] },
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        generationConfig: { temperature: 0.4, responseMimeType: 'application/json' },
      }),
      signal: controller.signal,
    });

    if (!response.ok) {
      const detail = await response.text().catch(() => '');
      throw new GeminiHttpError(
        response.status,
        `Gemini request failed (${model}): ${response.status} ${detail.slice(0, 200)}`,
      );
    }

    const data = (await response.json()) as {
      candidates?: { content?: { parts?: { text?: string }[] } }[];
    };
    const content = data.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!content) {
      throw new Error(`Gemini response had no content (${model})`);
    }

    const parsed = JSON.parse(content);
    return coerceToPlan(parsed, goal, selectedMinutes);
  } finally {
    clearTimeout(timeout);
  }
}

// ---------------------------------------------------------------------------
// Post-session recap: a short, encouraging "Kiki" message + a concrete
// suggestion for the next session, shown on the Focus Complete screen.
// ---------------------------------------------------------------------------

export interface FocusRecapInput {
  label: string;
  minutes: number;
  currentStreak: number;
  todayFocusMinutes: number;
  dailyGoalMinutes: number;
  dailyGoalCompleted: boolean;
}

export interface FocusRecapResult {
  praise: string; // 1 short celebratory line from Kiki
  suggestion: string; // 1 short, concrete next-session suggestion
}

const RECAP_SYSTEM_PROMPT = `You are Kiki, a friendly fox study companion inside a Pomodoro app for students.
A study session just finished. Given its details, return a warm, motivating recap.

Rules:
- "praise": ONE short sentence (max ~16 words) celebrating the session. Warm, specific, encouraging. You may use one emoji.
- "suggestion": ONE short, concrete suggestion for what to focus on next time (max ~20 words).
- Write in ENGLISH only.
- Keep Kiki's voice cheerful and supportive, never preachy.
- Respond with ONLY a JSON object: {"praise": string, "suggestion": string}. No markdown, no commentary.`;

function buildRecapPrompt(input: FocusRecapInput): string {
  return JSON.stringify({
    justFinished: {
      task: input.label,
      minutes: input.minutes,
    },
    progress: {
      currentStreakDays: input.currentStreak,
      todayFocusMinutes: input.todayFocusMinutes,
      dailyGoalMinutes: input.dailyGoalMinutes,
      dailyGoalCompleted: input.dailyGoalCompleted,
    },
  });
}

export async function buildFocusRecapWithAI(
  input: FocusRecapInput,
): Promise<FocusRecapResult> {
  const apiKey = process.env.GEMINI_API_KEY?.trim();
  if (!apiKey) {
    throw new Error('GEMINI_API_KEY is not configured');
  }

  const prompt = buildRecapPrompt(input);
  let lastError: unknown = new Error('No Gemini attempt was made');

  for (const model of MODELS) {
    for (let attempt = 1; attempt <= MAX_ATTEMPTS_PER_MODEL; attempt++) {
      try {
        return await callGeminiRecap(apiKey, model, prompt);
      } catch (error) {
        lastError = error;
        const status = error instanceof GeminiHttpError ? error.status : 0;
        if (!isTransient(status)) break;
      }
    }
  }

  throw lastError;
}

async function callGeminiRecap(
  apiKey: string,
  model: string,
  prompt: string,
): Promise<FocusRecapResult> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), TIMEOUT_MS);
  const url = `${GEMINI_BASE}/${model}:generateContent?key=${encodeURIComponent(apiKey)}`;

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: RECAP_SYSTEM_PROMPT }] },
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        generationConfig: { temperature: 0.7, responseMimeType: 'application/json' },
      }),
      signal: controller.signal,
    });

    if (!response.ok) {
      const detail = await response.text().catch(() => '');
      throw new GeminiHttpError(
        response.status,
        `Gemini recap failed (${model}): ${response.status} ${detail.slice(0, 200)}`,
      );
    }

    const data = (await response.json()) as {
      candidates?: { content?: { parts?: { text?: string }[] } }[];
    };
    const content = data.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!content) {
      throw new Error(`Gemini recap had no content (${model})`);
    }

    const parsed = JSON.parse(content) as Record<string, unknown>;
    const praise = typeof parsed.praise === 'string' ? parsed.praise.trim() : '';
    const suggestion = typeof parsed.suggestion === 'string' ? parsed.suggestion.trim() : '';
    if (!praise && !suggestion) {
      throw new Error('Gemini recap had empty fields');
    }
    return {
      praise: praise || 'Great focus session! Kiki is proud of you. 🎉',
      suggestion: suggestion || 'Next time, pick one clear topic before the timer starts.',
    };
  } finally {
    clearTimeout(timeout);
  }
}
