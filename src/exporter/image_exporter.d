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

    foreach (Frame frame; packer.frames) {
        TrueColorImage frameImage = packer.textures[frame.key];

        Rect realLocation = frame.frame;

        //writeln("real location: ", realLocation);
        //writeln("packer: ", width, " ", height);

        if (realLocation.exists) {
            for (int x = 0; x < realLocation.w; x++) {
                for (int y = 0; y < realLocation.h; y++) {
                    newImage.setPixel(
                        x + realLocation.x,
                        y + realLocation.y,
                        frameImage.getPixel(x,y)
                    );
                }
            }

        }
    }

    return newImage;
}
