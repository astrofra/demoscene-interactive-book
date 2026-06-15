import os
import shutil
import zipfile
from datetime import datetime

source_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.abspath(os.path.join(source_dir, ".."))

date_str = datetime.today().strftime('%Y-%m-%d')
dest_folder = os.path.join(parent_dir, f"demoscene-presentation-interactive-{date_str}")

def copy_files():
    if os.path.exists(dest_folder):
        shutil.rmtree(dest_folder)
    os.makedirs(dest_folder)

    print("Copying Redists")
    for folder_src in ["extern"]:
        folder_src_path = os.path.join(source_dir, "../work/", folder_src)
        folder_dest_path = os.path.join(dest_folder, folder_src)
        if os.path.exists(folder_src_path):
            shutil.copytree(folder_src_path, folder_dest_path)
    
    print("Copying main lua files")
    for file in os.listdir(source_dir):
        if file.endswith(".lua") and file not in ["build-latentspace-miro.lua", "build_slides.lua", "gamepad.lua"]:
            shutil.copy(os.path.join(source_dir, file), dest_folder)
    
    print("Copying readme files")
    for file in ["_Readme.md", "_Readme.pdf", "_start.bat"]:
        source_file = os.path.join(source_dir, file)
        if os.path.exists(source_file):
            shutil.copy(source_file, dest_folder)
    
    print("Copying assets & project lua files")
    for folder_src in ["assets_compiled", "projects"]:
        folder_src_path = os.path.join(source_dir, folder_src)
        folder_dest_path = os.path.join(dest_folder, folder_src)
        if os.path.exists(folder_src_path):
            shutil.copytree(folder_src_path, folder_dest_path)
    
    print("Copying HG Lua runtime")
    bin_src = os.path.join(source_dir, "bin")
    bin_dest = os.path.join(dest_folder, "bin")
    if os.path.exists(bin_src):
        def ignore_harfang(directory, files):
            return ["harfang"] if "harfang" in files and os.path.basename(directory) == "hg_lua-win-x64" else []
        shutil.copytree(bin_src, bin_dest, ignore=ignore_harfang)

def create_zip():
    print("Zipping...")
    zip_path = os.path.join(parent_dir, f"{os.path.basename(dest_folder)}.zip")
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, _, files in os.walk(dest_folder):
            for file in files:
                file_path = os.path.join(root, file)
                arcname = os.path.relpath(file_path, dest_folder)
                zipf.write(file_path, arcname)
    print(f"Package ZIP done: {zip_path}")

if __name__ == "__main__":
    copy_files()
    create_zip()
    print(f"Package ready in: {dest_folder}")
