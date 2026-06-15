import os
from PIL import Image, ImageDraw, ImageFont

def create_image(text, filename, font_path):
    # Load font
    font_size = 80  # Adjusted font size for smaller images
    font = ImageFont.truetype(font_path, font_size)
    
    # Create an image with a fixed width and height
    image_width = 256
    image_height = 128
    image = Image.new('RGBA', (image_width, image_height), (255, 255, 255, 0))
    draw = ImageDraw.Draw(image)
    
    # Get the bounding box of the text
    bbox = font.getbbox(text)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    # Calculate text position to center vertically and justify left
    text_x = (image_width - text_width) // 2  # Center h
    text_y = (image_height - text_height) // 5  # Center v
    
    # Draw text left-justified
    draw.text((text_x, text_y), text, font=font, fill="white")
    
    # Save the image
    image.save(filename)

def main():
    # Font path and strings to render
    font_path = '../../../work/fonts/Barlow-Medium.ttf'  # Update with the correct path to your font
    strings = {
        "size_720p": "720p",
        "size_1080p": "1080p",
        "at": "|",
        "framerate_24fps": "24fps",
        "framerate_25fps": "25fps",
        "framerate_30fps": "30fps",
        "framerate_50fps": "50fps",
        "framerate_60fps": "60fps",
    }
    
    # Create image for each string
    for key, text in strings.items():
        output_filename = f"{key}.png"
        create_image(text, os.path.join('../../assets/common/', 'video_player_' + output_filename), font_path)
        print(f"Generated image for '{text}' as '{output_filename}'")

if __name__ == '__main__':
    main()
