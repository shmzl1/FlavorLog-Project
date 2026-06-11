import asyncio
import time
import httpx

BASE_URL = "http://127.0.0.1:8000/api/v1"

# 测试账号
ACCOUNT = "redis@qq.com"
PASSWORD = "123456"

TOTAL_REQUESTS = 1000
CONCURRENCY = 100


async def login(client: httpx.AsyncClient) -> str:
    """
    自动登录获取 JWT
    """

    login_resp = await client.post(
        f"{BASE_URL}/auth/login",
        json={
            "account": ACCOUNT,
            "password": PASSWORD
        }
    )

    login_resp.raise_for_status()

    result = login_resp.json()

    token = result["data"]["access_token"]

    print("✅ 登录成功")
    return token


async def fetch_me(
    client: httpx.AsyncClient,
    headers: dict
):
    start = time.perf_counter()

    try:
        r = await client.get(
            f"{BASE_URL}/auth/me",
            headers=headers
        )

        elapsed = time.perf_counter() - start

        return r.status_code, elapsed

    except Exception:
        elapsed = time.perf_counter() - start
        return 500, elapsed


async def worker(
    semaphore,
    client,
    headers
):
    async with semaphore:
        return await fetch_me(
            client,
            headers
        )


async def main():

    async with httpx.AsyncClient(timeout=30.0) as client:

        # 1. 自动登录
        token = await login(client)

        headers = {
            "Authorization": f"Bearer {token}"
        }

        semaphore = asyncio.Semaphore(CONCURRENCY)

        print(
            f"\n 开始测试redis功能 "
            f"({TOTAL_REQUESTS} 请求, "
            f"{CONCURRENCY} 并发)\n"
        )

        start_time = time.perf_counter()

        tasks = [
            worker(
                semaphore,
                client,
                headers
            )
            for _ in range(TOTAL_REQUESTS)
        ]

        results = await asyncio.gather(*tasks)

        total_time = (
            time.perf_counter()
            - start_time
        )

    success = sum(
        1 for code, _
        in results
        if code == 200
    )

    failed = TOTAL_REQUESTS - success

    avg_time = (
        sum(t for _, t in results)
        / len(results)
    )

    qps = TOTAL_REQUESTS / total_time

    print("=" * 50)
    print("Redis redis测试结果")
    print("=" * 50)
    print(f"总请求数     : {TOTAL_REQUESTS}")
    print(f"成功请求数   : {success}")
    print(f"失败请求数   : {failed}")
    print(f"总耗时       : {total_time:.2f}s")
    print(f"平均响应时间 : {avg_time:.4f}s")
    print(f"QPS          : {qps:.2f}")
    print("=" * 50)


if __name__ == "__main__":
    asyncio.run(main())