import sys
from PIL import Image

def create_padded_icon(input_path, output_path, bg_color=None):
    try:
        img = Image.open(input_path)
        img = img.convert("RGBA")
        
        # Calculate new size (e.g. pad so the original image takes up 65% of the total size)
        scale_factor = 0.65
        max_dim = max(img.width, img.height)
        new_size = int(max_dim / scale_factor)
        
        # Create a new image with the target background
        if bg_color:
            new_img = Image.new("RGBA", (new_size, new_size), bg_color)
        else:
            new_img = Image.new("RGBA", (new_size, new_size), (255, 255, 255, 0))
            
        # Paste the original image into the center
        paste_x = (new_size - img.width) // 2
        paste_y = (new_size - img.height) // 2
        
        # Using alpha compositor
        new_img.alpha_composite(img, (paste_x, paste_y))
        
        if bg_color:
            new_img = new_img.convert("RGB") # Remove alpha for iOS
            
        new_img.save(output_path)
        print(f"Saved {output_path}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    input_file = "assets/images/logo1.png"
    # Create Android foreground icon (transparent background)
    create_padded_icon(input_file, "assets/images/logo1_android.png")
    # Create iOS icon (solid white background)
    create_padded_icon(input_file, "assets/images/logo1_ios.png", bg_color=(255, 255, 255, 255))
