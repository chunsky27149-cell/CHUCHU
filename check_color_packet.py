from pathlib import Path
import sys

PROJECT_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_DIR))

from protocol import parse_frame_packet

packet_path = Path(r"D:\chuchu\FPGA_tools\color_packet.bin")

if not packet_path.exists():
    raise FileNotFoundError(packet_path)

packet = packet_path.read_bytes()

print("封包大小：", len(packet), "Bytes")

result = parse_frame_packet(packet)

print("解析結果：")
print({
    key: value
    for key, value in result.items()
    if key != "payload"
})

if result["pixel_format"] == 3 and result["payload_size"] == 12288:
    print("FPGA 彩色封包驗證成功！")
else:
    print("彩色封包資料不符合預期！")