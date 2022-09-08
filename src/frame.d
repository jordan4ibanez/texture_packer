module frame;

/// Boundaries and properties of a packed texture.
struct Frame(K) {
    /// Key used to uniquely identify this frame.
    K key;
    /// Rectangle describing the texture coordinates and size.
    Rect frame;
    /// True if the texture was rotated during packing.
    /// If it was rotated, it was rotated 90 degrees clockwise.
    bool rotated = false;
    /// True if the texture was trimmed during packing.
    bool trimmed = false;

    // (x, y) is the trimmed frame position at original image
    // (w, h) is original image size
    //
    //            w
    //     +--------------+
    //     | (x, y)       |
    //     |  ^           |
    //     |  |           |
    //     |  *********   |
    //     |  *       *   |  h
    //     |  *       *   |
    //     |  *********   |
    //     |              |
    //     +--------------+
    /// Source texture size before any trimming.
    Rect source;

    bool exists = false;

    this(K key, Rect frame, bool rotated, bool trimmed, Rect source) {
        this.key = key;
        this.frame = frame;
        this.rotated = rotated;
        this.trimmed = trimmed;
        this.source = source;
        this.exists = true;
    }
}
