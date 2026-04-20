"""VLLM inference service — communicates with a vLLM OpenAI-compatible server."""
from typing import List, Optional, AsyncGenerator
from openai import AsyncOpenAI

from app.config import settings


_client: Optional[AsyncOpenAI] = None


def get_vllm_client() -> AsyncOpenAI:
    global _client
    if _client is None:
        _client = AsyncOpenAI(
            base_url=settings.VLLM_BASE_URL,
            api_key="not-needed",  # vLLM doesn't require a real key by default
        )
    return _client


async def generate(
    prompt: str,
    system_prompt: str = "You are CareMate, a helpful AI caregiver assistant.",
    temperature: float = 0.7,
    max_tokens: int = 1024,
    language: str = "en",
) -> str:
    """Single-shot generation via vLLM."""
    client = get_vllm_client()
    lang_instruction = _language_instruction(language)
    response = await client.chat.completions.create(
        model=settings.VLLM_MODEL,
        messages=[
            {"role": "system", "content": f"{system_prompt}\n{lang_instruction}"},
            {"role": "user", "content": prompt},
        ],
        temperature=temperature,
        max_tokens=max_tokens,
    )
    return response.choices[0].message.content.strip()


async def generate_with_history(
    messages: List[dict],
    system_prompt: str = "You are CareMate, a helpful AI caregiver assistant.",
    temperature: float = 0.7,
    max_tokens: int = 1024,
    language: str = "en",
) -> str:
    """Multi-turn chat generation."""
    client = get_vllm_client()
    lang_instruction = _language_instruction(language)
    full_messages = [
        {"role": "system", "content": f"{system_prompt}\n{lang_instruction}"},
        *messages,
    ]
    response = await client.chat.completions.create(
        model=settings.VLLM_MODEL,
        messages=full_messages,
        temperature=temperature,
        max_tokens=max_tokens,
    )
    return response.choices[0].message.content.strip()


async def stream_generate(
    prompt: str,
    system_prompt: str = "You are CareMate, a helpful AI caregiver assistant.",
    language: str = "en",
) -> AsyncGenerator[str, None]:
    """Streaming generation — yields text chunks."""
    client = get_vllm_client()
    lang_instruction = _language_instruction(language)
    stream = await client.chat.completions.create(
        model=settings.VLLM_MODEL,
        messages=[
            {"role": "system", "content": f"{system_prompt}\n{lang_instruction}"},
            {"role": "user", "content": prompt},
        ],
        stream=True,
    )
    async for chunk in stream:
        delta = chunk.choices[0].delta.content
        if delta:
            yield delta


async def reason_and_generate(
    prompt: str,
    context: str = "",
    language: str = "en",
) -> dict:
    """
    Chain-of-thought reasoning generation.
    Returns {"reasoning": str, "answer": str}
    """
    cot_system = (
        "You are CareMate, an expert AI caregiver assistant. "
        "Think step by step before answering. "
        "Format your response as:\n"
        "REASONING: <your step-by-step thinking>\n"
        "ANSWER: <your final answer>"
    )
    full_prompt = f"Context:\n{context}\n\nQuestion:\n{prompt}" if context else prompt
    raw = await generate(full_prompt, system_prompt=cot_system, language=language, temperature=0.3)

    reasoning, answer = "", raw
    if "REASONING:" in raw and "ANSWER:" in raw:
        parts = raw.split("ANSWER:", 1)
        reasoning = parts[0].replace("REASONING:", "").strip()
        answer = parts[1].strip()
    return {"reasoning": reasoning, "answer": answer}


def _language_instruction(language: str) -> str:
    instructions = {
        "en": "Always respond in English.",
        "my": "Always respond in Burmese (Myanmar language, မြန်မာဘာသာ).",
        "th": "Always respond in Thai (ภาษาไทย).",
        "ar": "Always respond in Arabic (العربية).",
    }
    return instructions.get(language, "Always respond in English.")
