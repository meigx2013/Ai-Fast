"""DeepSeek 模型模块测试：全部使用 Mock/Fake 客户端，不访问真实网络与密钥。

覆盖：成功路径、防御性解析（Markdown/非 JSON/缺字段/类型错误/越界/非法坐标）、
超时/网络/HTTP 失败的重试与降级、无密钥禁用、engine 标记如实、密钥不泄露。
"""

import unittest
from unittest import mock

import httpx

from backend import go_rules as gr
from backend.ai import heuristic, levels, llm
from backend.config import Settings
from backend.models import AiMoveRequest
from backend.tests.test_health import build_client

TEST_KEY = "unit-test-placeholder-secret"


def empty_board(size: int = 9) -> list[list[int]]:
    return [[gr.EMPTY] * size for _ in range(size)]


def place(board, points, color):
    for row, col in points:
        board[row][col] = color


def make_settings(**overrides) -> Settings:
    values = dict(
        api_key=TEST_KEY,
        model="deepseek-v4.1-flash",
        base_url="https://unit.test",
        timeout_seconds=12.0,
        max_retries=1,
        retry_backoff_seconds=0.0,
        max_tokens=512,
        candidate_top_k=30,
        allowed_sizes=(9, 13, 19),
        cors_allow_origins=(),
    )
    values.update(overrides)
    return Settings(**values)


def make_request(board=None, level=5) -> AiMoveRequest:
    if board is None:
        board = empty_board()
        place(board, [(4, 4)], gr.BLACK)
    return AiMoveRequest(
        board=board, size=len(board), level=level, moveNumber=1,
        lastMove={"row": 4, "col": 4}, previousBoard=None, consecutivePasses=0,
    )


def chat_content(text: str) -> dict:
    """构造 Chat Completions 风格的成功响应体。"""
    return {"choices": [{"message": {"role": "assistant", "content": text}}]}


def ok_text(row: int, col: int, reason: str = "扩展右下角") -> str:
    return '{"move":{"row":%d,"col":%d},"reason":"%s"}' % (row, col, reason)


class FakeResponse:
    def __init__(self, status_code: int = 200, payload=None):
        self.status_code = status_code
        self._payload = payload

    def json(self):
        if self._payload is None:
            raise ValueError("无 JSON 响应体")
        return self._payload


class FakeAsyncClient:
    """替代 httpx.AsyncClient 的假客户端：按脚本回放响应或抛异常。"""

    def __init__(self, responses=None, exception: Exception | None = None):
        self.responses = list(responses or [])
        self.exception = exception
        self.calls: list[tuple] = []

    async def __aenter__(self):
        return self

    async def __aexit__(self, *exc_info):
        return False

    async def post(self, url, **kwargs):
        self.calls.append((url, kwargs))
        if self.exception is not None:
            raise self.exception
        item = self.responses.pop(0) if self.responses else FakeResponse(500)
        if isinstance(item, Exception):
            raise item
        return item


def patch_client(fake: FakeAsyncClient):
    return mock.patch("backend.ai.llm._build_client", return_value=fake)


