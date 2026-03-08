import os
from fontTools.ttLib import TTFont

dir_path = r"E:\@MyApp\al_quran_v3-main\packages\qcf_quran_with_update\assets\fonts\qcf4"
print(f"Starting conversion in {dir_path}")

count = 0
for filename in os.listdir(dir_path):
    if filename.endswith(".woff"):
        woff_path = os.path.join(dir_path, filename)
        ttf_path = os.path.join(dir_path, filename.replace(".woff", ".ttf"))
        
        try:
            font = TTFont(woff_path)
            font.flavor = None  # Removes WOFF flavor, makes it a standard TTF/OTF
            font.save(ttf_path)
            count += 1
            if count % 100 == 0:
                print(f"Converted {count} fonts...")
        except Exception as e:
            print(f"Error converting {filename}: {e}")

print(f"Successfully converted {count} WOFF files to TTF.")
