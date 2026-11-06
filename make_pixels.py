
import cv2

# 讀取 FPGA 專案中的圖片
image = cv2.imread(r"D:\FPGA_FramePacket\boss.jpg")

if image is None:
    raise FileNotFoundError("找不到 boss.jpg")

# 調整成 64 x 64
image = cv2.resize(image, (64, 64))

# OpenCV 預設是 BGR，轉成 RGB
image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

# 輸出 pixels.txt
output_path = r"D:\FPGA_FramePacket\pixels.txt"

with open(output_path, "w") as file:
    file.write("64 64\n")

    for row in image:
        for pixel in row:
            r, g, b = pixel
            file.write(f"{r} {g} {b}\n")

print("pixels.txt 建立完成！")
print("圖片尺寸：64 x 64")
print("RGB 像素數量：4096")
