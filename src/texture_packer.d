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
    TrueColorImage[uint] textures;
    Frame[uint] frames;
    SkylinePacker packer;
    TexturePackerConfig config;

    /// Create a new packer using the skyline packing algorithm.
    static TexturePacker new_skyline(TexturePackerConfig config) {
        return TexturePacker(
            new TrueColorImage[0],
            new Frame[0],
            *new SkylinePacker(config),
            config
        );
    }

    /// Check if the texture can be packed into this packer.
    bool can_pack(TrueColorImage texture) {
        Rect rect = Rect(0,0,texture.width(), texture.height());
        return this.packer.can_pack(rect);
    }


    /// Pack the `texture` into this packer, taking a reference of the texture object.
    void pack_ref(uint key, ref TrueColorImage texture) {

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

        this.frames.insertInPlace(key, frame);

        this.textures.insertInPlace(key, texture);

    }

    /// Pack the `texture` into this packer, taking ownership of the texture object.
    void pack_own(uint key, TrueColorImage texture) {

        Rect rect = Rect(0,0,texture.width(), texture.height());

        assert(this.packer.can_pack(rect), "TextureTooLargeToFitIntoAtlas");

        uint w = texture.width();
        uint h = texture.height();

        Rect source = this.config.trim ? trim_texture(texture) : Rect(0,0,w,h);

        Frame frame = this.packer.pack(key.clone(), &rect);
        
        frame.frame.x += this.config.border_padding;
        frame.frame.y += this.config.border_padding;
        frame.trimmed = this.config.trim;
        frame.source = source;
        frame.source.w = w;
        frame.source.h = h;

        this.frames.insert(key, frame);

        this.textures.insert(key, texture);
    }

    /// Get the backing mapping from strings to frames.
    pub fn get_frames(&self) -> &HashMap<K, Frame<K>> {
        &self.frames
    }

    /// Acquire a frame by its name.
    pub fn get_frame(&self, key: &K) -> Option<&Frame<K>> {
        if let Some(frame) = self.frames.get(key) {
            Some(frame)
        } else {
            None
        }
    }

    /// Get the frame that overlaps with a specified coordinate.
    fn get_frame_at(&self, x: u32, y: u32) -> Option<&Frame<K>> {
        let extrusion = self.config.texture_extrusion;

        for (_, frame) in self.frames.iter() {
            let mut rect = frame.frame;

            rect.x = rect.x.saturating_sub(extrusion);
            rect.y = rect.y.saturating_sub(extrusion);

            rect.w += extrusion * 2;
            rect.h += extrusion * 2;

            if rect.contains_point(x, y) {
                return Some(frame);
            }
        }
        None
    }
}

impl<'a, Pix, T: Clone, K: Clone + Eq + Hash> Texture for TexturePacker<'a, T, K>
where
    Pix: Pixel,
    T: Texture<Pixel = Pix>,
{
    type Pixel = Pix;

    fn width(&self) -> u32 {
        let mut right = None;

        for (_, frame) in self.frames.iter() {
            if let Some(r) = right {
                if frame.frame.right() > r {
                    right = Some(frame.frame.right());
                }
            } else {
                right = Some(frame.frame.right());
            }
        }

        if let Some(right) = right {
            right + 1 + self.config.border_padding
        } else {
            0
        }
    }

    fn height(&self) -> u32 {
        let mut bottom = None;

        for (_, frame) in self.frames.iter() {
            if let Some(b) = bottom {
                if frame.frame.bottom() > b {
                    bottom = Some(frame.frame.bottom());
                }
            } else {
                bottom = Some(frame.frame.bottom());
            }
        }

        if let Some(bottom) = bottom {
            bottom + 1 + self.config.border_padding
        } else {
            0
        }
    }

    fn get(&self, x: u32, y: u32) -> Option<Pix> {
        if let Some(frame) = self.get_frame_at(x, y) {
            if self.config.texture_outlines && frame.frame.is_outline(x, y) {
                return Some(<Pix as Pixel>::outline());
            }

            if let Some(texture) = self.textures.get(&frame.key) {
                let x = x.saturating_sub(frame.frame.x);
                let y = y.saturating_sub(frame.frame.y);

                return if frame.rotated {
                    let x = min(x, texture.height() - 1);
                    let y = min(y, texture.width() - 1);
                    texture.get_rotated(x, y)
                } else {
                    let x = min(x, texture.width() - 1);
                    let y = min(y, texture.height() - 1);
                    texture.get(x, y)
                };
            }
        }

        None
    }

    fn set(&mut self, _x: u32, _y: u32, _val: Pix) {
        panic!("Can't set pixel directly");
    }
}

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
