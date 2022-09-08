module texture_packer_config;


/// Configuration for a texture packer.
struct TexturePackerConfig {
    //
    // layout configuration
    //
    /// Max width of the packed image. Default value is `1024`.
    uint max_width = 1024;
    /// Max height of the packed image. Default value is `1024`.
    uint max_height = 1024;
    /// True to allow rotation of the input images. Default value is `true`. Images rotated will be
    /// rotated 90 degrees clockwise.
    bool allow_rotation = true;

    //
    // texture configuration
    //
    /// Size of the padding on the outer edge of the packed image in pixel. Default value is `0`.
    uint border_padding = 0;
    /// Size of the padding between frames in pixel. Default value is `2`
    uint texture_padding = 2;
    /// Size of the repeated pixels at the border of each image. Default value is `0`.
    uint texture_extrusion = 0;

    /// True to trim the empty pixels of the input images. Default value is `true`.
    bool trim = true;

    /// True to draw the red line on the edge of the each frames. Useful for debugging. Default
    /// value is `false`.
    bool texture_outlines = false;
}

/*
impl Default for TexturePackerConfig {
    fn default() -> TexturePackerConfig {
        TexturePackerConfig {
            max_width: 1024,
            max_height: 1024,
            allow_rotation: true,

            border_padding: 0,
            texture_padding: 2,
            texture_extrusion: 0,

            trim: true,

            texture_outlines: false,
        }
    }
}
*/