"""配置模块测试：默认值、环境注入、非法值回退与密钥启用逻辑。"""

import os
import unittest
from unittest import mock

from backend.config import (
    APP_VERSION,
    DEFAULT_BASE_URL,
    DEFAULT_CANDIDATE_TOP_K,
    DEFAULT_MAX_RETRIES,
    DEFAULT_MAX_TOKENS,
    DEFAULT_MODEL,
    DEFAULT_RETRY_BACKOFF_SECONDS,
    DEFAULT_TIMEOUT_SECONDS,
    load_settings,
)

# 覆盖为空字符串即等效"未设置"，避免污染真实用户环境。
CONFIG_KEYS = (
    "DEEPSEEK_API_KEY",
    "DEEPSEEK_MODEL",
    "DEEPSEEK_BASE_URL",
    "DEEPSEEK_TIMEOUT_SECONDS",
    "DEEPSEEK_MAX_RETRIES",
    "DEEPSEEK_RETRY_BACKOFF_SECONDS",
    "DEEPSEEK_MAX_TOKENS",
    "AI_CANDIDATE_TOP_K",
    "ALLOWED_BOARD_SIZES",
    "CORS_ALLOW_ORIGINS",
)

BLANK_ENV = {key: "" for key in CONFIG_KEYS}


class ConfigDefaultTests(unittest.TestCase):
    def test_defaults_without_env(self):
        with mock.patch.dict(os.environ, BLANK_ENV, clear=False):
            settings = load_settings()
        self.assertEqual(settings.model, DEFAULT_MODEL)
        self.assertEqual(settings.base_url, DEFAULT_BASE_URL)
        self.assertEqual(settings.timeout_seconds, DEFAULT_TIMEOUT_SECONDS)
        self.assertEqual(settings.max_retries, DEFAULT_MAX_RETRIES)
        self.assertEqual(settings.retry_backoff_seconds, DEFAULT_RETRY_BACKOFF_SECONDS)
        self.assertEqual(settings.max_tokens, DEFAULT_MAX_TOKENS)
        self.assertEqual(settings.candidate_top_k, DEFAULT_CANDIDATE_TOP_K)
        self.assertEqual(settings.allowed_sizes, (9, 13, 19))
        self.assertFalse(settings.llm_enabled)
        self.assertEqual(APP_VERSION, "1.0.0")

    def test_custom_values_from_env(self):
        env = dict(BLANK_ENV)
        env.update(
            DEEPSEEK_API_KEY="unit-test-placeholder",
            DEEPSEEK_MODEL="deepseek-test-model",
            DEEPSEEK_BASE_URL="https://example.invalid/v1/",
            DEEPSEEK_TIMEOUT_SECONDS="20",
            DEEPSEEK_MAX_RETRIES="2",
            DEEPSEEK_RETRY_BACKOFF_SECONDS="1.5",
            DEEPSEEK_MAX_TOKENS="256",
            AI_CANDIDATE_TOP_K="40",
            ALLOWED_BOARD_SIZES="9,13",
            CORS_ALLOW_ORIGINS="http://localhost:3000",
        )
        with mock.patch.dict(os.environ, env, clear=False):
            settings = load_settings()
        self.assertTrue(settings.llm_enabled)
        self.assertEqual(settings.model, "deepseek-test-model")
        # 服务地址末尾斜杠应被归一化。
        self.assertEqual(settings.base_url, "https://example.invalid/v1")
        self.assertEqual(settings.timeout_seconds, 20.0)
        self.assertEqual(settings.max_retries, 2)
        self.assertEqual(settings.retry_backoff_seconds, 1.5)
        self.assertEqual(settings.max_tokens, 256)
        self.assertEqual(settings.candidate_top_k, 40)
        self.assertEqual(settings.allowed_sizes, (9, 13))
        self.assertEqual(settings.cors_allow_origins, ("http://localhost:3000",))

    def test_invalid_numeric_values_fall_back(self):
        env = dict(BLANK_ENV)
        env.update(
            DEEPSEEK_TIMEOUT_SECONDS="abc",
            DEEPSEEK_MAX_RETRIES="-3",
            DEEPSEEK_RETRY_BACKOFF_SECONDS="xyz",
            DEEPSEEK_MAX_TOKENS="tiny",
            AI_CANDIDATE_TOP_K="zero",
        )
        with mock.patch.dict(os.environ, env, clear=False):
            settings = load_settings()
        self.assertEqual(settings.timeout_seconds, DEFAULT_TIMEOUT_SECONDS)
        self.assertEqual(settings.max_retries, DEFAULT_MAX_RETRIES)
        self.assertEqual(settings.retry_backoff_seconds, DEFAULT_RETRY_BACKOFF_SECONDS)
        self.assertEqual(settings.max_tokens, DEFAULT_MAX_TOKENS)
        self.assertEqual(settings.candidate_top_k, DEFAULT_CANDIDATE_TOP_K)

    def test_llm_enabled_requires_nonblank_key(self):
        env = dict(BLANK_ENV)
        env["DEEPSEEK_API_KEY"] = "   "
        with mock.patch.dict(os.environ, env, clear=False):
            self.assertFalse(load_settings().llm_enabled)

    def test_cors_can_be_disabled(self):
        env = dict(BLANK_ENV)
        env["CORS_ALLOW_ORIGINS"] = "none"
        with mock.patch.dict(os.environ, env, clear=False):
            self.assertEqual(load_settings().cors_allow_origins, ())

    def test_invalid_board_sizes_fall_back(self):
        env = dict(BLANK_ENV)
        env["ALLOWED_BOARD_SIZES"] = "x,13,-5"
        with mock.patch.dict(os.environ, env, clear=False):
            self.assertEqual(load_settings().allowed_sizes, (13,))


if __name__ == "__main__":
    unittest.main()
