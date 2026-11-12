"""健康检查（v2 引擎信息契约）与应用骨架测试：静态托管预留与 CORS。"""

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
    def test_health_engine_contract(self):
        client = build_client(self)
        response = client.get("/api/health")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "ok")
        self.assertEqual(data["engine"], "kyu-engine")
        self.assertEqual(data["levels"], [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
        self.assertEqual(data["sizes"], [9, 13, 19])
        self.assertEqual(data["version"], "2.0.0")

    def test_health_fields_exact(self):
        client = build_client(self)
        data = client.get("/api/health").json()
        self.assertEqual(set(data.keys()), {"status", "engine", "levels", "sizes", "version"})

    def test_health_reflects_allowed_sizes(self):
        client = build_client(self, ALLOWED_BOARD_SIZES="9,13")
        data = client.get("/api/health").json()
        self.assertEqual(data["sizes"], [9, 13])


class AppSkeletonTests(unittest.TestCase):
    def test_root_serves_front_page(self):
        # front/index.html 存在时，GET / 应同源返回对弈前端页面。
        client = build_client(self)
        response = client.get("/")
        self.assertEqual(response.status_code, 200)
        self.assertIn("text/html", response.headers.get("content-type", ""))
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

    def test_old_ai_move_route_removed(self):
        # 旧路径 /api/ai-move 更名后必须 404（无兼容层）。
        client = build_client(self)
        response = client.post("/api/ai-move", json={})
        self.assertEqual(response.status_code, 404)


if __name__ == "__main__":
    unittest.main()
