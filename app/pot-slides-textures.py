import argparse
import os
import glob
from PIL import Image
import numpy as np

def nearest_power_of_two(n):
    return 2**int(np.floor(np.log2(n)))

def parse_args():
    parser = argparse.ArgumentParser(
        description="Resize slide textures down to power-of-two dimensions."
    )
    parser.add_argument(
        "--all-textures",
        action="store_true",
        help="Process every PNG in assets/slides instead of only *photo*.png files.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be resized without modifying files.",
    )
    return parser.parse_args()

def optimize_images(all_textures=False, dry_run=False):
    image_dir = os.path.join("assets", "slides")
    glob_pattern = "*.png" if all_textures else "*photo*.png"
    pattern = os.path.join(image_dir, glob_pattern)
    image_paths = sorted(glob.glob(pattern))
    optimized_images = []
    unchanged_images = 0

    if not image_paths:
        print(f"No matching images found for pattern: {pattern}")
        return

    for file_path in image_paths:
        with Image.open(file_path) as img:
            width, height = img.size

            new_width = nearest_power_of_two(width)
            new_height = nearest_power_of_two(height)

            if (new_width, new_height) != (width, height):
                optimized_images.append((file_path, width, height, new_width, new_height))
                if not dry_run:
                    resized = img.resize((new_width, new_height), Image.LANCZOS)
                    resized.save(file_path)
            else:
                unchanged_images += 1

    print(f"Scanned {len(image_paths)} matching image(s).")
    if not optimized_images:
        print("No resize needed: all matching images already use power-of-two dimensions.")
        return

    print("Would resize:" if dry_run else "Resized:")
    for file_path, old_w, old_h, new_w, new_h in optimized_images:
        print(f"{file_path}: {old_w}x{old_h} -> {new_w}x{new_h}")
    print(f"Unchanged: {unchanged_images}")

if __name__ == "__main__":
    args = parse_args()
    optimize_images(all_textures=args.all_textures, dry_run=args.dry_run)
