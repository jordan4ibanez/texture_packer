module app;

import std.stdio;

import texture_packer;
import texture_packer_config;
import image;

void main() {
    TexturePackerConfig config = TexturePackerConfig(400,400,true,0,0,0,true,false);
    TexturePacker packer = TexturePacker(config);

    TrueColorImage tempImageObject = loadImageFromFile("examples/assets/1.png").getAsTrueColorImage();

    packer.pack_own("blah", tempImageObject);

        
}