// Punctuate and clean a raw transcript (English/Hinglish) using Gemini.
// Use a supported model: gemini-1.5-flash is NOT available for v1beta;
// use gemini-2.5-flash or gemini-2.0-flash.
// https://ai.google.dev/gemini-api/docs/models

const GEMINI_MODEL = "gemini-2.5-flash"; // or "gemini-2.0-flash" if 2.5 is unavailable

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders() });
  }
  try {
    const { transcript } = (await req.json()) as { transcript?: string };
    const raw = typeof transcript === "string" ? transcript.trim() : "";
    if (!raw) {
      return json({ text: "" }, 400);
    }

    const apiKey = Deno.env.get("GEMINI_API_KEY");
    if (!apiKey) {
      console.error("GEMINI_API_KEY is not set");
      return json({ error: "Server configuration error" }, 500);
    }

    const url = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${apiKey}`;
    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [
          {
            role: "user",
            parts: [
              {
                text: `You are a helpful editor. Rewrite the following raw speech-to-text transcript in the same language (English or Hinglish). Add proper punctuation, capitalization, and fix obvious word breaks. Output ONLY the corrected text, no explanation.\n\nTranscript:\n${raw}`,
              },
            ],
          },
        ],
        generationConfig: {
          maxOutputTokens: 2048,
          temperature: 0.2,
        },
      }),
    });

    if (!res.ok) {
      const errBody = await res.text();
      console.error("Gemini error:", errBody);
      return json(
        { error: "Punctuation service failed", details: errBody },
        502
      );
    }

    const data = (await res.json()) as {
      candidates?: Array<{
        content?: { parts?: Array<{ text?: string }> };
      };
    };
    const text =
      data.candidates?.[0]?.content?.parts?.[0]?.text?.trim() ?? raw;
    return json({ text });
  } catch (e) {
    console.error(e);
    return json({ error: String(e) }, 500);
  }
});

function json(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders() },
  });
}

function corsHeaders(): Record<string, string> {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
  };
}
