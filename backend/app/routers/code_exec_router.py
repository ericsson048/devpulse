import asyncio
import sys
import traceback
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

router = APIRouter(prefix="/code-exec", tags=["Code Execution"])


class CodeExecuteRequest(BaseModel):
    language: str
    code: str
    stdin: str = ""


class CodeExecuteResponse(BaseModel):
    stdout: str = ""
    stderr: str = ""
    exit_code: int = 0


SUPPORTED_LANGUAGES = {"python", "py"}


def _sanitize_code(code: str) -> str:
    dangerous = ["__import__", "eval(", "exec(", "open(", "os.", "subprocess", "importlib"]
    for kw in dangerous:
        if kw in code:
            raise HTTPException(status_code=400, detail=f"Code contains forbidden pattern: {kw}")
    return code


@router.post("/execute", response_model=CodeExecuteResponse)
async def execute_code(body: CodeExecuteRequest):
    if body.language.lower() not in SUPPORTED_LANGUAGES:
        raise HTTPException(status_code=400, detail=f"Language '{body.language}' not supported. Use: {SUPPORTED_LANGUAGES}")

    safe_code = _sanitize_code(body.code)

    try:
        loop = asyncio.get_event_loop()
        result = await asyncio.wait_for(
            loop.run_in_executor(None, _run_python, safe_code, body.stdin),
            timeout=10.0,
        )
        return CodeExecuteResponse(
            stdout=result["stdout"],
            stderr=result["stderr"],
            exit_code=result["exit_code"],
        )
    except asyncio.TimeoutError:
        return CodeExecuteResponse(stdout="", stderr="Execution timed out after 10 seconds", exit_code=-1)
    except HTTPException:
        raise
    except Exception as e:
        return CodeExecuteResponse(stdout="", stderr=f"Internal error: {str(e)}", exit_code=-1)


def _run_python(code: str, stdin: str) -> dict:
    import subprocess
    try:
        proc = subprocess.run(
            [sys.executable, "-c", code],
            input=stdin,
            capture_output=True,
            text=True,
            timeout=8,
        )
        return {
            "stdout": proc.stdout,
            "stderr": proc.stderr,
            "exit_code": proc.returncode,
        }
    except subprocess.TimeoutExpired:
        return {"stdout": "", "stderr": "Execution timed out", "exit_code": -1}
