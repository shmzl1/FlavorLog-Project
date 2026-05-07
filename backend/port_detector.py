# backend/port_detector.py

import socket

class NetworkDetector:
    """
    底层网络端口连通性探测器。

    架构作用：
    当应用层的数据库驱动 (如 psycopg2) 因为跨平台编码问题崩溃、无法提供有效报错时，
    我们需要降级到 OS 网络层 (TCP/IP) 进行纯粹的连通性诊断。
    本类彻底脱离了任何第三方库，使用 Python 内置的 socket 直接向目标 IP 和端口发起 TCP 握手。
    这能帮我们 100% 确认 Docker 的 5432 端口到底有没有映射到 Windows 物理机上。
    """

    def __init__(self, host: str, port: int):
        """
        初始化探测器参数。

        Args:
            host (str): 目标主机 IP (例如 '127.0.0.1')。
            port (int): 目标监听端口 (例如 5432)。
        """
        self.host = host
        self.port = port

    def check_tcp_port(self) -> None:
        """
        执行 TCP 握手测试。

        业务逻辑：
        创建一个基于 IPv4 和 TCP 协议的套接字，设置 3 秒超时时间，避免假死。
        尝试连接目标端口：
        - 如果 `connect_ex` 返回 0，说明成功握手，端口绝对是畅通的。
        - 如果非 0，说明被防火墙拦截、端口被占用或 Docker 根本没开启监听。
        """
        print(f"🕵️ 正在启动底层网络探测...")
        print(f"📡 目标地址: {self.host}:{self.port}")
        
        # 创建一个 TCP Socket
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(3.0)  # 3秒超时
        
        try:
            # connect_ex 成功返回 0，失败返回系统的错误码
            result = sock.connect_ex((self.host, self.port))
            if result == 0:
                print("\n✅ 端口检测通过！TCP 连接已建立。")
                print("💡 结论：Docker 端口映射完全正常，之前连不上可能是账号密码配错了。")
            else:
                print(f"\n❌ 端口检测失败！错误码: {result}")
                print("💡 结论：Windows 根本找不到 5432 端口！请重点检查 Docker 状态！")
                print("👉 可能原因 1：Docker 容器内部启动失败，正在不断重启（假绿灯）。")
                print("👉 可能原因 2：你电脑本地偷偷运行了别的 PostgreSQL，端口冲突导致 Docker 映射失效。")
        finally:
            # 无论成功失败，都必须释放 Socket 资源
            sock.close()


if __name__ == "__main__":
    # 检测本地 127.0.0.1 的 5432 端口
    detector = NetworkDetector(host="127.0.0.1", port=5432)
    detector.check_tcp_port()