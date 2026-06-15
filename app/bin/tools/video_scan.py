import os
from moviepy.editor import VideoFileClip

# Path to the folder containing the videos
video_folder = "../../assets/videos"
# Path to the Lua output file
output_lua_file = "../../video_data.lua"

# Dictionary to store video data
video_data = {}

# Iterate over the folder to find .MP4 files
for filename in os.listdir(video_folder):
    if filename.lower().endswith(".mp4"):
        full_path = os.path.join(video_folder, filename)
        try:
            # Open the video file
            with VideoFileClip(full_path) as video:
                # Extract video properties
                duration = video.duration
                width, height = video.size
                fps = video.fps

            # Add the data to the dictionary
            video_data[filename] = {
                "duration": duration,
                "width": width,
                "height": height,
                "fps": fps,
            }

            print(f"Processed {filename}: Duration = {duration} seconds, "
                  f"Resolution = {width}x{height}, FPS = {fps}")
        except Exception as e:
            print(f"Error processing file {filename}: {e}")

# Write the data to a Lua file
with open(output_lua_file, 'w') as lua_file:
    lua_file.write("video_metadata = {\n")
    for video_name, data in video_data.items():
        duration = data["duration"]
        width = data["width"]
        height = data["height"]
        fps = data["fps"]
        lua_file.write(f"\t['{video_name}'] = {{ duration = {duration}, "
                       f"width = {width}, height = {height}, fps = {fps} }},\n")
    lua_file.write("}\n")

print("File with video_data table has been written to", output_lua_file)
