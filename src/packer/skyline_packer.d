module packer.skyline_packer;

import std.array: insertInPlace;
import std.algorithm.mutation: remove;
import std.typecons: Tuple, tuple;
import rect;
import texture_packer_config;

struct Skyline {
    uint x = 0;
    uint y = 0;
    uint w = 0;

    pragma(inline)
    uint left() {
        return this.x;
    }

    pragma(inline)
    uint right() {
        return this.x + this.w - 1;
    }
}

struct SkylinePacker {
    TexturePackerConfig config;
    Rect border;

    // the skylines are sorted by their `x` position
    Skyline[] skylines;

    this(TexturePackerConfig config) {
        skylines = new Skyline[0];

        skylines ~= Skyline(
            0,
            0,
            config.max_width,
        );

        border = Rect(0, 0, config.max_width, config.max_height);
    }

    // return `rect` if rectangle (w, h) can fit the skyline started at `i`
    Rect can_put(ref uint i, uint w, uint h) {

        Rect rect = Rect(this.skylines[i].x, 0, w, h);

        uint width_left = rect.w;

        while(true) {
            rect.y = max(rect.y, this.skylines[i].y);
            // the source rect is too large
            if (!this.border.contains(rect)) {
                return Rect();
            }
            if (this.skylines[i].w >= width_left) {
                return rect;
            }
            width_left -= this.skylines[i].w;
            i += 1;
            assert(i < this.skylines.len());
        }
    }

    Tuple!(uint, Rect) find_skyline(uint w, uint h) {
        uint bottom = uint.max;
        uint width = uint.max;
        uint index = 0;
        Rect rect;

        Rect r;

        // keep the `bottom` and `width` as small as possible
        for (uint i = 0; i < this.skylines.length(); i++) {
            
            r = this.can_put(i, h, w);

            if (r.exists) {
                if (r.bottom() < bottom || (r.bottom() == bottom && this.skylines[i].w < width)) {
                    bottom = r.bottom();
                    width = self.skylines[i].w;
                    index = i;
                    rect = r;
                }
            }

            if (this.config.allow_rotation) {

                r = this.can_put(i, h, w);

                if (r.exists) {
                    if (r.bottom() < bottom || (r.bottom() == bottom && this.skylines[i].w < width)) {
                        bottom = r.bottom();
                        width = this.skylines[i].w;
                        index = i;
                        rect = r;
                    }
                }
            }
        }

        return Tuple!(index, rect);
    }

    fn split(uint index, Rect rect) {
        Skyline skyline = Skyline(
            rect.left(),
            rect.bottom() + 1,
            rect.w,
        );

        assert(skyline.right() <= this.border.right());
        assert(skyline.y <= this.border.bottom());

        this.skylines.insertInPlace(index, skyline);

        uint i = index + 1;

        while (i < this.skylines.length()) {
            assert(this.skylines[i - 1].left() <= this.skylines[i].left());

            if (this.skylines[i].left() <= this.skylines[i - 1].right()) {
                uint shrink = this.skylines[i - 1].right() - this.skylines[i].left() + 1;
                if (this.skylines[i].w <= shrink) {
                    this.skylines.remove(i);
                } else {
                    this.skylines[i].x += shrink;
                    this.skylines[i].w -= shrink;
                    break;
                }
            } else {
                break;
            }
        }
    }

    fn merge(&mut self) {
        let mut i = 1;
        while i < self.skylines.len() {
            if self.skylines[i - 1].y == self.skylines[i].y {
                self.skylines[i - 1].w += self.skylines[i].w;
                self.skylines.remove(i);
                i -= 1;
            }
            i += 1;
        }
    }
}

impl<K> Packer<K> for SkylinePacker {
    fn pack(&mut self, key: K, texture_rect: &Rect) -> Option<Frame<K>> {
        let mut width = texture_rect.w;
        let mut height = texture_rect.h;

        width += self.config.texture_padding + self.config.texture_extrusion * 2;
        height += self.config.texture_padding + self.config.texture_extrusion * 2;

        if let Some((i, mut rect)) = self.find_skyline(width, height) {
            self.split(i, &rect);
            self.merge();

            let rotated = width != rect.w;

            rect.w -= self.config.texture_padding + self.config.texture_extrusion * 2;
            rect.h -= self.config.texture_padding + self.config.texture_extrusion * 2;

            Some(Frame {
                key,
                frame: rect,
                rotated,
                trimmed: false,
                source: Rect {
                    x: 0,
                    y: 0,
                    w: texture_rect.w,
                    h: texture_rect.h,
                },
            })
        } else {
            None
        }
    }

    fn can_pack(&self, texture_rect: &Rect) -> bool {
        if let Some((_, rect)) = self.find_skyline(
            texture_rect.w + self.config.texture_padding + self.config.texture_extrusion * 2,
            texture_rect.h + self.config.texture_padding + self.config.texture_extrusion * 2,
        ) {
            let skyline = Skyline {
                x: rect.left(),
                y: rect.bottom() + 1,
                w: rect.w,
            };

            return skyline.right() <= self.border.right() && skyline.y <= self.border.bottom();
        }
        false
    }
}
