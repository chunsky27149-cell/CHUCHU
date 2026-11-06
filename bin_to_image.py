
from pathlib import Path
import struct
import zlib
import cv2
import numpy as np


# ============================================================
# 基本設定
# ============================================================

BASE_DIR = Path(__file__).resolve().parent

MAGIC = 0x4652414D

GRAY8 = 1
BGR24 = 2
RGB24 = 3

HEADER_SIZE = 19
CRC_SIZE = 4


# ============================================================
# BIN 封包轉換圖片
# ============================================================

def convert_bin_to_image(filename, output_name):

    packet_path = BASE_DIR / filename
    output_path = BASE_DIR / output_name

    print("\n================================")
    print("開始處理：", filename)
    print("================================")

    # --------------------------------------------------------
    # 1. 檢查檔案
    # --------------------------------------------------------

    if not packet_path.exists():
        raise FileNotFoundError(
            f"找不到封包檔案：{packet_path}"
        )

    data = packet_path.read_bytes()

    if len(data) < HEADER_SIZE + CRC_SIZE:
        raise ValueError("封包大小不足")

    # --------------------------------------------------------
    # 2. 解析 Header
    # --------------------------------------------------------

    header = struct.unpack(
        "<IBBIHHBI",
        data[:HEADER_SIZE]
    )

    (
        magic,
        version,
        packet_type,
        frame_id,
        width,
        height,
        pixel_format,
        payload_size
    ) = header

    print("MAGIC：", hex(magic))
    print("Version：", version)
    print("Packet Type：", packet_type)
    print("Frame ID：", frame_id)
    print("Width：", width)
    print("Height：", height)
    print("Pixel Format：", pixel_format)
    print("Payload Size：", payload_size)

    # --------------------------------------------------------
    # 3. 檢查 Header
    # --------------------------------------------------------

    if magic != MAGIC:
        raise ValueError("MAGIC 錯誤")

    if version != 1:
        raise ValueError("Version 不支援")

    if packet_type != 1:
        raise ValueError("不是 FRAME 封包")

    if width == 0 or height == 0:
        raise ValueError("圖片尺寸錯誤")

    # --------------------------------------------------------
    # 4. 檢查封包總長度
    # --------------------------------------------------------

    expected_size = HEADER_SIZE + payload_size + CRC_SIZE

    if len(data) != expected_size:
        raise ValueError(
            f"封包長度錯誤：預期 {expected_size}，"
            f"實際 {len(data)}"
        )

    # --------------------------------------------------------
    # 5. 取得 Payload
    # --------------------------------------------------------

    payload_start = HEADER_SIZE
    payload_end = HEADER_SIZE + payload_size

    payload = data[payload_start:payload_end]

    # --------------------------------------------------------
    # 6. CRC32 驗證
    # --------------------------------------------------------

    stored_crc = struct.unpack(
        "<I",
        data[payload_end:payload_end + CRC_SIZE]
    )[0]

    calculated_crc = zlib.crc32(payload) & 0xFFFFFFFF

    print("Stored CRC32：", hex(stored_crc))
    print("Calculated CRC32：", hex(calculated_crc))

    if stored_crc != calculated_crc:
        raise ValueError("CRC32 驗證失敗")

    print("CRC32：PASS")

    # --------------------------------------------------------
    # 7. 檢查 Pixel Format 與 Payload 大小
    # --------------------------------------------------------

    if pixel_format == GRAY8:

        expected_payload = width * height

        if payload_size != expected_payload:
            raise ValueError("GRAY8 Payload 大小錯誤")

        image = np.frombuffer(
            payload,
            dtype=np.uint8
        ).reshape(height, width)

        print("圖片格式：GRAY8")

    elif pixel_format == BGR24:

        expected_payload = width * height * 3

        if payload_size != expected_payload:
            raise ValueError("BGR24 Payload 大小錯誤")

        image = np.frombuffer(
            payload,
            dtype=np.uint8
        ).reshape(height, width, 3)

        print("圖片格式：BGR24")

    elif pixel_format == RGB24:

        expected_payload = width * height * 3

        if payload_size != expected_payload:
            raise ValueError("RGB24 Payload 大小錯誤")

        image = np.frombuffer(
            payload,
            dtype=np.uint8
        ).reshape(height, width, 3)

        # RGB 轉成 OpenCV 使用的 BGR
        image = cv2.cvtColor(
            image,
            cv2.COLOR_RGB2BGR
        )

        print("圖片格式：RGB24")

    else:
        raise ValueError(
            f"不支援的 Pixel Format：{pixel_format}"
        )

    # --------------------------------------------------------
    # 8. 儲存 PNG 圖片
    # --------------------------------------------------------

    success = cv2.imwrite(
        str(output_path),
        image
    )

    if not success:
        raise RuntimeError("PNG 圖片儲存失敗")

    print("--------------------------------")
    print("圖片產生成功！")
    print("輸出位置：", output_path)
    print("圖片尺寸：", width, "x", height)
    print("================================")


# ============================================================
# 主程式：產生彩色與灰階圖片
# ============================================================

if __name__ == "__main__":

    print("===== FPGA BIN 封包圖片還原程式 =====")

    # 彩色圖片
    convert_bin_to_image(
        "color_packet.bin",
        "color_output.png"
    )

    # 灰階圖片
    convert_bin_to_image(
        "gray_packet.bin",
        "gray_output.png"
    )

    print("\n===== 全部圖片產生完成！ =====")