class LlmUnitTests(unittest.IsolatedAsyncioTestCase):
    async def test_success_returns_validated_move(self):
        fake = FakeAsyncClient(responses=[FakeResponse(payload=chat_content(ok_text(4, 5)))])
        request = make_request()
        candidates = heuristic.generate_candidates(request.board, 9, gr.WHITE)
        with patch_client(fake):
            move, reason = await llm.request_llm_move(
                request, levels.get_level_profile(5), make_settings(), candidates, (4, 4)
            )
        self.assertEqual(move, (4, 5))
        self.assertEqual(reason, "扩展右下角")
        self.assertEqual(len(fake.calls), 1)
        url, kwargs = fake.calls[0]
        self.assertEqual(url, "https://unit.test/chat/completions")
        # 请求头携带 Bearer 密钥（仅注入，不打印）。
        self.assertEqual(kwargs["headers"]["Authorization"], f"Bearer {TEST_KEY}")
        payload = kwargs["json"]
        self.assertEqual(payload["model"], "deepseek-v4.1-flash")
        self.assertEqual(payload["temperature"], levels.get_level_profile(5).temperature)
        self.assertEqual(payload["max_tokens"], 512)
        self.assertLessEqual(payload["max_tokens"], 2048, "max_tokens 必须有界")

    async def test_prompt_contains_board_coordinates_and_level_strategy(self):
        fake = FakeAsyncClient(responses=[FakeResponse(payload=chat_content(ok_text(4, 5)))])
        request = make_request()
        candidates = heuristic.generate_candidates(request.board, 9, gr.WHITE)
        with patch_client(fake):
            await llm.request_llm_move(
                request, levels.get_level_profile(10), make_settings(), candidates, (4, 4)
            )
        messages = fake.calls[0][1]["json"]["messages"]
        combined = "\n".join(m["content"] for m in messages)
        self.assertIn("9×9", combined)
        self.assertIn("0 基", combined)
        self.assertIn("白方", combined)
        self.assertIn("10级", combined)
        self.assertIn(levels.get_level_profile(10).strategy, combined)
        self.assertIn("(4,5)", combined, "候选点列表应包含合法落点坐标")

    async def test_top_k_candidates_limited_by_profile(self):
        fake = FakeAsyncClient(responses=[FakeResponse(payload=chat_content(ok_text(4, 5)))])
        request = make_request()
        candidates = heuristic.generate_candidates(request.board, 9, gr.WHITE)
        with patch_client(fake):
            await llm.request_llm_move(
                request, levels.get_level_profile(10), make_settings(), candidates, (4, 4)
            )
        combined = fake.calls[0][1]["json"]["messages"][1]["content"]
        # 10 级 top_k=20，全局预算 30：候选行数应为 20。
        candidate_lines = [line for line in combined.splitlines() if line.startswith("(")]
        self.assertEqual(len(candidate_lines), 20)

    async def test_markdown_fenced_json_parsed(self):
        text = "```json\n" + ok_text(3, 3, "占据要点") + "\n```"
        fake = FakeAsyncClient(responses=[FakeResponse(payload=chat_content(text))])
        request = make_request()
        candidates = heuristic.generate_candidates(request.board, 9, gr.WHITE)
        with patch_client(fake):
            move, _ = await llm.request_llm_move(
                request, levels.get_level_profile(1), make_settings(), candidates, (4, 4)
            )
        self.assertEqual(move, (3, 3))

    async def test_retry_once_then_success(self):
        fake = FakeAsyncClient(
            responses=[FakeResponse(status_code=500), FakeResponse(payload=chat_content(ok_text(4, 5)))]
        )
        request = make_request()
        candidates = heuristic.generate_candidates(request.board, 9, gr.WHITE)
        with patch_client(fake):
            move, _ = await llm.request_llm_move(
                request, levels.get_level_profile(5), make_settings(), candidates, (4, 4)
            )
        self.assertEqual(move, (4, 5))
        self.assertEqual(len(fake.calls), 2, "失败后应重试一次")

    async def test_timeout_retries_then_raises(self):
        fake = FakeAsyncClient(exception=httpx.TimeoutException("timed out"))
        request = make_request()
        candidates = heuristic.generate_candidates(request.board, 9, gr.WHITE)
        with patch_client(fake):
            with self.assertRaises(llm.LlmError) as ctx:
                await llm.request_llm_move(
                    request, levels.get_level_profile(5), make_settings(), candidates, (4, 4)
                )
        self.assertEqual(len(fake.calls), 2, "max_retries=1 时共尝试 2 次")
        self.assertIn("Timeout", str(ctx.exception))

    async def test_network_error_raises_llm_error(self):
        for exception in (httpx.ConnectError("refused"), httpx.ReadError("reset")):
            fake = FakeAsyncClient(exception=exception)
            request = make_request()
            candidates = heuristic.generate_candidates(request.board, 9, gr.WHITE)
            with patch_client(fake):
                with self.assertRaises(llm.LlmError):
                    await llm.request_llm_move(
                        request, levels.get_level_profile(5), make_settings(max_retries=0),
                        candidates, (4, 4),
                    )

    async def test_http_error_no_retry_when_retries_zero(self):
        fake = FakeAsyncClient(responses=[FakeResponse(status_code=429)])
        request = make_request()
        candidates = heuristic.generate_candidates(request.board, 9, gr.WHITE)
        with patch_client(fake):
            with self.assertRaises(llm.LlmError) as ctx:
                await llm.request_llm_move(
                    request, levels.get_level_profile(5), make_settings(max_retries=0),
                    candidates, (4, 4),
                )
        self.assertEqual(len(fake.calls), 1)
        self.assertIn("429", str(ctx.exception))

    async def _assert_parse_failure(self, text: str, board=None):
        fake = FakeAsyncClient(responses=[FakeResponse(payload=chat_content(text))])
        request = make_request(board)
        candidates = heuristic.generate_candidates(request.board, 9, gr.WHITE)
        with patch_client(fake):
            with self.assertRaises(llm.LlmError):
                await llm.request_llm_move(
                    request, levels.get_level_profile(5), make_settings(max_retries=0),
                    candidates, (4, 4),
                )

    async def test_non_json_content_rejected(self):
        await self._assert_parse_failure("我觉得应该下在天元附近。")

    async def test_empty_content_rejected(self):
        await self._assert_parse_failure("")

    async def test_missing_move_field_rejected(self):
        await self._assert_parse_failure('{"reason":"没有落点"}')

    async def test_wrong_move_type_rejected(self):
        await self._assert_parse_failure('{"move":"R16","reason":"字母坐标"}')
        await self._assert_parse_failure('{"move":[3,3],"reason":"数组坐标"}')

    async def test_non_integer_coordinates_rejected(self):
        await self._assert_parse_failure('{"move":{"row":"4","col":5},"reason":"字符串"}')
        await self._assert_parse_failure('{"move":{"row":4.5,"col":5},"reason":"浮点"}')

    async def test_out_of_bounds_coordinates_rejected(self):
        await self._assert_parse_failure('{"move":{"row":9,"col":0},"reason":"越界"}')
        await self._assert_parse_failure('{"move":{"row":-1,"col":0},"reason":"负数"}')

    async def test_occupied_coordinates_rejected(self):
        # 黑棋在 (4,4)，模型返回占用点应被规则预校验拒绝。
        await self._assert_parse_failure(ok_text(4, 4))

    async def test_model_pass_with_candidates_rejected(self):
        await self._assert_parse_failure('{"move":"pass","reason":"无合适落点"}')

    async def test_response_structure_errors_rejected(self):
        # choices 缺失 / content 非 JSON 体 / 空对象。
        for payload in ({}, {"choices": []}, {"choices": [{"message": {}}]}):
            fake = FakeAsyncClient(responses=[FakeResponse(payload=payload)])
            request = make_request()
            candidates = heuristic.generate_candidates(request.board, 9, gr.WHITE)
            with patch_client(fake):
                with self.assertRaises(llm.LlmError):
                    await llm.request_llm_move(
                        request, levels.get_level_profile(5), make_settings(max_retries=0),
                        candidates, (4, 4),
                    )

    async def test_error_message_never_contains_secret(self):
        fake = FakeAsyncClient(exception=httpx.ConnectError("refused"))
        request = make_request()
        candidates = heuristic.generate_candidates(request.board, 9, gr.WHITE)
        with patch_client(fake):
            with self.assertRaises(llm.LlmError) as ctx:
                await llm.request_llm_move(
                    request, levels.get_level_profile(5), make_settings(), candidates, (4, 4)
                )
        self.assertNotIn(TEST_KEY, str(ctx.exception))
        self.assertNotIn("Bearer", str(ctx.exception))

    async def test_reason_fallback_and_truncation(self):
        # 缺 reason 时使用默认值；超长 reason 被截断。
        text = '{"move":{"row":4,"col":5}}'
        parsed, reason = llm.parse_llm_reply(text, 9)
        self.assertEqual(parsed, (4, 5))
        self.assertEqual(reason, "模型建议")
        long_reason = "超" * 200
        parsed, reason = llm.parse_llm_reply(
            '{"move":"pass","reason":"%s"}' % long_reason, 9
        )
        self.assertEqual(parsed, "pass")
        self.assertLessEqual(len(reason), llm.MAX_REASON_LENGTH)


