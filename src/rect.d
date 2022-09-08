module rect;

/// Defines a rectangle in pixels with the origin at the top-left of the texture atlas.
struct Rect {
    /// Horizontal position the rectangle begins at.
    uint x = 0;
    /// Vertical position the rectangle begins at.
    uint y = 0;
    /// Width of the rectangle.
    uint w = 0;
    /// Height of the rectangle.
    uint h = 0;


    /// Create a new [Rect] based on a position and its width and height.
    this(uint x, uint y, uint w, uint h) {
        this.x = x; this.y = y; this.w = w; this.z = z;
    }

    /// Create a new [Rect] based on two points spanning the rectangle.
    this(uint x1, uint y1, uint x2, uint y2) {
        this.x = x1;
        this.y = y1;
        this.w = x2 - x1 + 1;
        this.h = y2 - y1 + 1;
    }

    /// Get the top coordinate of the rectangle.
    pragma(inline)
    uint top() {
        return this.y;
    }

    /// Get the bottom coordinate of the rectangle.
    pragma(inline)
    uint bottom() {
        return this.y + this.h - 1;
    }

    /// Get the left coordinate of the rectangle.
    pragma(inline)
    uint left() {
        return this.x;
    }

    /// Get the right coordinate of the rectangle.
    pragma(inline)
    uint right() {
        return this.x + this.w - 1;
    }

    /// Get the area of the rectangle.
    pragma(inline)
    uint area() {
        return this.w * this.h;
    }

    /// Check if this rectangle intersects with another.
    bool intersects(Rect other) {
        return this.left() < other.right()
            && this.right() > other.left()
            && this.top() < other.bottom()
            && this.bottom() > other.top();
    }

    /// Check if this rectangle contains another.
    pub fn contains(&self, other: &Rect) -> bool {
        self.left() <= other.left()
            && self.right() >= other.right()
            && self.top() <= other.top()
            && self.bottom() >= other.bottom()
    }

    /// Check if this rectangle contains a point. Includes the edges of the rectangle.
    pub fn contains_point(&self, x: u32, y: u32) -> bool {
        self.left() <= x && self.right() >= x && self.top() <= y && self.bottom() >= y
    }

    /// Check if a point falls on the rectangle's boundaries.
    pub fn is_outline(&self, x: u32, y: u32) -> bool {
        x == self.left() || x == self.right() || y == self.top() || y == self.bottom()
    }

    /// Split two rectangles into non-overlapping regions.
    pub fn crop(&self, other: &Rect) -> Vec<Rect> {
        if !self.intersects(other) {
            return vec![*self];
        }

        let inside_x1 = if other.left() < self.left() {
            self.left()
        } else {
            other.left()
        };

        let inside_y1 = if other.top() < self.top() {
            self.top()
        } else {
            other.top()
        };

        let inside_x2 = if other.right() > self.right() {
            self.right()
        } else {
            other.right()
        };

        let inside_y2 = if other.bottom() > self.bottom() {
            self.bottom()
        } else {
            other.bottom()
        };

        //
        // *******************
        // *    | r3  |      *
        // *    |     |      *
        // *    +++++++      *
        // * r1 +     +      *
        // *    +     +  r2  *
        // *    +++++++      *
        // *    |     |      *
        // *    | r4  |      *
        // *******************
        //
        let mut result = Vec::new();

        let r1 = Rect::new_with_points(self.left(), self.top(), inside_x1, self.bottom());
        if r1.area() > 0 {
            result.push(r1);
        }

        let r2 = Rect::new_with_points(inside_x2, self.top(), self.right(), self.bottom());
        if r2.area() > 0 {
            result.push(r2);
        }

        let r3 = Rect::new_with_points(inside_x1, self.top(), inside_x2, inside_y1);
        if r3.area() > 0 {
            result.push(r3);
        }

        let r4 = Rect::new_with_points(inside_x1, inside_y2, inside_x2, self.bottom());
        if r4.area() > 0 {
            result.push(r4);
        }

        result
    }
}

impl<T: Texture> From<&T> for Rect {
    fn from(item: &T) -> Self {
        Rect {
            x: 0,
            y: 0,
            w: item.width(),
            h: item.height(),
        }
    }
}
