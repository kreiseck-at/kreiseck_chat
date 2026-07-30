## 0.14.0

**Behavior changes for existing users** (nothing here breaks the API — every
call site still compiles — but bubbles render differently after upgrading,
even for hosts that never touch `ChatColors` or `ChatTheme` directly):

* Timestamps and status ticks (sending/sent/delivered) no longer render in
  text color at 70% opacity; they render in the new derived muted ink
  instead. This applies to **every** theme, not only the `whatsApp`/`iMessage`
  presets. The read-receipt blue keeps its own hue only where it still
  reaches 3:1 against the bubble fill — where it doesn't, the muted ink takes
  over there too.
* The reply quote's border, sender name and quoted text are now derived from
  the bubble they sit on instead of from `ChatColors.replyAccent`, which is
  therefore deprecated and has no effect anymore (see below).
* Reaction chips are visibly bigger: they use the new `ChatTypography.reaction`
  style instead of the timestamp style and more padding (was 8/2, now 10/5).
* The failed-delivery reason line is now capped at two lines with an ellipsis
  regardless of whether `onRetry` is set (it used to wrap without limit), and
  its text — together with the retry action's — renders one point size
  larger than before.
* The `whatsApp` and `iMessage` presets no longer draw a bubble tail out of
  the box (unchanged from earlier 0.14.0 notes below) — set
  `showBubbleTail: true` to bring it back.

* New `BubbleInk` derives text/muted/line colors from a bubble's fill color
  so anything drawn on it (reply quotes, the meta row, status ticks) keeps
  its contrast target regardless of the fill; `ChatColors.inkFor(bubble)`
  looks it up, and new optional `ChatColors.incomingInk`/`.outgoingInk`
  fields let a host supply its own instead of deriving one.
* `ChatColors.replyAccent` is now `@Deprecated`: the reply quote's border,
  sender name and quoted text come from the bubble's derived ink (see above)
  and no longer read this field, so setting it has no effect. It stays in
  the constructor so existing calls keep compiling; steer the quote's colors
  via `incomingInk`/`outgoingInk` instead.
* New public `contrastRatio`/`relativeLuminance` (WCAG 2.1) and `readableOn`,
  which nudges a color that carries meaning of its own — an error red, the
  read-receipt blue — towards black or white only as far as needed to reach
  a contrast target, without losing its hue.
* `ChatColors.errorOnBackground`/`.warningOnBackground` — `error`/`warning`
  lifted to 4.5:1 against `background` via `readableOn`, for hosts whose own
  palette doesn't already reach it.
* `MessageBubble`'s failed-delivery line now shows an error icon in
  `errorOnBackground`, truncates a long reason to two lines instead of
  wrapping without limit (regardless of whether `onRetry` is set), renders
  one point size larger than before, and — together with the new
  `ChatThreadView.onRetry`/`MessageBubble.onRetry` callback — offers a retry
  action sized to a 44x44 tap target; omit `onRetry` to keep showing only
  the reason, as before.
* New `ChatTheme.showBubbleTail` (default `false`) replaces the old rule that
  drew a bubble tail whenever `bubbleStyle` wasn't `minimal`. **Behavior
  change:** the `whatsApp` and `iMessage` presets no longer show a tail out
  of the box — set `showBubbleTail: true` (e.g. via `.copyWith`) to bring it
  back.
* New `ChatTypography.reaction` text style; reaction chips now use it
  instead of the timestamp style and grow with it (more padding), and the
  compact channel icon in the bubble's meta row is larger (12 -> 15).
* Example app: a new state gallery showing every bubble state — incoming/
  outgoing, error with retry, reactions, tail on/off — alongside its
  measured contrast ratio.

## 0.13.0

* New `ChatChannel` value object describing a channel a message travelled
  over (id, label, icon, brand color), with ready-made templates —
  `ChatChannel.whatsApp()`, `.sms()`, `.email()`, `.inApp()`, `.voice()` —
  and a matching `ChatChannelBadge` widget.
* `ChatMessage` gains `channel`, `errorText` (reason for a failed delivery),
  `kind` (`ChatMessageKind.normal`/`system`/`custom`), `translation`
  (`ChatTranslation`, toggleable in the bubble), and `headline` (a bold first
  line, e.g. an email subject). `ChatConversation` gains `channels`.
* New `ChatSystemCard` — a centered card for system notes/logged events;
  messages with `kind: ChatMessageKind.system` render as this automatically
  in `ChatThreadView`.
* New `ChatBanner` (`ChatBannerVariant.info`/`.warning`) — a notice bar for
  the composer, wired up via `ChatThreadView.composerBanner`.
* `MessageBubble` renders the new `headline`, `channel` badge, `errorText`,
  and a tap-to-toggle translation switcher.
* `ChatThreadView`: new `customMessageBuilder` for `kind: ChatMessageKind.custom`
  messages (falls back to the normal bubble when it returns `null`), new
  `composerBanner`/`composerLeading` slots forwarded to the composer, and a
  new `readOnly` flag that hides the composer entirely.
* `Composer`: new `leading` slot to the left of the input field, e.g. for a
  channel picker.
* `ConversationListView`: new `onLongPress` and `titleBadgeBuilder`; each row
  now also shows a compact strip of channel badges built from
  `ChatConversation.channels` in the subtitle line (`channelBadge` still wins
  when supplied, then `channels`, then the plain `channelLabel` text).
* `ChatColors` gains `error` and `warning`.

## 0.12.0

* `Composer`: when the field is empty and the channel offers no media/mic
  affordance, a disabled send button is shown (instead of nothing), so the input
  bar never looks empty. It activates as soon as there is text or an attachment.

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
