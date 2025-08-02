# Tạo file âm thanh WAV đúng format
$sampleRate = 44100
$duration = 0.5
$frequency = 800
$amplitude = 0.3

# Tính toán số mẫu
$samples = [int]($sampleRate * $duration)

# Tạo WAV header
$header = @(
    # RIFF header
    0x52, 0x49, 0x46, 0x46,  # "RIFF"
    0x00, 0x00, 0x00, 0x00,  # File size (sẽ được cập nhật sau)
    0x57, 0x41, 0x56, 0x45,  # "WAVE"
    
    # fmt chunk
    0x66, 0x6D, 0x74, 0x20,  # "fmt "
    0x10, 0x00, 0x00, 0x00,  # fmt chunk size
    0x01, 0x00,              # Audio format (PCM)
    0x01, 0x00,              # Number of channels (mono)
    0x44, 0xAC, 0x00, 0x00,  # Sample rate (44100)
    0x88, 0x58, 0x01, 0x00,  # Byte rate
    0x02, 0x00,              # Block align
    0x10, 0x00,              # Bits per sample
    
    # data chunk
    0x64, 0x61, 0x74, 0x61,  # "data"
    0x00, 0x00, 0x00, 0x00   # Data size (sẽ được cập nhật sau)
)

# Tạo dữ liệu âm thanh
$audioData = @()
for ($i = 0; $i -lt $samples; $i++) {
    $t = $i / $sampleRate
    $value = [int]($amplitude * 32767 * [Math]::Sin(2 * [Math]::PI * $frequency * $t))
    $audioData += $value -band 0xFF
    $audioData += ($value -shr 8) -band 0xFF
}

# Cập nhật kích thước file
$fileSize = $header.Length + $audioData.Length - 8
$header[4] = $fileSize -band 0xFF
$header[5] = ($fileSize -shr 8) -band 0xFF
$header[6] = ($fileSize -shr 16) -band 0xFF
$header[7] = ($fileSize -shr 24) -band 0xFF

# Cập nhật kích thước data
$dataSize = $audioData.Length
$header[40] = $dataSize -band 0xFF
$header[41] = ($dataSize -shr 8) -band 0xFF
$header[42] = ($dataSize -shr 16) -band 0xFF
$header[43] = ($dataSize -shr 24) -band 0xFF

# Ghi file
$allBytes = $header + $audioData
[System.IO.File]::WriteAllBytes("E:\loathong_bao\my_flutter_app\assets\sounds\beep.wav", $allBytes)

Write-Host "File âm thanh đã được tạo: assets\sounds\beep.wav" 