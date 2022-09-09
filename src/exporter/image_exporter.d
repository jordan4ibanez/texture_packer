module exporter.image_exporter;

import texture_packer;
import image;
import std.stdio;
import frame;
import rect;

/// Export a memory texture packer to a TrueTypeImage.
TrueColorImage exportToImage(TexturePacker packer) {

    uint width = packer.width();
    uint height = packer.height();

    assert(width != 0, "Width of this packer is zero");
    assert(height != 0, "Height of this packer is zero");


    // Build the new image, pixel by pixel
    TrueColorImage newImage = new TrueColorImage(width, height);

    for (int x = 0; x < width; x++) {
        for (int y = 0; y < height; y++) {
            newImage.setPixel(
                x,
                y,
                packer.get(x,y)
            );
        }
    }

    
    

    return newImage;
}
