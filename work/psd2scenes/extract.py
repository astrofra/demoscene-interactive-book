from psd_tools import PSDImage
from PIL import Image
import numpy as np
import os
import json
import re

hg_to_assets_path = '../../app/assets/'
hg_from_assets_path = 'slides/'
output_path = os.path.join(hg_to_assets_path, hg_from_assets_path)
common_files = ["bg", "separator", "title_decoration", "page_square"]
slide_bg_color=(78/255.0, 81/255.0, 86/255.0)


def generate_meta_json(filename):
    # Define the JSON structure
    data = {
        "profiles": {
            "default": {
                "compression": "BC3",
                "wrap-U": "Clamp",
                "wrap-V": "Clamp"
            }
        }
    }
    
    # Create the .meta filename by appending ".meta" to the original filename
    meta_filename = f"{filename}.meta"
    
    # Write the JSON structure to the .meta file
    with open(meta_filename, "w") as f:
        json.dump(data, f, indent=4)

    print(f"Meta file created: {meta_filename}")


def clean_alpha(image: Image.Image, bg_color=(1.0, 1.0, 1.0)) -> Image.Image:
    """Clean alpha channel by setting RGB to background color where alpha is 0."""
    rgba = np.array(image, dtype=np.float32)  # Convert PIL.Image to NumPy array
    alpha = rgba[:, :, 3] / 255.0  # Normalize alpha channel (0 to 1)

    # Background color to replace RGB in fully transparent areas
    bg_r, bg_g, bg_b = bg_color

    # Set the RGB channels to background color where alpha is 0 or near 0
    near_zero_alpha = alpha < 1e-5  # Threshold for 'almost' transparent pixels
    rgba[near_zero_alpha, 0] = bg_r * 255  # Red
    rgba[near_zero_alpha, 1] = bg_g * 255  # Green
    rgba[near_zero_alpha, 2] = bg_b * 255  # Blue

    # Convert back to 8-bit integer format
    rgba = np.clip(rgba, 0, 255).astype(np.uint8)

    # Convert back to PIL.Image and return
    return Image.fromarray(rgba, 'RGBA')

# # Open the PNG image as a PIL.Image
# image = Image.open("input_image.png").convert("RGBA")

# # Apply premultiplied alpha transformation with a background color
# premultiplied_image = premultiply_alpha(image)

# # Save the result back as a PNG
# premultiplied_image.save("output_image.png", "PNG")


def extract_human_name(text):
    # Updated regex to account for potential spaces
    match = re.search(r"\(\s*'([^']*)'\s*", text)
    if match:
        return match.group(1)
    return None


def camel_to_snake(name):
    # Convert camelCase to snake_case by adding underscores before capital letters
    name = re.sub(r'(?<!^)(?=[A-Z])', '_', name)
    # Ensure the string is fully lowercase (since snake_case requires all lowercase)
    name = name.lower()
    # Replace any double underscores in case they appear due to pre-existing underscores
    name = re.sub(r'_+', '_', name)
    if name[0] == '_':
        name = name[1:]
    return name


def sanitize_filename(filename):
    return "".join(x for x in filename if x.isalnum() or x in ['-', '_'])


def sanitize_node_name(name):
    name = name.replace('(', '_')
    name = name.replace(')', '_')
    name = name.replace("'", '_')
    name = name.replace("=", '_')
    name = name.replace(" ", '')
    name = name.replace("__", '_')
    name = name.replace("__", '_')
    if name.startswith('_'):
        name = name[1:]
    if name.endswith('_'):
        name = name[:-1]
    return name

# Function to convert JSON to Lua syntax
def convert_json_to_lua(data):
    lua_lines = []
    
    lua_lines.append("local data = {")
    
    for obj in data:
        lua_lines.append("  {")
        for key, value in obj.items():
            if isinstance(value, list):
                # Format list as Lua table
                lua_lines.append(f"    {key} = {{ {', '.join(map(str, value))} }},")
            elif isinstance(value, str):
                # Format string
                lua_lines.append(f"    {key} = '{value}',")
            else:
                # Format numbers and other types
                lua_lines.append(f"    {key} = {value},")
        lua_lines.append("  },")
    
    lua_lines.append("}")
    lua_lines.append("return data")

    return "\n".join(lua_lines)


