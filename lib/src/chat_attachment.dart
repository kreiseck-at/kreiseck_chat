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
    this.contentType,
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

  /// MIME type of the full asset, e.g. `audio/ogg`, when the host knows it.
  final String? contentType;

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
      contentType: json['contentType'] as String?,
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
      if (contentType != null) 'contentType': contentType,
      if (url != null) 'url': url,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      if (fileName != null) 'fileName': fileName,
      if (sizeBytes != null) 'sizeBytes': sizeBytes,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
    };
  }

  /// Returns a copy of this attachment with the given fields replaced.
  ///
  /// For each nullable field there is a matching `clearX` flag: passing
  /// `clearX: true` sets that field to null, passing a value for the field
  /// sets it, and passing neither keeps the current value. Passing both a
  /// value and the matching `clearX: true` for the same field is a
  /// programming error and triggers an assertion.
  ChatAttachment copyWith({
    AttachmentKind? kind,
    String? contentType,
    bool clearContentType = false,
    String? url,
    bool clearUrl = false,
    ImageProvider? thumbnail,
    bool clearThumbnail = false,
    String? thumbnailUrl,
    bool clearThumbnailUrl = false,
    String? fileName,
    bool clearFileName = false,
    int? sizeBytes,
    bool clearSizeBytes = false,
    int? width,
    bool clearWidth = false,
    int? height,
    bool clearHeight = false,
  }) {
    assert(
      !(clearContentType && contentType != null),
      'clearContentType und ein contentType-Wert schließen sich aus.',
    );
    assert(
      !(clearUrl && url != null),
      'clearUrl und ein url-Wert schließen sich aus.',
    );
    assert(
      !(clearThumbnail && thumbnail != null),
      'clearThumbnail und ein thumbnail-Wert schließen sich aus.',
    );
    assert(
      !(clearThumbnailUrl && thumbnailUrl != null),
      'clearThumbnailUrl und ein thumbnailUrl-Wert schließen sich aus.',
    );
    assert(
      !(clearFileName && fileName != null),
      'clearFileName und ein fileName-Wert schließen sich aus.',
    );
    assert(
      !(clearSizeBytes && sizeBytes != null),
      'clearSizeBytes und ein sizeBytes-Wert schließen sich aus.',
    );
    assert(
      !(clearWidth && width != null),
      'clearWidth und ein width-Wert schließen sich aus.',
    );
    assert(
      !(clearHeight && height != null),
      'clearHeight und ein height-Wert schließen sich aus.',
    );
    return ChatAttachment(
      kind: kind ?? this.kind,
      contentType: clearContentType ? null : (contentType ?? this.contentType),
      url: clearUrl ? null : (url ?? this.url),
      thumbnail: clearThumbnail ? null : (thumbnail ?? this.thumbnail),
      thumbnailUrl: clearThumbnailUrl
          ? null
          : (thumbnailUrl ?? this.thumbnailUrl),
      fileName: clearFileName ? null : (fileName ?? this.fileName),
      sizeBytes: clearSizeBytes ? null : (sizeBytes ?? this.sizeBytes),
      width: clearWidth ? null : (width ?? this.width),
      height: clearHeight ? null : (height ?? this.height),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatAttachment &&
        other.kind == kind &&
        other.contentType == contentType &&
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
    contentType,
    url,
    thumbnail,
    thumbnailUrl,
    fileName,
    sizeBytes,
    width,
    height,
  );
}
