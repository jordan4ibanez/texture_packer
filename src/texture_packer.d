module texture_packer;

import frame;
import packer.skyline_packer;
import rect;
import texture_packer_config;
import image;
import std.typecons: tuple, Tuple;
import std.array: insertInPlace;
import std.stdio;
import std.algorithm.comparison: min;

// pub type PackResult<T> = Result<T, PackError>;

enum PackError {
    TextureTooLargeToFitIntoAtlas,
}

/// Packs textures into a single texture atlas.
struct TexturePacker {
    TrueColorImage[string] textures;
    Frame[string] frames;
    SkylinePacker packer;
    TexturePackerConfig config;

    this(TexturePackerConfig config) {
        this.config = config;
        this.packer = SkylinePacker(config);
    }

    /// Create a new packer using the skyline packing algorithm.
    static TexturePacker new_skyline(TexturePackerConfig config) {
        return TexturePacker(config);
    }

    /// Check if the texture can be packed into this packer.
    bool can_pack(TrueColorImage texture) {
        Rect rect = Rect(0,0,texture.width(), texture.height());
        return this.packer.can_pack(rect);
    }


    /// Pack the `texture` into this packer, taking a reference of the texture object.
    void pack_ref(string key, ref TrueColorImage texture) {

        Rect rect = Rect(0,0,texture.width(), texture.height());

        assert(this.packer.can_pack(rect), "TextureTooLargeToFitIntoAtlas");

        uint w = texture.width();
        uint h = texture.height();

        Rect source;
        if (this.config.trim) {
            source = trim_texture(texture);
        } else {
            source = Rect(0,0,w,h);
        }

        Frame frame = this.packer.pack(key, rect);
        
        frame.frame.x += this.config.border_padding;
        frame.frame.y += this.config.border_padding;
        frame.trimmed = this.config.trim;
        frame.source = source;
        frame.source.w = w;
        frame.source.h = h;

        this.frames[key] = frame;

        this.textures[key] = texture;

    }

    /// Pack the `texture` into this packer, taking ownership of the texture object.
    void pack_own(string key, TrueColorImage texture) {

        writeln("packing ", key);
        Rect rect = Rect(0,0,texture.width(), texture.height());     

        assert(this.packer.can_pack(rect), "TextureTooLargeToFitIntoAtlas");

        uint w = texture.width();
        uint h = texture.height();

        Rect source;

        writeln(this.config.trim);
        if (this.config.trim) {
            source = trim_texture(texture);
        } else {
            source = Rect(0,0,w,h);
        }

        Frame frame = this.packer.pack(key, rect);
        
        frame.frame.x += this.config.border_padding;
        frame.frame.y += this.config.border_padding;
        frame.trimmed = this.config.trim;
        frame.source = source;
        frame.source.w = w;
        frame.source.h = h;

        this.frames[key] = frame;

        this.textures[key] = texture;
    }

    /// Get the backing mapping from strings to frames.
    Frame[string] get_frames() {
        return this.frames;
    }

    /// Acquire a frame by its name.
   Frame get_frame(string key) {
        return this.frames[key];
    }

    /// Get the frame that overlaps with a specified coordinate.
    Frame get_frame_at(uint x, uint y) {

        uint extrusion = this.config.texture_extrusion;

        foreach (Frame frame; this.frames) {

            Rect rect = frame.frame;

            rect.x -= extrusion;
            rect.y -= extrusion;

            rect.w += extrusion * 2;
            rect.h += extrusion * 2;

            if (rect.contains_point(x, y)) {
                return frame;
            }
        }

        // Return nothing
        return Frame();
    }

    uint width() {
        uint right = 0;

        foreach (Frame frame; this.frames){
            if (frame.frame.right() > right) {
                right = frame.frame.right();
            }
        }

        return right + 1 + this.config.border_padding;
    }

    uint height() {
        uint bottom = 0;

        foreach (Frame frame; this.frames) {
            if (frame.frame.bottom() > bottom) {
                bottom = frame.frame.bottom();
            }
        }

        return bottom + 1 + this.config.border_padding;
    }

    Color get(uint x, uint y) {

        Frame frame = this.get_frame_at(x, y);

        Color colorData = Color(0,0,0,0);

        if (frame.exists) {


            // An outline - black
            if (this.config.texture_outlines && frame.frame.is_outline(x, y)) {
                return Color(255,0,0,255);
            }        

            TrueColorImage texture = this.textures[frame.key];

            x -= frame.frame.x;
            y -= frame.frame.y;

            x = min(x, texture.width() - 1);
            y = min(y, texture.height() - 1);

            colorData = texture.getPixel(x, y);
        }

        return colorData;
    }

    Rect trim_texture(TrueColorImage texture) {

        uint textureWidth = texture.width();
        uint textureHeight = texture.height();

        uint x1 = 0;

        for (uint x = 0; x < textureWidth; x++){
            bool columnTransparent = true;

            for (uint y = 0; y < textureHeight; y++) {
                if (texture.getPixel(x,y).a > 0) {
                    columnTransparent = false;
                }
            }          
            if (columnTransparent) {
                x1 = x + 1;
            } else {
                break;
            }
        }

        uint x2 = textureWidth - 1;

        for (uint x = 0; x < textureWidth; x++){

            bool columnTransparent = true;

            x = textureWidth - x - 1;


            for (uint y = 0; y < textureHeight; y++) {
                if (texture.getPixel(x,y).a > 0) {
                    columnTransparent = false;
                }
            }  

            if (columnTransparent) {
                x2 = x - 1;
            } else {
                break;
            }
        }

        uint y1 = 0;

        for (uint y = 0; y < textureHeight; y++) {

            bool rowTransparent = true;

            for (uint x = 0; x < textureWidth; x++) {
                if (texture.getPixel(x,y).a > 0) {
                    rowTransparent = false;
                }
            }

            if (rowTransparent) {
                y1 = y + 1;
            } else {
                break;
            }
        }

        uint y2 = textureHeight - 1;

        for (uint y = 0; y < textureHeight; y++) {

            bool rowTransparent = true;
            y = textureHeight - y - 1;

            for (uint x = 0; x < textureWidth; x++) {
                if (texture.getPixel(x,y).a > 0) {
                    rowTransparent = false;
                }
            }

            if (rowTransparent) {
                y2 = y - 1;
            } else {
                break;
            }
        }


        return Rect.newWithPoints(x1,y1,x2,y2);
    }
}