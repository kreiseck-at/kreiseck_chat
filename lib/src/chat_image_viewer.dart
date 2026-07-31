import 'package:flutter/material.dart';

import 'chat_theme.dart';

/// Opens [urls] full screen: pinch to zoom, swipe between them, tap to close.
///
/// [index] is the one that was tapped. Images are fetched through
/// [ChatTheme.imageProvider], so they come from the same cache the thread
/// already filled — a photo opened from a bubble does not download twice.
Future<void> showChatImageViewer(
  BuildContext context, {
  required List<String> urls,
  int index = 0,
  ChatTheme theme = const ChatTheme.light(),
}) {
  if (urls.isEmpty) return Future<void>.value();
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black,
    builder: (_) => _ChatImageViewer(urls: urls, index: index, theme: theme),
  );
}

class _ChatImageViewer extends StatefulWidget {
  const _ChatImageViewer({
    required this.urls,
    required this.index,
    required this.theme,
  });

  final List<String> urls;
  final int index;
  final ChatTheme theme;

  @override
  State<_ChatImageViewer> createState() => _ChatImageViewerState();
}

class _ChatImageViewerState extends State<_ChatImageViewer> {
  late int _current = widget.index.clamp(0, widget.urls.length - 1);
  late final PageController _pages = PageController(initialPage: _current);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Without a Material ancestor there is no text style, and Flutter paints
    // the notorious yellow double underlines under every piece of text.
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Stack(
          children: [
            Positioned.fill(
              child: PageView.builder(
                controller: _pages,
                itemCount: widget.urls.length,
                onPageChanged: (i) => setState(() => _current = i),
                itemBuilder: (_, i) => InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Center(
                    child: Image(
                      image: widget.theme.imageProvider(widget.urls[i]),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white54,
                          size: 40),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 44,
              right: 12,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            // A counter only earns its place when there is something to swipe.
            if (widget.urls.length > 1)
              Positioned(
                top: 52,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '${_current + 1} / ${widget.urls.length}',
                    style: widget.theme.typography.timestamp
                        .copyWith(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
