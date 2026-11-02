import logging
import os
from functools import lru_cache
from typing import Literal

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from openai import OpenAI
from pydantic import BaseModel, Field, field_validator

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="AI Chatbot API")

# 允许本地前端访问，null 用于支持直接双击 index.html 打开。
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:8080", "null"],
    allow_credentials=False,
    allow_methods=["POST", "OPTIONS"],
    allow_headers=["Content-Type"],
)


class ChatMessage(BaseModel):
    role: Literal["user", "assistant"]
    content: str = Field(min_length=1)


class ChatRequest(BaseModel):
    message: str = Field(min_length=1)
    history: list[ChatMessage] = Field(default_factory=list)

    @field_validator("message")
    @classmethod
    def validate_message(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("消息不能为空")
        return value


class ChatResponse(BaseModel):
    reply: str | None = None
    error: str | None = None


@lru_cache
def get_client() -> OpenAI:
    return OpenAI(
        api_key=os.environ["DEEPSEEK_API_KEY"],
        base_url="https://api.deepseek.com",
    )


def generate_reply(messages: list[dict[str, str]]) -> str:
    # 通过 OpenAI 兼容 SDK 调用 DeepSeek，非流式响应便于后续扩展。
    completion = get_client().chat.completions.create(
        model="deepseek-flash",
        messages=messages,
    )
    reply = completion.choices[0].message.content
    if not reply:
        raise ValueError("DeepSeek 返回了空内容")
    return reply


@app.post("/api/chat", response_model=ChatResponse)
async def chat(request: ChatRequest) -> ChatResponse:
    if not os.environ.get("DEEPSEEK_API_KEY"):
        return ChatResponse(error="服务端尚未配置 DEEPSEEK_API_KEY，请联系管理员。")

    # 将历史消息与当前用户消息依次拼接后发送给模型。
    messages = [
        {"role": item.role, "content": item.content} for item in request.history
    ]
    messages.append({"role": "user", "content": request.message})

    try:
        reply = generate_reply(messages)
        return ChatResponse(reply=reply)
    except Exception:
        logger.exception("DeepSeek API 调用失败")
        return ChatResponse(error="AI 服务暂时不可用，请稍后重试。")