def walk_psd_layer(layer, tab, id, description):
    for layer_idx in range(len(layer._layers)):
        slide_height_index = str((tab + 1) * 1000 + id + layer_idx) 
        print(slide_height_index, " " * tab * tab_size, layer._layers[layer_idx], ": ", layer._layers[layer_idx].kind)
        _name = camel_to_snake(str(layer._layers[layer_idx]))
        _human_name = extract_human_name(_name)
        _name = sanitize_node_name(_name)
        _new_desc = {"name": _name, "human_name": _human_name, "index": slide_height_index, "kind": layer._layers[layer_idx].kind, "text": "", "bitmap": "", "bbox": []}
        # if layer._layers[layer_idx].kind == "type": # text
        #     print(slide_height_index, " " * tab * tab_size, layer._layers[layer_idx].engine_dict["Editor"]["Text"])
        #     # _new_desc["text"] = layer._layers[layer_idx].engine_dict["Editor"]["Text"]
        if layer._layers[layer_idx].is_group():
            walk_psd_layer(layer._layers[layer_idx], tab + 1, id + 1, description)
        else:
            slide_png_filename = str(layer._layers[layer_idx])
            slide_png_filename = slide_png_filename.replace("(", "_")
            slide_png_filename = slide_png_filename.replace(" size=", " _size_=")
            slide_png_filename = camel_to_snake(sanitize_filename(slide_png_filename))
            slide_png_filename = slide_png_filename +  "_" + str(id)
            if _human_name in common_files:
                _slide_name = "common"
                slide_png_filename = slide_png_filename.split("_size_")[0]
            else:
                _slide_name = slide_name
            slide_png_filename = _slide_name + '_' + slide_png_filename + '.png'
            slide_png_filename_path = os.path.join(output_path, slide_png_filename)
            layer._layers[layer_idx].composite().save(slide_png_filename_path)
            generate_meta_json(slide_png_filename_path)

            if layer._layers[layer_idx].kind != "type" or _human_name.startswith("page_"):
                tmp_image = Image.open(slide_png_filename_path).convert("RGBA")
                premultiplied_image = clean_alpha(tmp_image, slide_bg_color)
                premultiplied_image.save(slide_png_filename_path, "PNG")

            _new_desc["bitmap"] = os.path.join(hg_from_assets_path, slide_png_filename)
            _new_desc["bbox"] = layer._layers[layer_idx].bbox
        description.append(_new_desc)

        # return description
        

for slide_idx in range(0, 7):
    slide_name = "slide_" + f"{slide_idx + 1:02}"

    tab_size = 4
    description = []
    psd = PSDImage.open('slides/' + slide_name + '.psd')

    # psd.composite().save('out/example.png')
    # lr = psd.layer_and_mask.LayerRecords()

    tab = 0
    id = 0
    walk_psd_layer(psd, tab, id, description)

    json_object = json.dumps(description, indent = 4)
    json_filename = os.path.join(output_path, slide_name + ".json")
    with open(json_filename, "w") as outfile:
        outfile.write(json_object)
    # with open(output_path + slide_name + ".lua", "w") as outfile:
    #     outfile.write(convert_dict_to_lua(description))
    # print(json_object)

    # re-Load the JSON data
    with open(json_filename, 'r') as json_file:
        data = json.load(json_file)

    # Convert JSON to Lua
    lua_code = convert_json_to_lua(data)

    # Write the Lua code to a file
    with open(json_filename.replace('.json', '.lua'), 'w') as lua_file:
        lua_file.write(lua_code)

# for layer_idx in range(len(psd._layers)):
#     print(psd._layers[layer_idx])

# for layer in psd:
#     print(layer)
#     image = layer.composite()