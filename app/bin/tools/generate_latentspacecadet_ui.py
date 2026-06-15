import re
import os
from PIL import Image, ImageDraw, ImageFont

def extract_titles(lua_file):
    with open(lua_file, 'r', encoding='utf-8') as file:
        lua_content = file.read()
    
    # Regular expression to extract the title from each entry
    pattern = re.compile(r'title\s*=\s*"([^"]+)"')
    return re.findall(pattern, lua_content)

def create_image(text, filename, font_path):
    # Load font
    font_size = 40  # Fixed font size
    font = ImageFont.truetype(font_path, font_size)
    
    # Define image dimensions
    image_width = 2048  # Fixed width
    image_height = 128  # Fixed height
    temp_image = Image.new('RGBA', (image_width, 100), (255, 255, 255, 0))  # Temp image to measure text
    draw = ImageDraw.Draw(temp_image)
    
    # Calculate text height
    bbox = font.getbbox(text)
    text_height = bbox[3] - bbox[1]
    
    # Create final image
    image = Image.new('RGBA', (image_width, image_height), (255, 255, 255, 0))  # Black background
    draw = ImageDraw.Draw(image)
    
    # Draw text centered vertically and aligned left
    draw.text((10, (image_height - text_height) // 2), text, font=font, fill="white")  # 10px padding on left
    
    # Save the image
    image.save(filename)

def main():
    lua_filename = '../../projects/latent_space_cadet/latent_images.lua'
    font_path = '../../../work/fonts/Barlow-Medium.ttf'  # Update with the correct path to your font
    output_directory = '../../assets/projects/latent_space_cadet/images/'  # Directory to save generated images
    
    # Ensure output directory exists
    os.makedirs(output_directory, exist_ok=True)
    
    # Extract titles from Lua file
    titles = extract_titles(lua_filename)
    
    for idx, title in enumerate(titles):
        # Create a filename for each title image
        output_filename = os.path.join(output_directory, "%02d_title.png" % (idx))
        create_image(title, output_filename, font_path)
        print(f"Generated image for '{title}' as '{output_filename}'")

if __name__ == '__main__':
    main()
