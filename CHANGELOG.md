## 0.11.0

* `ChatThreadView`: opening a thread now reliably lands at the very bottom. A
  lazy `ListView.builder` doesn't know its full extent on the first frame, so a
  single jump fell short; the view now re-snaps to the bottom across several
  frames until the extent stabilizes.

## 0.10.0

* `ConversationListView`: new `channelBadge` builder renders a small badge on the
  bottom-right of each avatar (e.g. a channel marker) and hides the textual
  channel-label chip when supplied.
* `MailListView`: new optional `badge` shows a leading sender avatar (initials)
  with a bottom-right badge, so mail rows can carry the same channel marker.

## 0.9.0

* `MessageBubble`: album images now fade in over a neutral placeholder (via
  `Image.frameBuilder`) so a freshly opened thread no longer flashes empty tiles.
* `MessageBubble` / `ChatThreadView`: new `onOpenImages(images, index)` callback,
  fired when an album image is tapped, so the host can open a swipeable
  full-screen gallery. `onOpenAttachment` now only fires for non-image files.
* `MessageBubble`: the long-press context menu is themed — surface color from
  `ChatColors.composer`, rounded corners, and item text/icons in the bubble
  text color.

## 0.8.0

* `MessageBubble`: images now render as a WhatsApp-style **album** — a single
  wide image or a 2-column grid for multiple, with a "+N" overlay past four,
  tap-to-open via `onOpenAttachment`. Image bubbles use a much tighter frame
  (near edge-to-edge) with the caption/timestamp padded below.
* `MessageBubble`: long-press now opens a **context menu anchored at the press
  position** (`showMenu`) instead of a bottom sheet.
* `ChatThreadView`: tapping the conversation background dismisses the keyboard.

## 0.7.0

* `Composer`: multi-attachment preview. Replaces the single `attachmentPreview`
  with `attachmentPreviews` (a `List<ImageProvider>`) shown as a horizontal row
  of removable thumbnails plus a trailing "+" tile; new `onRemoveAttachmentAt`
  and `onAddAttachment` callbacks. `ChatThreadView` forwards all three. **Breaking:**
  `attachmentPreview`/`onRemoveAttachment` are gone.
* `ChatThreadView`: auto-scroll now re-snaps to the bottom on the next frame and
  after a short delay, so image bubbles and the collapsing composer preview no
  longer leave the thread scrolled short of the newest message.

## 0.6.0

* `Composer`: new `attachmentPreview` (an `ImageProvider`) + `onRemoveAttachment`
  — when set, a thumbnail with a remove (×) button appears above the input and
  the send button stays active with an empty text field, so a picked photo can
  be sent with or without a caption. The caller owns the file/upload and pairs
  the attachment with `onSend`'s text. `ChatThreadView` forwards both.

## 0.5.0

* `MessageBubble`: the send-status row (time + delivery ticks) now renders on
  every outgoing message, not only the last one of a group.
* `MessageBubble` / `ChatThreadView`: long-pressing a bubble now offers a **Copy**
  action alongside reply/react (where supported). New `onCopy` callback fires
  after the text is copied to the clipboard, the action menu opens whenever a
  bubble has copyable text, and a themeable `ChatIcons.copy` icon was added.

## 0.4.0

* `Composer`: WhatsApp-style input — Enter inserts a newline (new `sendOnEnter`
  flag to opt back in), sentence auto-capitalization (`textCapitalization`), the
  send button now appears only while typing, and a dedicated camera shortcut
  replaces the mic slot when the field is empty.
* New `ChatAvatar` widget with a phone-number-aware fallback: contacts that are
  bare phone numbers get a neutral person icon instead of a "+" monogram
  (`isPhoneNumberLike` exposed). Used by `ChatHeader` and `ConversationListView`.
* `ChatColors.readReceipt` — read double-checks now render in a dedicated blue,
  independent of a branded/green `accent`.

## 0.3.0

* Add `ChatCapabilities` capability profiles (`twilioSms`, `twilioWhatsApp`,
  `inApp`, custom) that gate which affordances widgets render.
* Richer models: `ChatParticipant`, `ChatPresence`, `ChatAttachment`,
  `MessageReaction`, `ChatMessageRef`, `TypingState`; `ChatMessage` gains
  `sender`, typed `attachments`, `replyTo`, `reactions`, and receipt timestamps.
* **Breaking:** `ChatMessage.attachments` is now `List<ChatAttachment>` (was
  `List<String>`).
* Layered `ChatTheme` (`ChatColors`, `ChatTypography`, `ChatIcons`,
  `ChatMotion`, `BubbleStyle`) with `whatsApp`/`iMessage` presets; old flat
  getters preserved.
* New widgets: `TypingIndicator`, `DateSeparator`, `ChatHeader`; rewritten
  `MessageBubble`, `Composer`, `ChatThreadView`, `ConversationListView` with
  grouping, reactions, replies, media, presence, and motion/haptics.

## 0.2.0

Mail-Modelle und -Widgets

* `MailDirection`, `MailAttachment`, `MailAccountRef` und `MailMessage` Modelle.

## 0.1.0

Initial release.

* `ChatMessage` and `ChatConversation` models.
* `ChatTheme` with `light()` and `dark()` presets.
* `MessageBubble`, `Composer`, `ChatThreadView` and `ConversationListView` widgets.
