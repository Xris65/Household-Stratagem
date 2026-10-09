import 'dart:io';
import 'dart:typed_data';

/// Minimal valid MPEG-1 Layer III frame generator (128 kbps, 44.1 kHz, mono)
List<int> createMpeg1Layer3FrameMono128k44100() {
  final frame = Uint8List(417);
  // Header: 0xFF 0xFB 0x90 0xC4
  frame[0] = 0xFF; // Syncword
  frame[1] = 0xFB; // MPEG-1 Layer III, no CRC
  frame[2] = 0x90; // 128 kbps, 44100 Hz, no padding
  frame[3] = 0xC4; // Mono, not copyrighted, original, no emphasis
  // Side info (bytes 4..20) and audio data (bytes 21..416) remain 0s (digital silence / valid frames)
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

/// Builds ID3v2.3 tag with Title, Artist, and Album metadata
List<int> buildId3v2Tag({
  required String title,
  required String artist,
  required String album,
}) {
  final frames = <int>[];

  void addTextFrame(String id, String text) {
    final textBytes = [0x00, ...text.codeUnits]; // ISO-8859-1
    frames.addAll(id.codeUnits);
    final size = textBytes.length;
    frames.addAll([
      (size >> 24) & 0xFF,
      (size >> 16) & 0xFF,
      (size >> 8) & 0xFF,
      size & 0xFF,
    ]);
    frames.addAll([0x00, 0x00]); // Flags
    frames.addAll(textBytes);
  }

  addTextFrame('TIT2', title);
  addTextFrame('TPE1', artist);
  addTextFrame('TALB', album);

  final header = <int>[
    0x49, 0x44, 0x33, // 'ID3'
    0x03, 0x00,       // version 2.3.0
    0x00,             // flags
  ];
  header.addAll(encodeSynchsafe(frames.length));

  return [...header, ...frames];
}

/// Generates valid MP3 binary bytes
List<int> generateMp3Binary({
  required String title,
  required String artist,
  required String album,
  int frameCount = 120, // ~3.13 seconds of 44.1 kHz audio
}) {
  final tag = buildId3v2Tag(title: title, artist: artist, album: album);
  final singleFrame = createMpeg1Layer3FrameMono128k44100();
  final builder = BytesBuilder();
  builder.add(tag);
  for (int i = 0; i < frameCount; i++) {
    builder.add(singleFrame);
  }
  return builder.toBytes();
}

void main(List<String> args) {
  final outputDir = args.isNotEmpty ? args[0] : 'sample_assets';
  final dir = Directory(outputDir);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  final track1 = generateMp3Binary(
    title: 'Tactical Ambiance 1: Dark Synth Pulse',
    artist: 'Household Stratagem Sound Division',
    album: 'Household Stratagem Tactical Audio',
    frameCount: 150, // ~3.9 seconds
  );

  final track2 = generateMp3Binary(
    title: 'Tactical Ambiance 2: Heavy Cyber Bass Drone',
    artist: 'Household Stratagem Sound Division',
    album: 'Household Stratagem Tactical Audio',
    frameCount: 150, // ~3.9 seconds
  );

  final file1 = File('${dir.path}/tactical_ambiance_1.mp3');
  final file2 = File('${dir.path}/tactical_ambiance_2.mp3');

  file1.writeAsBytesSync(track1);
  file2.writeAsBytesSync(track2);

  print('Successfully generated:');
  print('  ${file1.path} (${file1.lengthSync()} bytes)');
  print('  ${file2.path} (${file2.lengthSync()} bytes)');
}
