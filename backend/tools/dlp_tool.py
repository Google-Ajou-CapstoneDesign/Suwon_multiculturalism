"""PII masking tool — regex fallback, Cloud DLP when credentials available."""
from __future__ import annotations
import os
import re

# Regex patterns for Korean PII
_PATTERNS = [
    (re.compile(r"\d{6}-[1-4]\d{6}"), "[주민등록번호]"),
    (re.compile(r"01[016789]-?\d{3,4}-?\d{4}"), "[전화번호]"),
    (re.compile(r"[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}"), "[이메일]"),
    (re.compile(r"\b\d{4}-\d{4}-\d{4}-\d{4}\b"), "[카드번호]"),
]


def mask_pii(text: str) -> str:
    """Mask personally identifiable information from text using regex patterns."""
    for pattern, replacement in _PATTERNS:
        text = pattern.sub(replacement, text)
    return text


async def mask_pii_safe(text: str) -> str:
    """Mask PII, preferring Cloud DLP when credentials are available."""
    project_id = os.getenv("GOOGLE_CLOUD_PROJECT_ID")
    if not project_id:
        return mask_pii(text)

    try:
        import google.cloud.dlp_v2 as dlp
        import asyncio

        client = dlp.DlpServiceClient()
        deidentify_config = {
            "info_type_transformations": {
                "transformations": [
                    {"primitive_transformation": {"replace_with_info_type_config": {}}}
                ]
            }
        }
        inspect_config = {
            "info_types": [
                {"name": "KOREA_RRN"},
                {"name": "PHONE_NUMBER"},
                {"name": "EMAIL_ADDRESS"},
            ]
        }
        response = await asyncio.to_thread(
            client.deidentify_content,
            request={
                "parent": f"projects/{project_id}",
                "deidentify_config": deidentify_config,
                "inspect_config": inspect_config,
                "item": {"value": text},
            },
        )
        return response.item.value
    except Exception:
        return mask_pii(text)
