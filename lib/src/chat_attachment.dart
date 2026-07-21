import 'package:flutter/widgets.dart';

/// The kind of content an attachment carries.
enum AttachmentKind { image, video, file, audio }

/// A media/file attachment on a chat message.
///
/// Backend-agnostic: it carries references, not bytes. Provide [thumbnail] (an
/// in-memory image) or [thumbnailUrl] for a preview; [url] points at the full
/// asset the host opens.
class ChatAttachment {
  /// Creates an attachment.
  const ChatAttachment({
    required this.kind,
    this.url,
    this.thumbnail,
    this.thumbnailUrl,
    this.fileName,
    this.sizeBytes,
    this.width,
    this.height,
  });

  /// Content kind.
  final AttachmentKind kind;

  /// URL of the full asset.
  final String? url;

  /// In-memory preview image; wins over [thumbnailUrl] when both are set.
  final ImageProvider? thumbnail;

  /// Remote preview URL; used when [thumbnail] is null.
  final String? thumbnailUrl;

  /// Display file name, e.g. `invoice.pdf`.
  final String? fileName;

  /// File size in bytes, if known.
  final int? sizeBytes;

  /// Pixel width, if known (used to size image bubbles).
  final int? width;

  /// Pixel height, if known.
  final int? height;

  /// Creates an attachment from a JSON-decoded map. The in-memory [thumbnail]
  /// provider is not part of JSON.
  factory ChatAttachment.fromJson(Map<String, dynamic> json) {
    return ChatAttachment(
      kind: AttachmentKind.values.byName(json['kind'] as String),
      url: json['url'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      fileName: json['fileName'] as String?,
      sizeBytes: json['sizeBytes'] as int?,
      width: json['width'] as int?,
      height: json['height'] as int?,
    );
  }

  /// Converts to a JSON-encodable map (excludes the in-memory [thumbnail]).
  Map<String, dynamic> toJson() {
    return {
      'kind': kind.name,
      if (url != null) 'url': url,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      if (fileName != null) 'fileName': fileName,
      if (sizeBytes != null) 'sizeBytes': sizeBytes,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
    };
  }

  /// Returns a copy with the given fields replaced.
  ChatAttachment copyWith({
    AttachmentKind? kind,
    String? url,
    ImageProvider? thumbnail,
    String? thumbnailUrl,
    String? fileName,
    int? sizeBytes,
    int? width,
    int? height,
  }) {
    return ChatAttachment(
      kind: kind ?? this.kind,
      url: url ?? this.url,
      thumbnail: thumbnail ?? this.thumbnail,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fileName: fileName ?? this.fileName,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatAttachment &&
        other.kind == kind &&
        other.url == url &&
        other.thumbnail == thumbnail &&
        other.thumbnailUrl == thumbnailUrl &&
        other.fileName == fileName &&
        other.sizeBytes == sizeBytes &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode => Object.hash(
        kind,
        url,
        thumbnail,
        thumbnailUrl,
        fileName,
        sizeBytes,
        width,
        height,
      );
}
