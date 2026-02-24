// Generate a follow-up question for a journal entry using Gemini.
// Returns a warm, empathetic sentence + open-ended question as plain text.

const GEMINI_MODEL = "gemini-2.5-flash";

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return json({}, 200);
  }

  try {
    const { content } = (await req.json()) as { content?: string };

    if (!content || content.trim().length === 0) {
      return json({ followUp: "What else is on your mind?" });
    }

    const apiKey = Deno.env.get("GEMINI_API_KEY");
    if (!apiKey) {
      console.error("GEMINI_API_KEY not set");
      return json({ followUp: "What else is on your mind?" });
    }

    const prompt = `Read this journal entry carefully. Write one brief empathetic sentence acknowledging what was shared, followed by one open-ended follow-up question to help the writer go deeper. Keep it warm, concise, non-clinical. Second person. Return as plain text only — no JSON, no labels, no formatting — just the sentence and question together.\n\nJournal entry:\n${content}`;

    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${apiKey}`;

    const geminiRes = await fetch(geminiUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { temperature: 0.7, maxOutputTokens: 1024 },
      }),
    });

    if (!geminiRes.ok) {
      console.error("Gemini error:", await geminiRes.text());
      return json({ followUp: "What else is on your mind?" });
    }

    const geminiData = await geminiRes.json();
    const text: string =
      geminiData?.candidates?.[0]?.content?.parts?.[0]?.text?.trim() ?? "";

    if (!text) {
      return json({ followUp: "What else is on your mind?" });
    }

    return json({ followUp: text });
  } catch (e) {
    console.error("generate-followup error:", e);
    return json({ followUp: "What else is on your mind?" });
  }
});
