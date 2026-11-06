
import sys
import threading
from pathlib import Path

# 加入 D:\chuchu，讓 Python 找得到 transport.py
PROJECT_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_DIR))

from transport_fpga import TCPTransport


# ===== FPGA 封包路徑 =====
COLOR_PACKET = Path(r"D:\chuchu\FPGA_tools\color_packet.bin")
GRAY_PACKET = Path(r"D:\chuchu\FPGA_tools\gray_packet.bin")


# ===== 本機接收端設定 =====
COLOR_IP = "192.168.1.4"
GRAY_IP = "192.168.1.3"

COLOR_PORT = 5000
GRAY_PORT = 5001


def send_packet(ip, port, packet_path, label):
    transport = TCPTransport(ip, port)

    try:
        # 確認封包檔案存在
        if not packet_path.is_file():
            raise FileNotFoundError(packet_path)

        # 讀取 FPGA 已經產生的完整封包
        packet = packet_path.read_bytes()

        if not packet:
            raise ValueError("封包檔案是空的")

        # 建立 TCP 連線
        transport.connect()

        print(f"[{label}] 已連線到 {ip}:{port}")

        # 傳送原始 BIN 資料
        transport.send(packet)

        print(
            f"[{label}] 已傳送 {packet_path.name} "
            f"（{len(packet)} bytes）"
        )

    except Exception as e:
        print(f"[{label}] 傳送失敗：{e}")

    finally:
        transport.close()
        print(f"[{label}] 傳送結束")


def main():
    print("===== FPGA 區域網路 TCP 傳送測試 =====")

    color_thread = threading.Thread(
        target=send_packet,
        args=(
            COLOR_IP,
            COLOR_PORT,
            COLOR_PACKET,
            "彩色"
        )
    )

    gray_thread = threading.Thread(
        target=send_packet,
        args=(
            GRAY_IP,
            GRAY_PORT,
            GRAY_PACKET,
            "灰階"
        )
    )

    # 同時傳送彩色與灰階封包
    color_thread.start()
    gray_thread.start()

    color_thread.join()
    gray_thread.join()

    print("\nFPGA 封包傳送程序結束！")


if __name__ == "__main__":
    main()
