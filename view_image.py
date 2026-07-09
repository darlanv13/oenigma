import sys
from PIL import Image

def get_image_info(path):
    try:
        with Image.open(path) as img:
            print(f"File: {path}")
            print(f"Format: {img.format}")
            print(f"Size: {img.size}")
            print(f"Mode: {img.mode}")
    except Exception as e:
        print(f"Error opening image: {e}")

get_image_info(sys.argv[1])
