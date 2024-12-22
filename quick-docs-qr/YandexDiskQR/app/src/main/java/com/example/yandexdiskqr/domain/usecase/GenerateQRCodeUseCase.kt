package com.example.yandexdiskqr.domain.usecase

import android.graphics.Bitmap
import com.google.zxing.BarcodeFormat
import com.google.zxing.qrcode.QRCodeWriter
import javax.inject.Inject

class GenerateQRCodeUseCase @Inject constructor() {
    operator fun invoke(folderPath: String, width: Int = 512, height: Int = 512): Result<Bitmap> = runCatching {
        val writer = QRCodeWriter()
        val bitMatrix = writer.encode(folderPath, BarcodeFormat.QR_CODE, width, height)
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.RGB_565)
        
        for (x in 0 until width) {
            for (y in 0 until height) {
                bitmap.setPixel(x, y, if (bitMatrix[x, y]) android.graphics.Color.BLACK else android.graphics.Color.WHITE)
            }
        }
        
        bitmap
    }
}
