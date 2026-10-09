import 'dart:io';
import 'dart:typed_data';

/// Minimal valid MPEG-1 Layer III frame generator
List<int> createMpeg1Layer3FrameMono128k44100() {
  // 128 kbps, 44100 Hz, mono -> frame size = floor(144 * 128000 / 44100) = 417 bytes
  final frame = Uint8List(417);

  // Header (4 bytes):
  // Syncword (11 bits 1s): 0xFF, 0xFB (MPEG-1 Layer III, no CRC)
  frame[0] = 0xFF;
  frame[1] = 0xFB;
  // Bitrate 128 kbps (1001), 44100 Hz (00), padding 0, private 0 -> 0x90
  frame[2] = 0x90;
  // Mode Mono (11), mode ext 00, not copyrighted 0, original 1, emphasis none 00 -> 0xC4
  frame[3] = 0xC4;

  // Side information for mono MPEG-1: 17 bytes (frame[4..20])
  // main_data_begin = 0 (9 bits)
  // private_bits = 0 (5 bits)
  // scfsi = 0 (4 bits)
  // part2_3_length for granule 0 = 0 (12 bits)
  // part2_3_length for granule 1 = 0 (12 bits)
  // Zeroing out side info bytes 4 to 20 leaves part2_3_length = 0, meaning 0 bits of Huffman data (valid digital silence)
  // Remaining bytes (21..416) are ancillary data (all 0x00)

  return frame;
}

/// Helper to encode ID3v2 synchsafe integer (7 bits per byte)
List<int> encodeSynchsafe(int value) {
  return [
    (value >> 21) & 0x7F,
    (value >> 14) & 0x7F,
    (value >> 7) & 0x7F,
    value & 0x7F,
  ];
}

/// Builds ID3v2.3 tag with Title and Artist
List<int> buildId3v2Tag({required String title, required String artist}) {
  final frames = <int>[];

  // Helper to add text frame (TIT2, TPE1, etc.)
  void addTextFrame(String id, String text) {
    final textBytes = [0x00, ...text.codeUnits]; // 0x00 = ISO-8859-1 encoding
    frames.addAll(id.codeUnits);
    // Frame size (4 bytes big-endian)
    final size = textBytes.length;
    frames.addAll([
      (size >> 24) & 0xFF,
      (size >> 16) & 0xFF,
      (size >> 8) & 0xFF,
      size & 0xFF,
    ]);
    frames.addAll([0x00, 0x00]); // flags
    frames.addAll(textBytes);
  }

  addTextFrame('TIT2', title);
  addTextFrame('TPE1', artist);
  addTextFrame('TALB', 'Household Stratagem Tactical Audio');

  final header = <int>[
    0x49, 0x44, 0x33, // 'ID3'
    0x03, 0x00,       // version 2.3.0
    0x00,             // flags
  ];
  header.addAll(encodeSynchsafe(frames.length));

  return [...header, ...frames];
}

List<int> generateMp3({
  required String title,
  required String artist,
  int frameCount = 120, // ~3.1 seconds at 44.1 kHz
}) {
  final bytes = <int>[];
  bytes.addAll(buildId3v2Tag(title: title, artist: artist));
  final singleFrame = createMpeg1Layer3FrameMono128k44100();
  for (int i = 0; i < frameCount; i++) {
    bytes.addAll(singleFrame);
  }
  return bytes;
}

void main() {
  final mp3Bytes1 = generateMp3(
    title: 'Tactical Ambiance 1: Dark Synth Pulse',
    artist: 'Household Stratagem Sound Division',
    frameCount: 120,
  );
  final mp3Bytes2 = generateMp3(
    title: 'Tactical Ambiance 2: Heavy Bass Drone',
    artist: 'Household Stratagem Sound Division',
    frameCount: 120,
  );

  print('Track 1 generated: ${mp3Bytes1.length} bytes');
  print('Track 2 generated: ${mp3Bytes2.length} bytes');
  print('Track 1 magic: ${String.fromCharCodes(mp3Bytes1.sublist(0, 3))}');
  // First MP3 syncword check after ID3 tag
  final id3Size = (mp3Bytes1[6] << 21) | (mp3Bytes1[7] << 14) | (mp3Bytes1[8] << 7) | mp3Bytes1[9];
  final mp3Offset = 10 + id3Size;
  print('MP3 frame sync bytes at offset $mp3Offset: 0x${mp3Bytes1[mp3Offset].toRadixString(16).toUpperCase()} 0x${mp3Bytes1[mp3Offset + 1].toRadixString(16).toUpperCase()}');
}
