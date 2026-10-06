package com.mr.flutter.plugin.filepicker

import org.junit.Assert.assertEquals
import org.junit.Test

class BitmapSampleSizeTest {
    @Test fun keepsSmallImagesAtTheirOriginalResolution() {
        assertEquals(1, BitmapSampleSize.forDimensions(640, 480))
        assertEquals(1, BitmapSampleSize.forDimensions(2048, 2048))
    }

    @Test fun samplesLandscapePortraitAndPanoramasBeforeDecoding() {
        assertEquals(2, BitmapSampleSize.forDimensions(4000, 3000))
        assertEquals(2, BitmapSampleSize.forDimensions(3000, 4000))
        assertEquals(8, BitmapSampleSize.forDimensions(16000, 1000))
        assertEquals(4, BitmapSampleSize.forDimensions(4097, 1000))
    }

    @Test fun handlesLargeDimensionsWithoutIntegerOverflow() {
        assertEquals(1048576, BitmapSampleSize.forDimensions(Int.MAX_VALUE, 1))
    }

    @Test(expected = IllegalArgumentException::class)
    fun rejectsInvalidBounds() {
        BitmapSampleSize.forDimensions(-1, 100)
    }
}
