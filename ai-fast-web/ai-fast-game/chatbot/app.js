"use strict";

const API_URL = "http://localhost:8000/api/chat";
const history = [];
let isLoading = false;

const messagesElement = document.getElementById("messages");
const formElement = document.getElementById("chat-form");
const inputElement = document.getElementById("message-input");
const sendButton = document.getElementById("send-button");

function scrollToBottom() {
  messagesElement.scrollTop = messagesElement.scrollHeight;
}

function appendMessage(role, content, extraClass = "") {
  const messageElement = document.createElement("div");
  messageElement.className = `message ${role} ${extraClass}`.trim();

  if (role !== "system") {
    const avatar = document.createElement("div");
    avatar.className = "avatar";
    avatar.setAttribute("aria-hidden", "true");
    avatar.textContent = role === "user" ? "我" : "AI";
    messageElement.appendChild(avatar);
  }

  const bubble = document.createElement("div");
  bubble.className = "bubble";
  bubble.textContent = content;
  messageElement.appendChild(bubble);
  messagesElement.appendChild(messageElement);
  scrollToBottom();
  return messageElement;
}

function setLoading(loading) {
  isLoading = loading;
  sendButton.disabled = loading;
  sendButton.textContent = loading ? "发送中" : "发送";
}

async function sendMessage() {
  const message = inputElement.value.trim();
  if (!message || isLoading) {
    return;
  }

  // 每轮包含一问一答，仅发送当前消息之前的最近 10 轮，避免重复。
  const recentHistory = history.slice(-20);
  history.push({ role: "user", content: message });
  appendMessage("user", message);
  inputElement.value = "";

  setLoading(true);
  const loadingMessage = appendMessage("assistant", "思考中...", "loading");

  try {
    const response = await axios.post(API_URL, {
      message,
      history: recentHistory,
    });
    loadingMessage.remove();

    const { reply, error } = response.data;
    if (error) {
      appendMessage("system", error);
      return;
    }

    if (typeof reply !== "string" || !reply.trim()) {
      appendMessage("system", "AI 返回了空消息，请稍后重试。");
      return;
    }

    appendMessage("assistant", reply);
    history.push({ role: "assistant", content: reply });
  } catch (error) {
    loadingMessage.remove();
    const errorMessage = error.response?.data?.error
      || "无法连接到服务器，请确认后端已启动后重试。";
    appendMessage("system", errorMessage);
  } finally {
    setLoading(false);
    inputElement.focus();
    scrollToBottom();
  }
}

formElement.addEventListener("submit", (event) => {
  event.preventDefault();
  sendMessage();
});

inputElement.addEventListener("keydown", (event) => {
  if (event.key === "Enter" && !event.shiftKey && !event.isComposing) {
    event.preventDefault();
    sendMessage();
  }
});

inputElement.focus();
