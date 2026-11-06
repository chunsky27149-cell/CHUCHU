
import socket


class TCPTransport:
    """
    FPGA 專用 TCP 通訊模組。
    支援 Client、Server、完整資料傳送與接收。
    """

    def __init__(self, host, port, timeout=None):
        self.host = host
        self.port = port
        self.timeout = timeout
        self.sock = None

    # ================= Client =================

    def connect(self):
        if self.sock is not None:
            raise RuntimeError("Socket 已經建立")

        self.sock = socket.socket(
            socket.AF_INET,
            socket.SOCK_STREAM
        )

        if self.timeout is not None:
            self.sock.settimeout(self.timeout)

        try:
            self.sock.connect((self.host, self.port))
        except Exception:
            self.close()
            raise

    # ================= Server =================

    def listen(self, backlog=1):
        if self.sock is not None:
            raise RuntimeError("Socket 已經建立")

        self.sock = socket.socket(
            socket.AF_INET,
            socket.SOCK_STREAM
        )

        self.sock.setsockopt(
            socket.SOL_SOCKET,
            socket.SO_REUSEADDR,
            1
        )

        self.sock.bind((self.host, self.port))
        self.sock.listen(backlog)

        print(
            f"[TCP Server] 等待連線 "
            f"{self.host}:{self.port}"
        )

        client_socket, address = self.sock.accept()

        print(f"[TCP Server] Client 已連線：{address}")

        client = TCPTransport(
            self.host,
            self.port,
            self.timeout
        )

        client.sock = client_socket

        return client

    # ================= Send =================

    def send(self, data):
        if self.sock is None:
            raise RuntimeError("尚未建立 Socket")

        if not isinstance(data, bytes):
            raise TypeError("data 必須是 bytes")

        self.sock.sendall(data)

    # ================= Receive =================

    def receive_exactly(self, size):
        if self.sock is None:
            raise RuntimeError("尚未建立 Socket")

        if size < 0:
            raise ValueError("接收大小不能小於 0")

        data = bytearray()

        while len(data) < size:
            chunk = self.sock.recv(size - len(data))

            if not chunk:
                raise ConnectionError(
                    f"TCP 連線中斷，只收到 "
                    f"{len(data)}/{size} bytes"
                )

            data.extend(chunk)

        return bytes(data)

    # ================= Close =================

    def close(self):
        if self.sock is not None:
            try:
                self.sock.shutdown(socket.SHUT_RDWR)
            except OSError:
                pass

            self.sock.close()
            self.sock = None
