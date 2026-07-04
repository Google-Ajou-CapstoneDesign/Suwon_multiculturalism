import os
import json
import chromadb
from chromadb.utils.embedding_functions import GoogleGenerativeAiEmbeddingFunction

_collection: chromadb.Collection | None = None

_DATA_PATH = os.path.join(os.path.dirname(__file__), "../data/labor_law_chunks.json")


def _get_collection() -> chromadb.Collection:
    global _collection
    if _collection is not None:
        return _collection

    db_path = os.getenv("VECTOR_DB_PATH", "./data/chromadb")
    client = chromadb.PersistentClient(path=db_path)

    embedding_fn = GoogleGenerativeAiEmbeddingFunction(
        api_key=os.getenv("GEMINI_API_KEY", ""),
        model_name="models/text-embedding-004",
    )

    _collection = client.get_or_create_collection(
        name="labor_law",
        embedding_function=embedding_fn,
    )

    if _collection.count() == 0:
        _seed_collection(_collection)

    return _collection


def _seed_collection(col: chromadb.Collection) -> None:
    with open(_DATA_PATH, encoding="utf-8") as f:
        chunks: list[dict] = json.load(f)

    col.add(
        ids=[c["id"] for c in chunks],
        documents=[c["content"] for c in chunks],
        metadatas=[
            {
                "topic": c["topic"],
                "law": c["law"],
                "keywords": ", ".join(c.get("keywords", [])),
            }
            for c in chunks
        ],
    )


def search(query: str, n_results: int = 3) -> list[dict]:
    col = _get_collection()
    results = col.query(query_texts=[query], n_results=n_results)
    docs = results["documents"][0]
    metas = results["metadatas"][0]
    return [
        {"content": doc, "topic": meta["topic"], "law": meta["law"]}
        for doc, meta in zip(docs, metas)
    ]
