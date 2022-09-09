module texture_packer;


import frame;
import packer.skyline_packer;
import rect;
import texture_packer_config;
import image;
import std.typecons: tuple, Tuple;
import std.array: insertInPlace;

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

        Rect source = this.config.trim ? trim_texture(texture) : Rect(0,0,w,h);

        
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

        Rect rect = Rect(0,0,texture.width(), texture.height());

        assert(this.packer.can_pack(rect), "TextureTooLargeToFitIntoAtlas");

        uint w = texture.width();
        uint h = texture.height();

        Rect source = this.config.trim ? trim_texture(texture) : Rect(0,0,w,h);

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

            rect.x = rect.x - extrusion;
            rect.y = rect.y - extrusion;

            rect.w += extrusion * 2;
            rect.h += extrusion * 2;

            if (rect.contains_point(x, y)) {
                return frame;
            }
        }

        // Return nothing
        return Frame();
    }

    Tuple!(bool, uint) width() {
        uint right = 0;
        bool goodToGo = false;

        foreach (Frame frame; this.frames){
            if (frame.frame.right() > right) {
                right = frame.frame.right();
                goodToGo = true;
            }
        }

        return tuple(goodToGo, right + 1 + this.config.border_padding);
    }

    Tuple!(bool, uint) height() {
        uint bottom = 0;
        bool goodToGo = false;

        foreach (Frame frame; this.frames) {
            if (frame.frame.bottom() > bottom) {
                bottom = frame.frame.bottom();
                goodToGo = true;
            }
        }

        return tuple(goodToGo, bottom + 1 + this.config.border_padding);
    }

    ubyte get(uint x, uint y) {
        /*
        if let Some(frame) = self.get_frame_at(x, y) {
            if self.config.texture_outlines && frame.frame.is_outline(x, y) {
                return Some(<Pix as Pixel>::outline());
            }

            if let Some(texture) = self.textures.get(&frame.key) {
                let x = x - frame.frame.x;
                let y = y - frame.frame.y;
            }
        }

        None
        */

        return 0;
    }
}

/*
fn trim_texture<T: Texture>(texture: &T) -> Rect {
    let mut x1 = 0;
    for x in 0..texture.width() {
        if texture.is_column_transparent(x) {
            x1 = x + 1;
        } else {
            break;
        }
    }

    let mut x2 = texture.width() - 1;
    for x in 0..texture.width() {
        let x = texture.width() - x - 1;
        if texture.is_column_transparent(x) {
            x2 = x - 1;
        } else {
            break;
        }
    }

    let mut y1 = 0;
    for y in 0..texture.height() {
        if texture.is_row_transparent(y) {
            y1 = y + 1;
        } else {
            break;
        }
    }

    let mut y2 = texture.height() - 1;
    for y in 0..texture.height() {
        let y = texture.height() - y - 1;
        if texture.is_row_transparent(y) {
            y2 = y - 1;
        } else {
            break;
        }
    }
    Rect::new_with_points(x1, y1, x2, y2)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::texture::memory_rgba8_texture::MemoryRGBA8Texture;

    #[test]
    fn able_to_store_in_struct() {
        let packer = TexturePacker::new_skyline(TexturePackerConfig::default());

        struct MyPacker<'a> {
            _packer: TexturePacker<'a, MemoryRGBA8Texture, String>,
        }

        MyPacker { _packer: packer };
    }
}
*/