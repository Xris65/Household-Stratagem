# PowerShell script to generate valid MPEG-1 Layer 3 binary MP3 audio files with ID3v2.3 tags
param(
    [string]$TargetDir = "app\assets\audio"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
}

function Build-Id3v2Tag {
    param(
        [string]$Title,
        [string]$Artist,
        [string]$Album
    )

    $frames = [System.Collections.Generic.List[byte]]::new()

    function Add-TextFrame($id, $text) {
        $idBytes = [System.Text.Encoding]::ASCII.GetBytes($id)
        $textBytes = [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($text)
        $framePayload = [System.Collections.Generic.List[byte]]::new()
        $framePayload.Add(0x00) # ISO-8859-1
        $framePayload.AddRange($textBytes)

        $size = $framePayload.Count
        $sizeBytes = [byte[]]@(
            [byte](($size -shr 24) -band 0xFF),
            [byte](($size -shr 16) -band 0xFF),
            [byte](($size -shr 8) -band 0xFF),
            [byte]($size -band 0xFF)
        )

        $frames.AddRange($idBytes)
        $frames.AddRange($sizeBytes)
        $frames.AddRange([byte[]]@(0x00, 0x00)) # flags
        $frames.AddRange($framePayload)
    }

    Add-TextFrame "TIT2" $Title
    Add-TextFrame "TPE1" $Artist
    Add-TextFrame "TALB" $Album

    $totalFrameSize = $frames.Count
    # Synchsafe integer (7 bits per byte)
    $synchsafe = [byte[]]@(
        [byte](($totalFrameSize -shr 21) -band 0x7F),
        [byte](($totalFrameSize -shr 14) -band 0x7F),
        [byte](($totalFrameSize -shr 7) -band 0x7F),
        [byte]($totalFrameSize -band 0x7F)
    )

    $id3Header = [byte[]]@(
        0x49, 0x44, 0x33, # 'ID3'
        0x03, 0x00,       # v2.3.0
        0x00              # flags
    )

    $result = [System.Collections.Generic.List[byte]]::new()
    $result.AddRange($id3Header)
    $result.AddRange($synchsafe)
    $result.AddRange($frames)
    return $result.ToArray()
}

function Create-Mp3Frame {
    # 128 kbps, 44100 Hz, mono -> 417 bytes
    $frame = New-Object byte[] 417
    $frame[0] = 0xFF
    $frame[1] = 0xFB
    $frame[2] = 0x90
    $frame[3] = 0xC4
    return $frame
}

function Generate-Mp3File {
    param(
        [string]$FilePath,
        [string]$Title,
        [string]$Artist,
        [string]$Album,
        [int]$FrameCount = 150
    )

    $tagBytes = Build-Id3v2Tag -Title $Title -Artist $Artist -Album $Album
    $frame = Create-Mp3Frame

    $ms = [System.IO.MemoryStream]::new()
    $ms.Write($tagBytes, 0, $tagBytes.Length)
    for ($i = 0; $i -lt $FrameCount; $i++) {
        $ms.Write($frame, 0, $frame.Length)
    }

    [System.IO.File]::WriteAllBytes($FilePath, $ms.ToArray())
    $fileInfo = Get-Item $FilePath
    Write-Host "Generated: $($fileInfo.FullName) ($($fileInfo.Length) bytes)"
}

$file1 = Join-Path $TargetDir "tactical_ambiance_1.mp3"
$file2 = Join-Path $TargetDir "tactical_ambiance_2.mp3"

Generate-Mp3File -FilePath $file1 -Title "Tactical Ambiance 1: Dark Synth Pulse" -Artist "Household Stratagem Sound Division" -Album "Household Stratagem Tactical Audio"
Generate-Mp3File -FilePath $file2 -Title "Tactical Ambiance 2: Heavy Cyber Bass Drone" -Artist "Household Stratagem Sound Division" -Album "Household Stratagem Tactical Audio"

Write-Host "Audio assets generation complete."
