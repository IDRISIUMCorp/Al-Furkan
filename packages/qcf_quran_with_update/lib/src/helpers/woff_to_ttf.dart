import 'dart:io';
import 'dart:typed_data';

/// Converts WOFF 1.0 font data to raw TTF (TrueType / OpenType SFNT) data.
///
/// WOFF wraps SFNT tables with optional zlib compression per-table.
/// Flutter's [FontLoader] only understands raw TTF/OTF on non-web platforms,
/// so we must decode WOFF → SFNT before feeding bytes to the engine.
///
/// Reference: https://www.w3.org/TR/WOFF/
Uint8List woffToTtf(Uint8List woffBytes) {
  final woff = ByteData.sublistView(woffBytes);

  // ── WOFF Header (44 bytes) ──
  final signature = woff.getUint32(0); // 'wOFF'
  if (signature != 0x774F4646) {
    // Not WOFF — assume it's already raw TTF/OTF, return as-is
    return woffBytes;
  }

  final flavor = woff.getUint32(4); // The SFNT "flavor" (e.g. 0x00010000 for TrueType)
  // final woffLength    = woff.getUint32(8);
  final numTables = woff.getUint16(12);
  // final reserved      = woff.getUint16(14); // must be 0
  final totalSfntSize = woff.getUint32(16);
  // remaining header fields (version, metaOffset, etc.) not needed

  // ── Parse WOFF Table Directory ──
  // Each entry is 20 bytes, located right after the 44-byte header.
  final tables = <_WoffTableEntry>[];
  for (int i = 0; i < numTables; i++) {
    final off = 44 + i * 20;
    tables.add(_WoffTableEntry(
      tag: woff.getUint32(off),
      woffOffset: woff.getUint32(off + 4),
      compLength: woff.getUint32(off + 8),
      origLength: woff.getUint32(off + 12),
      origChecksum: woff.getUint32(off + 16),
    ));
  }

  // ── Reconstruct the SFNT (TTF/OTF) binary ──
  final out = BytesBuilder(copy: false);

  // SFNT Offset Table (12 bytes)
  final sfntHeader = ByteData(12);
  sfntHeader.setUint32(0, flavor);
  sfntHeader.setUint16(4, numTables);

  // Calculate searchRange, entrySelector, rangeShift
  int searchRange = 1;
  int entrySelector = 0;
  while (searchRange * 2 <= numTables) {
    searchRange *= 2;
    entrySelector++;
  }
  searchRange *= 16;
  final rangeShift = numTables * 16 - searchRange;

  sfntHeader.setUint16(6, searchRange);
  sfntHeader.setUint16(8, entrySelector);
  sfntHeader.setUint16(10, rangeShift);
  out.add(sfntHeader.buffer.asUint8List());

  // SFNT Table Records (16 bytes each)
  // We need to calculate offsets, which start after header + table records.
  int dataOffset = 12 + numTables * 16;

  // Sort tables by tag for the table directory (SFNT spec recommendation)
  tables.sort((a, b) => a.tag.compareTo(b.tag));

  // First pass: decompress all table data and compute padded sizes
  final decompressedTables = <Uint8List>[];
  final tableOffsets = <int>[];

  for (final t in tables) {
    final Uint8List raw;
    if (t.compLength < t.origLength) {
      // Table is zlib-compressed → decompress
      final compressed = woffBytes.sublist(t.woffOffset, t.woffOffset + t.compLength);
      raw = Uint8List.fromList(zlib.decode(compressed));
    } else {
      // Table is stored uncompressed
      raw = woffBytes.sublist(t.woffOffset, t.woffOffset + t.origLength);
    }

    tableOffsets.add(dataOffset);
    decompressedTables.add(raw);

    // Each table must be 4-byte aligned in the SFNT
    final padded = (raw.length + 3) & ~3;
    dataOffset += padded;
  }

  // Write SFNT Table Records
  for (int i = 0; i < tables.length; i++) {
    final rec = ByteData(16);
    rec.setUint32(0, tables[i].tag);
    rec.setUint32(4, tables[i].origChecksum);
    rec.setUint32(8, tableOffsets[i]);
    rec.setUint32(12, decompressedTables[i].length);
    out.add(rec.buffer.asUint8List());
  }

  // Write Table Data (4-byte padded)
  for (final data in decompressedTables) {
    out.add(data);
    final pad = (4 - (data.length % 4)) % 4;
    if (pad > 0) {
      out.add(Uint8List(pad)); // zero padding
    }
  }

  return out.toBytes();
}

class _WoffTableEntry {
  final int tag;
  final int woffOffset;
  final int compLength;
  final int origLength;
  final int origChecksum;

  _WoffTableEntry({
    required this.tag,
    required this.woffOffset,
    required this.compLength,
    required this.origLength,
    required this.origChecksum,
  });
}
