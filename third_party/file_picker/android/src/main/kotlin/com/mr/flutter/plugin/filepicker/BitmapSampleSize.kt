package com.mr.flutter.plugin.filepicker

/** Bounds the decoded bitmap's longest edge before allocating its pixels. */
internal object BitmapSampleSize {
    private const val MAX_EDGE = 2048

    fun forDimensions(width: Int, height: Int): Int {
        require(width > 0 && height > 0)
        val longestEdge = maxOf(width, height).toLong()
        var sampleSize = 1
        // Ceiling division also bounds odd dimensions and panoramic images.
        while ((longestEdge + sampleSize - 1) / sampleSize > MAX_EDGE) {
            sampleSize *= 2
        }
        return sampleSize
    }
}
