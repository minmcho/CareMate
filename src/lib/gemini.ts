import { GoogleGenAI, Modality, Type } from "@google/genai";

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

export async function translateAudio(
  base64Audio: string,
  mimeType: string,
  sourceLang: "en" | "my" | "zh" | "ms",
  targetLang: "en" | "my" | "zh" | "ms",
): Promise<{ text: string; audioBase64?: string }> {
  try {
    // 1. Transcribe and translate the audio to text
    const prompt = `You are a helpful translator for a caregiver and an elderly person in Singapore.
    The audio is in ${sourceLang}. Please translate it to ${targetLang}.
    Return ONLY the translated text, nothing else.`;

    const response = await ai.models.generateContent({
      model: "gemini-3-flash-preview",
      contents: {
        parts: [
          {
            inlineData: {
              data: base64Audio,
              mimeType: mimeType,
            },
          },
          { text: prompt },
        ],
      },
    });

    const translatedText = response.text?.trim() || "";

    if (!translatedText) {
      throw new Error("Failed to translate");
    }

    // 2. Generate speech for the translated text
    // Note: TTS model might not support all languages perfectly, but we'll try.
    // For Myanmar (Burmese), TTS might be limited, but we'll use the available voices.
    let audioBase64;
    try {
      const ttsResponse = await ai.models.generateContent({
        model: "gemini-2.5-flash-preview-tts",
        contents: [{ parts: [{ text: `Say: ${translatedText}` }] }],
        config: {
          responseModalities: [Modality.AUDIO],
          speechConfig: {
            voiceConfig: {
              prebuiltVoiceConfig: { voiceName: "Kore" },
            },
          },
        },
      });

      audioBase64 =
        ttsResponse.candidates?.[0]?.content?.parts?.[0]?.inlineData?.data;
    } catch (ttsError) {
      console.error("TTS Error:", ttsError);
      // Fallback to text only if TTS fails
    }

    return { text: translatedText, audioBase64 };
  } catch (error) {
    console.error("Translation Error:", error);
    throw error;
  }
}

export async function extractRecipeFromImage(
  base64Image: string,
  mimeType: string,
  targetLang: "en" | "my" | "th" | "ar"
): Promise<{
  titleEn: string;
  titleLocal: string;
  time: string;
  ingredientsEn: string[];
  ingredientsLocal: string[];
  instructionsEn: string[];
  instructionsLocal: string[];
}> {
  try {
    const prompt = `You are a helpful assistant that extracts recipes from images (handwritten or printed).
    Extract the recipe details. Provide the title, estimated cooking time, ingredients, and step-by-step instructions.
    Translate all content into English AND into the language code: ${targetLang}.
    If the image doesn't contain a recipe, do your best to guess or return empty fields.`;

    const response = await ai.models.generateContent({
      model: "gemini-3-flash-preview",
      contents: {
        parts: [
          {
            inlineData: {
              data: base64Image,
              mimeType: mimeType,
            },
          },
          { text: prompt },
        ],
      },
      config: {
        responseMimeType: "application/json",
        responseSchema: {
          type: Type.OBJECT,
          properties: {
            titleEn: { type: Type.STRING, description: "Recipe title in English" },
            titleLocal: { type: Type.STRING, description: `Recipe title in ${targetLang}` },
            time: { type: Type.STRING, description: "Estimated cooking time (e.g., '30 mins')" },
            ingredientsEn: {
              type: Type.ARRAY,
              items: { type: Type.STRING },
              description: "List of ingredients in English",
            },
            ingredientsLocal: {
              type: Type.ARRAY,
              items: { type: Type.STRING },
              description: `List of ingredients in ${targetLang}`,
            },
            instructionsEn: {
              type: Type.ARRAY,
              items: { type: Type.STRING },
              description: "Step-by-step instructions in English",
            },
            instructionsLocal: {
              type: Type.ARRAY,
              items: { type: Type.STRING },
              description: `Step-by-step instructions in ${targetLang}`,
            },
          },
          required: [
            "titleEn",
            "titleLocal",
            "time",
            "ingredientsEn",
            "ingredientsLocal",
            "instructionsEn",
            "instructionsLocal",
          ],
        },
      },
    });

    const jsonStr = response.text?.trim() || "{}";
    const result = JSON.parse(jsonStr);
    return result;
  } catch (error) {
    console.error("Recipe Extraction Error:", error);
    throw error;
  }
}
