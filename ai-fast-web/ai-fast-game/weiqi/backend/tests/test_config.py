"""配置模块测试（v2）：默认值、环境注入、非法值回退与结算贴目配置。"""

import os
import unittest
from unittest import mock

from backend.config import (
    APP_VERSION,
    DEFAULT_CANDIDATE_TOP_K,
    DEFAULT_SCORING_KOMI,
    load_settings,
)

# 覆盖为空字符串即等效"未设置"，避免污染真实用户环境。
CONFIG_KEYS = (
    "AI_CANDIDATE_TOP_K",
    "ALLOWED_BOARD_SIZES",
    "CORS_ALLOW_ORIGINS",
    "SCORING_KOMI",
)

BLANK_ENV = {key: "" for key in CONFIG_KEYS}


class ConfigDefaultTests(unittest.TestCase):
    def test_defaults_without_env(self):
        with mock.patch.dict(os.environ, BLANK_ENV, clear=False):
            settings = load_settings()
        self.assertEqual(settings.candidate_top_k, DEFAULT_CANDIDATE_TOP_K)
        self.assertEqual(settings.allowed_sizes, (9, 13, 19))
        self.assertEqual(settings.scoring_komi, DEFAULT_SCORING_KOMI)
        self.assertEqual(APP_VERSION, "2.0.0")

    def test_custom_values_from_env(self):
        env = dict(BLANK_ENV)
        env.update(
            AI_CANDIDATE_TOP_K="40",
            ALLOWED_BOARD_SIZES="9,13",
            CORS_ALLOW_ORIGINS="http://localhost:3000",
            SCORING_KOMI="7.5",
        )
        with mock.patch.dict(os.environ, env, clear=False):
            settings = load_settings()
        self.assertEqual(settings.candidate_top_k, 40)
        self.assertEqual(settings.allowed_sizes, (9, 13))
        self.assertEqual(settings.cors_allow_origins, ("http://localhost:3000",))
        self.assertEqual(settings.scoring_komi, 7.5)

    def test_invalid_numeric_values_fall_back(self):
        env = dict(BLANK_ENV)
        env.update(
            AI_CANDIDATE_TOP_K="zero",
            SCORING_KOMI="abc",
        )
        with mock.patch.dict(os.environ, env, clear=False):
            settings = load_settings()
        self.assertEqual(settings.candidate_top_k, DEFAULT_CANDIDATE_TOP_K)
        self.assertEqual(settings.scoring_komi, DEFAULT_SCORING_KOMI)

    def test_negative_komi_falls_back(self):
        env = dict(BLANK_ENV)
        env["SCORING_KOMI"] = "-1"
        with mock.patch.dict(os.environ, env, clear=False):
            self.assertEqual(load_settings().scoring_komi, DEFAULT_SCORING_KOMI)

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
