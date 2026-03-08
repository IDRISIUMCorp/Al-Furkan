import os
from fontTools.ttLib import TTFont

font_path = r"E:\@MyApp\al_quran_v3-main\packages\qcf_quran_with_update\assets\fonts\qcf4\QCF4001_X-Regular.ttf"

def dump_cmap(font_path):
    font = TTFont(font_path)
    cmap = font.getBestCmap()
    if not cmap:
        print("No cmap found.")
        return
        
    print(f"Total mapped characters: {len(cmap)}")
    
    # Let's print the ranges of supported characters
    chars = sorted(cmap.keys())
    
    # Group contiguous ranges
    ranges = []
    start = chars[0]
    prev = chars[0]
    
    for c in chars[1:]:
        if c == prev + 1:
            prev = c
        else:
            ranges.append((start, prev))
            start = c
            prev = c
    ranges.append((start, prev))
    
    for start, end in ranges:
        if start == end:
            print(f"U+{start:04X} ({chr(start) if start > 0x20 else ''})")
        else:
            print(f"U+{start:04X} - U+{end:04X} ({end - start + 1} chars)")
            
    # Also print any characters in the PUA range F000-F8FF or similar
    print("\nSample mapped Characters:")
    for code in chars[:20]:
        print(f"U+{code:04X} : {cmap[code]}")

dump_cmap(font_path)
