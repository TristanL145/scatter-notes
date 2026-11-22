import 'dart:convert';

/// Supported structured content block types inside a Scatter Notes document.
enum BlockType {
  paragraph('paragraph'),
  heading('heading'),
  checklist('checklist'),
  callout('callout'),
  code('code'),
  math('math'),
  toggle('toggle'),
  table('table'),
  image('image');

  const BlockType(this.storageKey);

  /// Stable string representation stored in SQLite.
  final String storageKey;

  /// Resolves a [BlockType] from its persisted [storageKey], defaulting to
  /// [BlockType.paragraph] when unrecognized.
  static BlockType fromStorageKey(String key) {
    for (final value in BlockType.values) {
      if (value.storageKey == key) {
        return value;
      }
    }
    return BlockType.paragraph;
  }
}

/// Typed representation of a note content block used when creating, editing,
/// and indexing structured note blocks.
class NoteBlockInput {
  const NoteBlockInput({
    this.id,
    required this.type,
    this.content = const <String, dynamic>{},
  });

  /// Optional stable block ID; generated if omitted when persisting.
  final String? id;

  /// Block kind determining rendering and extraction semantics.
  final BlockType type;

  /// Arbitrary JSON-serializable attributes for this block type.
  final Map<String, dynamic> content;

  /// Serializes [content] to a JSON string for SQLite storage.
  String encodeContentJson() => jsonEncode(content);

  /// Decodes a persisted block JSON payload into a typed [NoteBlockInput].
  factory NoteBlockInput.fromPersisted({
    required String id,
    required String typeKey,
    required String contentJson,
  }) {
    final decoded = jsonDecode(contentJson);
    final map = decoded is Map<String, dynamic>
        ? decoded
        : Map<String, dynamic>.from(decoded as Map);
    return NoteBlockInput(
      id: id,
      type: BlockType.fromStorageKey(typeKey),
      content: map,
    );
  }
}

/// Extracts searchable plain text from an ordered list of [blocks] for
/// SQLite FTS5 indexing.
String extractPlainTextFromBlocks(Iterable<NoteBlockInput> blocks) {
  final buffer = StringBuffer();

  void appendValue(Object? value) {
    if (value == null) return;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        if (buffer.isNotEmpty) buffer.write(' ');
        buffer.write(trimmed);
      }
      return;
    }
    if (value is Iterable) {
      for (final item in value) {
        appendValue(item);
      }
    }
  }

  for (final block in blocks) {
    final content = block.content;
    appendValue(content['title']);
    appendValue(content['summary']);
    appendValue(content['text']);
    appendValue(content['code']);
    appendValue(content['expression']);
    appendValue(content['caption']);
    appendValue(content['rows']);
  }

  return buffer.toString();
}
