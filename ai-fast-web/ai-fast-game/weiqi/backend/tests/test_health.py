"""健康检查与应用骨架测试：契约、无密钥降级、密钥不泄露与静态托管预留。"""

import os
import unittest
from unittest import mock

from fastapi.testclient import TestClient

from backend.main import create_app
from backend.tests.test_config import BLANK_ENV


def build_client(testcase: unittest.TestCase, **env_overrides) -> TestClient:
    """在受控环境下装配应用并返回测试客户端。

    健康检查路由在请求期间动态读取环境变量，因此补丁必须覆盖整个
    请求周期（由 addCleanup 保证退出），而不只是应用装配阶段。
    """
    env = dict(BLANK_ENV)
    env.update(env_overrides)
    patcher = mock.patch.dict(os.environ, env, clear=False)
    patcher.start()
    testcase.addCleanup(patcher.stop)
    app = create_app()
    return TestClient(app)


class HealthContractTests(unittest.TestCase):
    def test_health_without_key(self):
        client = build_client(self)
        response = client.get("/api/health")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "ok")
        self.assertFalse(data["llm"])
        self.assertEqual(data["model"], "deepseek-flash")
        self.assertEqual(data["version"], "1.0.0")

    def test_health_fields_exact(self):
        client = build_client(self)
        data = client.get("/api/health").json()
        self.assertEqual(set(data.keys()), {"status", "llm", "model", "version"})

    def test_health_with_key_enabled_and_no_leak(self):
        secret = "unit-test-placeholder-secret"
        client = build_client(self, DEEPSEEK_API_KEY=secret)
        response = client.get("/api/health")
        data = response.json()
        self.assertTrue(data["llm"])
        # 健康响应不得包含任何形式的密钥。
        self.assertNotIn(secret, response.text)

    def test_health_custom_model_name(self):
        client = build_client(self, DEEPSEEK_API_KEY="unit-test-placeholder", DEEPSEEK_MODEL="deepseek-alt")
        data = client.get("/api/health").json()
        self.assertEqual(data["model"], "deepseek-alt")


class AppSkeletonTests(unittest.TestCase):
    def test_root_serves_front_page(self):
        # front/index.html 已由任务 5 创建，GET / 应同源返回人机对弈前端页面。
        client = build_client(self)
        response = client.get("/")
        self.assertEqual(response.status_code, 200)
        self.assertIn("text/html", response.headers.get("content-type", ""))
        # 返回的是改造后的人机对弈页面，而不是原始双人版本。
        self.assertIn("人机对弈", response.text)
        self.assertNotIn("本地双人对弈", response.text)
        # 前端不得包含任何密钥或外部 CDN 引用。
        self.assertNotIn("DEEPSEEK_API_KEY", response.text)
        self.assertNotIn("http://cdn", response.text)
        self.assertNotIn("https://cdn", response.text)

    def test_cors_headers_for_allowed_origin(self):
        client = build_client(self, CORS_ALLOW_ORIGINS="http://127.0.0.1:5500")
        response = client.get(
            "/api/health",
            headers={"Origin": "http://127.0.0.1:5500"},
        )
        self.assertEqual(response.headers.get("access-control-allow-origin"), "http://127.0.0.1:5500")

    def test_cors_rejects_unknown_origin(self):
        client = build_client(self, CORS_ALLOW_ORIGINS="http://127.0.0.1:5500")
        response = client.get(
            "/api/health",
            headers={"Origin": "http://evil.example"},
        )
        self.assertNotIn("http://evil.example", response.headers.get("access-control-allow-origin", ""))

    def test_cors_disabled_with_none(self):
        client = build_client(self, CORS_ALLOW_ORIGINS="none")
        response = client.get("/api/health", headers={"Origin": "http://127.0.0.1:5500"})
        self.assertNotIn("access-control-allow-origin", response.headers)

    def test_unknown_route_friendly_404(self):
        client = build_client(self)
        response = client.get("/api/not-exist")
        self.assertEqual(response.status_code, 404)
        self.assertNotIn("Traceback", response.text)


if __name__ == "__main__":
    unittest.main()
