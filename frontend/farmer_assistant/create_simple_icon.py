#!/usr/bin/env python3
"""
Create a simple app icon without external dependencies
"""
import struct

def create_simple_png():
    # Create a simple 16x16 green PNG
    width, height = 16, 16
    
    # PNG signature
    png_signature = b'\x89PNG\r\n\x1a\n'
    
    # IHDR chunk
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)
    ihdr_crc = 0x4A7A7A7A  # Placeholder CRC
    ihdr_chunk = struct.pack('>I', 13) + b'IHDR' + ihdr_data + struct.pack('>I', ihdr_crc)
    
    # IDAT chunk (simple green image data)
    # This is a very basic implementation
    idat_data = b'\x78\x9c\x62\x00\x00\x00\x02\x00\x01'
    idat_crc = 0x12345678  # Placeholder CRC
    idat_chunk = struct.pack('>I', len(idat_data)) + b'IDAT' + idat_data + struct.pack('>I', idat_crc)
    
    # IEND chunk
    iend_crc = 0xAE426082
    iend_chunk = struct.pack('>I', 0) + b'IEND' + struct.pack('>I', iend_crc)
    
    # Combine all chunks
    png_data = png_signature + ihdr_chunk + idat_chunk + iend_chunk
    
    # Write to file
    with open('assets/app_icon.png', 'wb') as f:
        f.write(png_data)
    
    print("Created simple app icon: assets/app_icon.png")
    print("Note: This is a placeholder. Please replace with a proper 512x512 icon.")

if __name__ == "__main__":
    create_simple_png()
