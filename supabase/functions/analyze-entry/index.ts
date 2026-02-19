// Analyze a journal entry (reflection or rant) using Gemini and return
// structured JSON: title, moods, insight, topics.

const GEMINI_MODEL = "gemini-2.5-flash";

const MOOD_LIST = [
  "Enraged","Panicked","Stressed","Jittery","Livid","Furious","Frustrated",
  "Tense","Fuming","Frightened","Angry","Nervous","Restless","Anxious",
  "Apprehensive","Worried","Irritated","Annoyed","Repulsed","Troubled",
  "Concerned","Uneasy","Peeved","Disgusted","Shocked","Surprised","Upbeat",
  "Festive","Hyper","Cheerful","Motivated","Inspired","Elated","Lively",
  "Excited","Optimistic","Enthusiastic","Energized","Thrilled","Happy","Proud",
  "Focused","Exhilarated","Ecstatic","Joyful","Playful","Blissful","Hopeful",
  "Pleased","At Ease","Easygoing","Content","Loving","Fulfilled","Calm",
  "Secure","Satisfied","Grateful","Touched","Apathetic","Down","Sad","Bored",
  "Discouraged","Morose","Pessimistic","Glum","Disappointed","Alienated",
  "Disheartened","Miserable","Lonely",
];

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return json({}, 200);
  }

  try {
    const { content, entryType } = (await req.json()) as {
      content?: string;
      entryType?: string;
    };

    const text = typeof content === "string" ? content.trim() : "";
    if (!text) {
      return json({ error: "content is required" }, 400);
    }

    const apiKey = Deno.env.get("GEMINI_API_KEY");
    if (!apiKey) {
      console.error("GEMINI_API_KEY is not set");
      return json({ error: "Server configuration error" }, 500);
    }

    const modeLabel = entryType === "rant" ? "rant" : "reflection";
    const moodListStr = MOOD_LIST.join(", ");

    const prompt = `You are a thoughtful journaling companion. Analyze this ${modeLabel} entry and return ONLY a JSON object — no markdown, no code block, no extra text.

Journal entry:
"""
${text}
"""

Return this exact JSON structure:
{
  "title": "<short title, max 10 words, capturing the core theme>",
  "moods": ["<mood1>", "<mood2>"],
  "insight": "<2-4 sentence insight about what the person expressed, written in second person (You...)>",
  "topics": ["<topic1>", "<topic2>", "<topic3>"]
}

Rules:
- title: 10 words or fewer, plain text, no quotes inside
- moods: 1 to 3 moods, chosen ONLY from this list: ${moodListStr}
- insight: 2-4 sentences, empathetic, second person ("You...")
- topics: 2 to 5 short topic tags (1-3 words each), lowercase

Output ONLY the JSON object.`;

    const url = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${apiKey}`;
    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ role: "user", parts: [{ text: prompt }] }],
        generationConfig: {
          maxOutputTokens: 512,
          temperature: 0.4,
        },
      }),
    });

    if (!res.ok) {
      const errBody = await res.text();
      console.error("Gemini error:", errBody);
      return json({ error: "Analysis service failed", details: errBody }, 502);
    }

    const data = (await res.json()) as {
      candidates?: Array<{
        content?: { parts?: Array<{ text?: string }> };
      }>;
    };

    const rawText =
      data.candidates?.[0]?.content?.parts?.[0]?.text?.trim() ?? "";

    // Strip markdown code fences if Gemini wraps the response
    const cleaned = rawText
      .replace(/^```(?:json)?\s*/i, "")
      .replace(/\s*```$/, "")
      .trim();

    let parsed: Record<string, unknown>;
    try {
      parsed = JSON.parse(cleaned);
    } catch {
      console.error("Failed to parse Gemini JSON:", cleaned);
      return json({ error: "Invalid JSON from analysis model" }, 502);
    }

    return json({
      title: String(parsed.title ?? ""),
      moods: Array.isArray(parsed.moods) ? parsed.moods.map(String) : [],
      insight: String(parsed.insight ?? ""),
      topics: Array.isArray(parsed.topics) ? parsed.topics.map(String) : [],
    });
  } catch (e) {
    console.error(e);
    return json({ error: String(e) }, 500);
  }
});

function json(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization",
    },
  });
}
