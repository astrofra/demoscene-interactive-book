import os
from PIL import Image
import math

def pack_images_to_texture(input_folder, output_file, image_size, texture_size):
    # List all images in the input folder
    images = sorted([f for f in os.listdir(input_folder) if f.endswith(".png")])
    
    if not images:
        print("No images found in the folder.")
        return

    # Calculate number of rows and columns for the texture
    cols = texture_size[0] // image_size[0]
    rows = texture_size[1] // image_size[1]
    max_images = cols * rows

    if len(images) > max_images:
        print(f"Warning: Only the first {max_images} images will fit in the texture.")

    # Create a blank canvas for the texture
    texture = Image.new("RGBA", texture_size, (0, 0, 0, 0))

    # Iterate through images and paste them into the texture
    for index, image_file in enumerate(images):
        if index >= max_images:
            break

        # Load the image
        img = Image.open(os.path.join(input_folder, image_file))
        
        # Resize the image using nearest neighbor
        img_resized = img.resize(image_size, Image.FILTERED)

        # Calculate the position in the texture
        x = (index % cols) * image_size[0]
        y = (index // cols) * image_size[1]

        # Paste the resized image into the texture
        texture.paste(img_resized, (x, y))

    # Save the resulting texture
    texture.save(output_file)
    print(f"Texture saved as {output_file}")

if __name__ == "__main__":
    image_size = (512, 256)  # Desired size of each image
    texture_size = (4096, 4096)  # Size of the output texture

    # pack_images_to_texture("bonjour_madame", "../../app/assets/common/image-sequences/bonjour_madame_seq.png", image_size, texture_size)
    # pack_images_to_texture("couloir-14", "../../app/assets/common/image-sequences/couloir-14_seq.png", image_size, texture_size)
    pack_images_to_texture("caillou", "../../app/assets/common/image-sequences/caillou_seq.png", image_size, texture_size)
    # pack_images_to_texture("oeil-du-cyclone", "../../app/assets/common/image-sequences/oeil-du-cyclone_seq.png", image_size, texture_size)
