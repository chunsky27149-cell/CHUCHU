from pathlib import Path
import sys

# 將 D:\chuchu 加入 Python 模組搜尋路徑
PROJECT_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_DIR))

from protocol import parse_frame_packet

# Verilog 產生的灰階封包
packet_path = Path(r"D:\FPGA_FramePacket\gray_packet.bin")

if not packet_path.exists():
    raise FileNotFoundError(f"找不到封包：{packet_path}")

# 讀取封包
packet = packet_path.read_bytes()

print("封包大小：", len(packet), "Bytes")

# 解析封包
result = parse_frame_packet(packet)

print("解析結果：")
print(result)

print("FPGA 灰階封包驗證成功！")