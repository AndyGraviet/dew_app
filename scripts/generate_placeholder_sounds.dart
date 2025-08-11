import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;

/// Generates simple placeholder sound files for testing
/// These should be replaced with actual sound files in production
void main() {
  print('Generating placeholder sound files...');
  
  // Create very simple WAV files as placeholders
  // In production, replace these with actual sound files
  
  // Create tick sound placeholder
  createPlaceholderWav('assets/sounds/tick.wav', duration: 0.1, frequency: 1000);
  
  // Create timer complete sound placeholder  
  createPlaceholderWav('assets/sounds/timer_complete.wav', duration: 0.5, frequency: 800);
  
  print('✅ Placeholder sound files created');
  print('Note: Replace these with actual sound files for production');
}

void createPlaceholderWav(String filename, {required double duration, required double frequency}) {
  final file = File(filename);
  
  // WAV file parameters
  const sampleRate = 44100;
  const bitsPerSample = 16;
  const channels = 1;
  
  final numSamples = (sampleRate * duration).round();
  final dataSize = numSamples * (bitsPerSample ~/ 8);
  
  // Generate a simple sine wave
  final samples = Uint8List(dataSize);
  for (int i = 0; i < numSamples; i++) {
    final value = (32767 * math.sin(2 * math.pi * frequency * i / sampleRate)).round();
    // Little-endian 16-bit
    samples[i * 2] = value & 0xFF;
    samples[i * 2 + 1] = (value >> 8) & 0xFF;
  }
  
  // Create WAV header
  final header = BytesBuilder();
  
  // RIFF header
  header.add('RIFF'.codeUnits);
  header.add(_int32ToBytes(36 + dataSize)); // File size - 8
  header.add('WAVE'.codeUnits);
  
  // fmt chunk
  header.add('fmt '.codeUnits);
  header.add(_int32ToBytes(16)); // Chunk size
  header.add(_int16ToBytes(1)); // Audio format (PCM)
  header.add(_int16ToBytes(channels)); // Number of channels
  header.add(_int32ToBytes(sampleRate)); // Sample rate
  header.add(_int32ToBytes(sampleRate * channels * (bitsPerSample ~/ 8))); // Byte rate
  header.add(_int16ToBytes(channels * (bitsPerSample ~/ 8))); // Block align
  header.add(_int16ToBytes(bitsPerSample)); // Bits per sample
  
  // data chunk
  header.add('data'.codeUnits);
  header.add(_int32ToBytes(dataSize));
  
  // Write file
  file.writeAsBytesSync([...header.toBytes(), ...samples]);
}

Uint8List _int32ToBytes(int value) {
  return Uint8List(4)
    ..[0] = value & 0xFF
    ..[1] = (value >> 8) & 0xFF
    ..[2] = (value >> 16) & 0xFF
    ..[3] = (value >> 24) & 0xFF;
}

Uint8List _int16ToBytes(int value) {
  return Uint8List(2)
    ..[0] = value & 0xFF
    ..[1] = (value >> 8) & 0xFF;
}