class EngineLlmIntegrationTests(unittest.TestCase):
    """引擎级集成：模型优先、失败降级、无密钥禁用、密钥不泄露。"""

    def _client_with_llm(self, fake: FakeAsyncClient, **env_overrides):
        env = {"DEEPSEEK_API_KEY": TEST_KEY, "DEEPSEEK_RETRY_BACKOFF_SECONDS": "0"}
        env.update(env_overrides)
        patcher = patch_client(fake)
        patcher.start()
        self.addCleanup(patcher.stop)
        return build_client(self, **env)

    def _payload(self, level=5):
        board = empty_board()
        place(board, [(4, 4)], gr.BLACK)
        return {
            "board": board, "size": 9, "level": level, "moveNumber": 1,
            "lastMove": {"row": 4, "col": 4}, "previousBoard": None, "consecutivePasses": 0,
        }

    def test_engine_uses_llm_when_model_succeeds(self):
        fake = FakeAsyncClient(responses=[FakeResponse(payload=chat_content(ok_text(4, 5, "贴身应对")))])
        client = self._client_with_llm(fake)
        response = client.post("/api/ai-move", json=self._payload())
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["engine"], "llm")
        self.assertEqual(data["move"], {"row": 4, "col": 5})
        self.assertEqual(data["reason"], "贴身应对")
        self.assertGreaterEqual(data["elapsedMs"], 0)
        self.assertEqual(len(fake.calls), 1)
        # 密钥只进入请求头，不进入响应。
        self.assertNotIn(TEST_KEY, response.text)

    def test_engine_falls_back_on_model_timeout(self):
        fake = FakeAsyncClient(exception=httpx.TimeoutException("timed out"))
        client = self._client_with_llm(fake)
        board = empty_board()
        place(board, [(4, 4)], gr.BLACK)
        response = client.post("/api/ai-move", json=self._payload())
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["engine"], "heuristic")
        move = data["move"]
        self.assertTrue(gr.simulate_move(board, 9, move["row"], move["col"], gr.WHITE).ok)
        # 重试后仍失败：共调用 2 次。
        self.assertEqual(len(fake.calls), 2)
        self.assertNotIn(TEST_KEY, response.text)

    def test_engine_falls_back_after_retry_exhausted(self):
        fake = FakeAsyncClient(
            responses=[FakeResponse(status_code=500), FakeResponse(status_code=503)]
        )
        client = self._client_with_llm(fake)
        response = client.post("/api/ai-move", json=self._payload())
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["engine"], "heuristic")
        self.assertEqual(len(fake.calls), 2)

    def test_engine_illegal_model_move_falls_back(self):
        # 模型始终返回占用点 (4,4)：重试一次后仍非法 → 降级启发式。
        fake = FakeAsyncClient(
            responses=[
                FakeResponse(payload=chat_content(ok_text(4, 4))),
                FakeResponse(payload=chat_content(ok_text(4, 4))),
            ]
        )
        client = self._client_with_llm(fake)
        response = client.post("/api/ai-move", json=self._payload())
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["engine"], "heuristic")
        self.assertNotEqual(data["move"], {"row": 4, "col": 4})

    def test_engine_llm_disabled_without_key(self):
        class ExplodingClient(FakeAsyncClient):
            async def post(self, url, **kwargs):
                raise AssertionError("无密钥时不得调用模型")

        fake = ExplodingClient()
        client = self._client_with_llm(fake, DEEPSEEK_API_KEY="")
        response = client.post("/api/ai-move", json=self._payload())
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["engine"], "heuristic")
        # 健康检查仍为 llm=false。
        health = client.get("/api/health").json()
        self.assertFalse(health["llm"])

    def test_engine_full_board_skips_llm_and_passes(self):
        # 满盘无合法候选：即使模型可用也不应调用，直接启发式 pass。
        class ExplodingClient(FakeAsyncClient):
            async def post(self, url, **kwargs):
                raise AssertionError("无合法候选时不得调用模型")

        fake = ExplodingClient()
        client = self._client_with_llm(fake)
        board = [[gr.BLACK] * 9 for _ in range(9)]
        payload = {
            "board": board, "size": 9, "level": 5, "moveNumber": 81,
            "lastMove": {"row": 8, "col": 8}, "previousBoard": None, "consecutivePasses": 0,
        }
        response = client.post("/api/ai-move", json=payload)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["move"], "pass")
        self.assertEqual(data["engine"], "heuristic")

    def test_engine_level_shown_in_heuristic_reason(self):
        fake = FakeAsyncClient(exception=httpx.ConnectError("refused"))
        client = self._client_with_llm(fake, DEEPSEEK_MAX_RETRIES="0")
        response = client.post("/api/ai-move", json=self._payload(level=7))
        data = response.json()
        self.assertEqual(data["engine"], "heuristic")
        self.assertIn("7级", data["reason"])


if __name__ == "__main__":
    unittest.main()
