"""ChromaDB-backed semantic memory (RAG) for user wellness context."""

from __future__ import annotations

from dataclasses import dataclass
from typing import List, Optional

from loguru import logger

try:  # ChromaDB is optional at import-time so tests can stub it.
    import chromadb  # type: ignore
    from chromadb.config import Settings as ChromaSettings  # type: ignore
except Exception:  # pragma: no cover
    chromadb = None  # type: ignore
    ChromaSettings = None  # type: ignore

from app.core.config import get_settings


@dataclass
class MemoryRecord:
    user_id: str
    content: str
    kind: str  # "profile" | "chat" | "session"
    score: float = 0.0


class WellnessMemory:
    """Thin wrapper around ChromaDB for per-user semantic recall."""

    def __init__(self) -> None:
        settings = get_settings()
        self._collection = None
        self._collection_name = settings.chroma_collection
        if chromadb is None:
            logger.info("ChromaDB not installed — memory is disabled")
            return
        try:
            self._client = chromadb.HttpClient(
                host=settings.chroma_host,
                port=settings.chroma_port,
            )
            self._collection = self._client.get_or_create_collection(
                self._collection_name,
                metadata={"hnsw:space": "cosine"},
            )
        except Exception as exc:  # pragma: no cover
            logger.warning("ChromaDB unavailable: {}", exc)
            self._collection = None

    def add(self, user_id: str, text: str, kind: str, embedding_id: str) -> None:
        if self._collection is None:
            return
        self._collection.upsert(
            ids=[embedding_id],
            documents=[text],
            metadatas=[{"user_id": user_id, "kind": kind}],
        )

    def recall(self, user_id: str, query: str, k: int = 3) -> List[MemoryRecord]:
        if self._collection is None:
            return []
        results = self._collection.query(
            query_texts=[query],
            n_results=k,
            where={"user_id": user_id},
        )
        records: List[MemoryRecord] = []
        docs: Optional[List[List[str]]] = results.get("documents")
        metas: Optional[List[List[dict]]] = results.get("metadatas")
        distances: Optional[List[List[float]]] = results.get("distances")
        if not docs or not metas:
            return records
        for doc, meta, dist in zip(docs[0], metas[0], (distances or [[0.0] * len(docs[0])])[0]):
            records.append(
                MemoryRecord(
                    user_id=str(meta.get("user_id", user_id)),
                    content=doc,
                    kind=str(meta.get("kind", "chat")),
                    score=float(1.0 - dist),
                )
            )
        return records
