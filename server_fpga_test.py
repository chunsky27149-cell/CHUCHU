
import sys
import threading
from pathlib import Path

# 加入 D:\chuchu
PROJECT_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_DIR))

from transport_fpga import TCPTransport


# ===== 區域網路接收設定 =====
# 監聽所有網路介面
SERVER_IP = "0.0.0.0"

COLOR_PORT = 5000
GRAY_PORT = 5001

# 接收檔案儲存位置
SAVE_DIR = Path(__file__).resolve().parent / "fpga_received"
SAVE_DIR.mkdir(exist_ok=True)


def receive_packet(ip, port, label, filename):
    server = TCPTransport(ip, port)
    client = None

    try:
        print(f"[{label}] 等待連線：{ip}:{port}")

        # 等待傳送端連線
        client = server.listen()

        print(f"[{label}] 已有電腦連線！")
        
        # 接收 19 Bytes Header
        header = client.receive_exactly(19)

        # 取得 Payload 大小
        payload_size = int.from_bytes(
            header[15:19],
            byteorder="little"
        )

        # 接收 Payload + 4 Bytes CRC
        remaining = client.receive_exactly(payload_size + 4)

        # 組合完整封包
        packet = header + remaining

        # 儲存封包
        output_path = SAVE_DIR / filename
        output_path.write_bytes(packet)

        print(f"[{label}] 接收成功！")
        print(f"[{label}] 封包大小：{len(packet)} Bytes")
        print(f"[{label}] 儲存位置：{output_path}")

    except Exception as e:
        print(f"[{label}] 接收失敗：{e}")

    finally:
        if client is not None:
            client.close()

        server.close()


def main():
    print("===== FPGA 區域網路 TCP 接收測試 =====")
    print(f"彩色監聽：{SERVER_IP}:{COLOR_PORT}")
    print(f"灰階監聽：{SERVER_IP}:{GRAY_PORT}")
    print()

    color_thread = threading.Thread(
        target=receive_packet,
        args=(
            SERVER_IP,
            COLOR_PORT,
            "彩色",
            "color_received.bin"
        )
    )

    gray_thread = threading.Thread(
        target=receive_packet,
        args=(
            SERVER_IP,
            GRAY_PORT,
            "灰階",
            "gray_received.bin"
        )
    )

    color_thread.start()
    gray_thread.start()

    color_thread.join()
    gray_thread.join()

    print("\n兩種 FPGA 封包接收完成！")


if __name__ == "__main__":
    main()
