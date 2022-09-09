module app;

import std.stdio;

import texture_packer;
import texture_packer_config;
import image;
import exporter.image_exporter;
import std.conv: to;
import arsd.png;


void main() {

    TexturePackerConfig config = TexturePackerConfig(400,400, false,2,0,0,true,true);
    TexturePacker packer = TexturePacker.new_skyline(config);


    uint x = 1;
    while (x <= 10){
        TrueColorImage tempImageObject = loadImageFromFile("examples/assets/" ~ to!string(x) ~ ".png").getAsTrueColorImage();
        packer.pack_own("blah" ~ to!string(x), tempImageObject);
        x++;
    }

    writeln("exiting");
    TrueColorImage myCoolPicture = exportToImage(packer);

    writeImageToPngFile("test.png", myCoolPicture);

        
}