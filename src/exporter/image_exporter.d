module exporter.image_exporter;

import texture_packer;
import image;

/// Export a memory texture packer to a TrueTypeImage.
void exportToImage(TexturePacker packer) {

    uint width = packer.width();
    uint height = packer.height();

    assert(width == 0 || height == 0, "Width or height of this packer is zero");



    TrueColorImage newImage = new TrueColorImage(width, height);

    /*

    let mut pixels = Vec::with_capacity((width * height * 4) as usize);

    for row in 0..height {
        for col in 0..width {
            if let Some(pixel) = texture.get(col, row) {
                pixels.push(pixel[0]);
                pixels.push(pixel[1]);
                pixels.push(pixel[2]);
                pixels.push(pixel[3]);
            } else {
                pixels.push(0);
                pixels.push(0);
                pixels.push(0);
                pixels.push(0);
            }
        }
    }

    if let Some(image_buffer) =
        ImageBuffer::<Rgba<u8>, Vec<u8>>::from_raw(width, height, pixels)
    {
        Ok(DynamicImage::ImageRgba8(image_buffer))
    } else {
        Err("Can't export texture".to_string())
    }
    */
}
