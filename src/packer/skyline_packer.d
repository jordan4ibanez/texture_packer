module packer.skyline_packer;

import std.array: insertInPlace;
import std.algorithm.mutation: remove;
import std.typecons: Tuple, tuple;
import std.algorithm.comparison: max;
import rect;
import texture_packer_config;
import frame;

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

        skylines ~= Skyline(
            0,
            0,
            config.max_width,
        );

        border = Rect(0, 0, config.max_width, config.max_height);
        this.config = config;
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
            assert(i < this.skylines.length);
        }
    }

    Tuple!(uint, Rect) find_skyline(uint w, uint h) {
        uint bottom = uint.max;
        uint width = uint.max;
        uint index = 0;
        Rect rect;

        Rect r;

        // keep the `bottom` and `width` as small as possible
        for (uint i = 0; i < this.skylines.length; i++) {
            
            r = this.can_put(i, h, w);

            if (r.exists) {
                if (r.bottom() < bottom || (r.bottom() == bottom && this.skylines[i].w < width)) {
                    bottom = r.bottom();
                    width = this.skylines[i].w;
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

        return tuple(index, rect);
    }

    void split(uint index, Rect rect) {
        Skyline skyline = Skyline(
            rect.left(),
            rect.bottom() + 1,
            rect.w,
        );

        assert(skyline.right() <= this.border.right());
        assert(skyline.y <= this.border.bottom());

        this.skylines.insertInPlace(index, skyline);

        uint i = index + 1;

        while (i < this.skylines.length) {
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

    void merge() {
        uint i = 1;
        while (i < this.skylines.length) {
            if (this.skylines[i - 1].y == this.skylines[i].y) {
                this.skylines[i - 1].w += this.skylines[i].w;
                this.skylines.remove(i);
                i -= 1;
            }
            i += 1;
        }
    }

    Frame pack(string key, Rect texture_rect) {
        uint width = texture_rect.w;
        uint height = texture_rect.h;

        width += this.config.texture_padding + this.config.texture_extrusion * 2;
        height += this.config.texture_padding + this.config.texture_extrusion * 2;

        Tuple!(uint, Rect) data = this.find_skyline(width, height);

        uint i = data[0];
        Rect rect = data[1];

        if (rect.exists) {
            this.split(i, rect);
            this.merge();

            bool rotated = width != rect.w;

            rect.w -= this.config.texture_padding + this.config.texture_extrusion * 2;
            rect.h -= this.config.texture_padding + this.config.texture_extrusion * 2;

            return Frame(
                key,
                rect,
                rotated,
                false,
                Rect (
                    0,
                    0,
                    texture_rect.w,
                    texture_rect.h,
                )
            );
        } else {
            return Frame();
        }
    }

    bool can_pack(Rect texture_rect) {

        Tuple!(uint, Rect) data = this.find_skyline(
            texture_rect.w + this.config.texture_padding + this.config.texture_extrusion * 2,
            texture_rect.h + this.config.texture_padding + this.config.texture_extrusion * 2,
        );

        Rect rect = data[1];
        
        if (rect.exists){
            Skyline skyline = Skyline(
                rect.left(),
                rect.bottom() + 1,
                rect.w,
            );

            return skyline.right() <= this.border.right() && skyline.y <= this.border.bottom();
        }

        return false;
    }
}
