import re
import os
from PIL import Image, ImageDraw, ImageFont

def extract_titles_and_refs(lua_file):
    with open(lua_file, 'r', encoding='utf-8') as file:
        lua_content = file.read()
    
    # Regular expression to find title and ref within the lua tables
    pattern = re.compile(r'\{type\s*=\s*action_type\.svid, ref\s*=\s*"([^"]+)",.*?title\s*=\s*"([^"]+)"\}', re.S)
    return re.findall(pattern, lua_content)

def create_image(text, filename, font_path):
    # Load font
    font_size = 80  # Fixed font size
    font = ImageFont.truetype(font_path, font_size)
    
    # Create an image with a fixed width and sufficient height
    image_width = 2048  # Fixed width for all images
    image_height = 128
    temp_image = Image.new('RGBA', (image_width, 100), (255, 255, 255, 0))  # Temp image to measure text
    draw = ImageDraw.Draw(temp_image)
    
    # Get the bounding box of the text to calculate height
    bbox = font.getbbox(text)
    text_height = bbox[3] - bbox[1]
    # image_height = text_height + 20  # Adding some padding
    
    # Create the final image with the correct dimensions
    image = Image.new('RGBA', (image_width, image_height), (255, 255, 255, 0))
    draw = ImageDraw.Draw(image)
    
    # Draw text left-justified
    draw.text((10, (image_height - text_height) // 5), text, font=font, fill="white")  # Start text 10 pixels from the left
    
    # Save the image
    image.save(filename)

def main():
    lua_filename = '../../presentation.lua'
    font_path = '../../../work/fonts/Barlow-Light.ttf'
    titles_refs = extract_titles_and_refs(lua_filename)
    
    for ref, title in titles_refs:
        # Extract filename from ref path
        output_filename = ref.split('/')[-1].replace('.mp4', '.png')
        create_image(title, os.path.join('../../assets/videos/', output_filename), font_path)
        print(f"Generated image for '{title}' as '{output_filename}'")

if __name__ == '__main__':
    main()
