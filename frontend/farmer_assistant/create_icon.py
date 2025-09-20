#!/usr/bin/env python3
"""
Simple script to create a basic app icon for Pravah
"""
from PIL import Image, ImageDraw
import os

def create_app_icon():
    # Create a 512x512 image with green background
    size = 512
    img = Image.new('RGBA', (size, size), (76, 175, 80, 255))  # #4CAF50
    draw = ImageDraw.Draw(img)
    
    # Draw a border
    draw.rectangle([0, 0, size-1, size-1], outline=(46, 125, 50, 255), width=8)  # #2E7D32
    
    # Draw a simple "P" in the center
    font_size = 200
    # Simple "P" shape
    draw.rectangle([size//2-60, size//2-100, size//2-20, size//2+100], fill=(255, 255, 255, 255))
    draw.rectangle([size//2-60, size//2-100, size//2+40, size//2-60], fill=(255, 255, 255, 255))
    draw.rectangle([size//2+20, size//2-100, size//2+40, size//2], fill=(255, 255, 255, 255))
    
    # Save the image
    output_path = 'assets/app_icon.png'
    img.save(output_path, 'PNG')
    print(f"Created app icon: {output_path}")

if __name__ == "__main__":
    try:
        create_app_icon()
    except ImportError:
        print("PIL (Pillow) not available. Please install with: pip install Pillow")
        print("Or manually create a 512x512 PNG icon and save as assets/app_icon.png")
