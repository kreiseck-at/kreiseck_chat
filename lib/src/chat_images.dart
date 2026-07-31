import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

/// Turns an image URL into an [ImageProvider].
///
/// Every remote image the chat widgets draw — bubble attachments, avatars —
/// goes through this, so a host can decide once how images are fetched and
/// cached.
typedef ChatImageProvider = ImageProvider Function(String url);

/// The default: a provider that keeps images on disk, so a thread that is
/// opened twice does not download its photos twice — and images survive a
/// restart of the app.
ImageProvider cachedChatImage(String url) => CachedNetworkImageProvider(url);

/// No caching beyond Flutter's in-memory image cache. Pass this as
/// `ChatTheme.imageProvider` for hosts that manage their own fetching, or in
/// tests.
ImageProvider plainChatImage(String url) => NetworkImage(url);
