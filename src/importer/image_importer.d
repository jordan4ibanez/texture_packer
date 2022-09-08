module importer.image_importer;

import image;

/// Importer type for images.
struct ImageImporter {
    /// Import an image from a path.
    TrueColorImage import_from_file(string path) {
        return loadImageFromFile(path).getAsTrueColorImage();
    }

    /// Import an image from memory.
    TrueColorImage import_from_memory(ubyte[] buffer) {
        return loadImageFromMemory(cast(const(void)[]) buffer).getAsTrueColorImage();
    }
}