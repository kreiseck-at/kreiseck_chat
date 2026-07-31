## 0.15.0

**Behavior changes for existing users:**

* Every word the widgets put on screen — reply/copy/original, retry,
  today/yesterday, the composer's placeholder and attachment-source labels,
  the typing indicator, presence/last-seen wording, and the mail widgets'
  subject/to/body/spam/"possible spam"/"no mail yet" labels — used to be
  hard-coded German (or, for "No mail yet", English) text. It now comes from
  the new `ChatStrings`, resolved from the ambient `Locale`
  (`Localizations.maybeLocaleOf(context)`) via each widget's new optional
  `strings` parameter — a host that already sets its app `locale` needs to
  pass nothing. **A host that never set an app locale before will now see
  English instead of German**: English, not German, is `ChatStrings`'
  fallback for an unset or unsupported locale. One exception: `ChatChannel`'s
  templates (`.whatsApp()`, `.sms()`, `.email()`, `.inApp()`, `.voice()`)
  carry their own `label` (e.g. "Anruf" for `.voice()`) — channel names are
  caller-supplied data on a `const` value object, not `ChatStrings` wording,
  so they don't follow the ambient locale; override `label` per instance if
  you need a translated one.
* `ChatStrings` is new in this release, so there is no prior public API to
  stay compatible with. Its main constructor takes all twenty-three fields as
  `required` — build one by hand only if you need a mix no language preset
  offers; the five presets (`ChatStrings.en()` … `ChatStrings.uk()`) are the
  recommended way to get a full set and need nothing added at a call site.
* `ChatHeader.typingLabel` and `ConversationListView.typingLabel` (the
  per-instance override, not the private per-row field) changed from
  `String` to `String?` so leaving it unset falls through to
  `ChatStrings.typing` instead of forcing a value. This is the one
  signature change in this release that isn't purely additive; every
  existing call site that passed a `String` still compiles unchanged.
* `PresenceLabels`' German defaults are unchanged, so existing direct calls
  to `formatPresenceLabel` keep behaving exactly as before. What changed is
  `ChatHeader`: its presence subtitle used to call `formatPresenceLabel`
  with the German defaults regardless of locale; it now builds its
  `PresenceLabels` from the same resolved `ChatStrings` as everything else
  it renders, via the new `PresenceLabels.fromStrings`.

* New `ChatStrings` — twenty-three strings (`reply`, `copy`, `original`,
  `retry`, `today`, `yesterday`, `messageHint`, `send`, `camera`, `gallery`,
  `file`, `typing`, `spam`, `subject`, `to`, `possibleSpam`, `online`,
  `lastSeenTodayPrefix`, `lastSeenYesterdayPrefix`, `lastSeenDatePrefix`,
  `lastSeenAtJoiner`, `noMailYet`, `body`) in five languages (`.en()`,
  `.de()`, `.hr()`, `.tr()`, `.uk()`), matched to the ambient locale via
  `ChatStrings.forLocale`/`ChatStrings.of`. `possibleSpam` is the sentence
  shown in an opened mail's header ("Possible spam"), distinct from the
  short `spam` tag shown in a mail list row; `online`/`lastSeen*` are the
  presence wording also used by `PresenceLabels.fromStrings` (see below);
  `noMailYet` is the empty-state text in `MailListView`; `body` is the
  message-body field's label in `MailComposer`. `ChatThreadView`,
  `DateSeparator`, `MessageBubble`, `Composer`, `ChatHeader`,
  `ConversationListView`, `MailListView`, `MailDetailView`, and
  `MailComposer` each gained (or, for `ChatThreadView`, newly gained) an
  optional `strings: ChatStrings?` parameter to override individual words
  without touching the ambient locale; `ChatThreadView` forwards its
  `strings` to the `MessageBubble`, `DateSeparator`, and `Composer` it
  renders.
* New `PresenceLabels.fromStrings(ChatStrings)` builds a `PresenceLabels`
  from a `ChatStrings`' five presence fields. New `PresenceLabels`
  field `lastSeenAtJoiner` (default `' um '`, matching the previous
  hard-coded joiner) — the word(s) between an older last-seen date and its
  time, e.g. `' um '` in `'zuletzt gesehen am 3.2.2026 um 14:30'`; it used
  to be an inline literal with no way to override it. For Turkish this is
  deliberately a single space rather than a word (see
  `ChatStrings.tr().lastSeenAtJoiner`).
* A widget returned by `ChatThreadView.customMessageBuilder` is now inset
  like a bubble (12 to each side, a little air above and below) instead of
  being laid out flush against the viewport edge.
* `MessageBubble` now renders a message's attachments regardless of
  `ChatCapabilities.media`, which from now on only governs the composer's
  attach affordances. A thread that mixes channels (a photo received over
  WhatsApp while the composer is set to SMS) used to hide the photo
  outright.
* `ChatThreadView` now draws its list reversed (`reverse: true`), so the
  newest message sits at scroll offset 0. This replaces every scroll
  correction the view used to run — the multi-frame settle on open, the
  delayed re-snap after sending, the jump on new messages. A thread now
  opens at the bottom, stays there while an image finishes loading or the
  keyboard opens, and keeps its place when the reader has scrolled up. On
  screen nothing moved: messages still run oldest to newest, top to bottom.
  `onLoadEarlier` now fires at the end of the scroll extent (the oldest
  message), not at offset 0.
* `ChatThreadView.groupMedia` (new, **on by default**): consecutive
  image-only messages going the same direction and within five minutes of
  each other are folded into one album bubble via the new public
  `groupMediaRuns`. Channels that carry one photo per message (MMS,
  WhatsApp) would otherwise fill the thread with one bubble per photo. The
  merged message keeps the first message's id and the last one's timestamp
  and status. Pass `groupMedia: false` for the old one-bubble-per-message
  rendering.
* `ConversationListView` now emphasizes an unread row: bold title, preview
  at full opacity instead of 60%. Rows with `unread == 0` are unchanged, so
  a host that never sets `unread` sees no difference.
* New `ConversationListView.timeLabelBuilder` and `unreadStyle`. The row can
  now end with a time — the host formats it, since date formatting is its
  business and this package brings no date library — and an unread
  conversation can be marked with a plain dot (`UnreadStyle.dot`) instead of
  a count, for hosts whose unread state is a yes/no and whose badge would
  therefore only ever read "1". Defaults are unchanged: no time, count
  badge.
* New `ChatColors.incomingBubbleBorder` / `outgoingBubbleBorder` (both
  `null` in the presets, so bubbles stay borderless as before): a hairline
  around the bubble. For palettes whose bubble fill sits close to the
  background — a near-white incoming bubble on a white thread would
  otherwise have no edge at all. `copyWith` takes the matching
  `clearIncomingBubbleBorder` / `clearOutgoingBubbleBorder` switches.
* New `textBuilder` on `MessageBubble` and `ChatThreadView` (which forwards
  it to every bubble): renders the message body instead of the built-in
  plain `Text`, called with the text currently shown and the style the
  bubble would have used. For linkified or otherwise rich message text —
  previously the only way to get tappable links in a bubble was to not use
  the bubble.
* New `ChatTranslation.showFirst` (default `false`, so nothing changes for
  existing callers): the bubble opens on the translation rather than the
  original, putting the original one tap away. For readers who picked a
  language they prefer to read in — an inbox that translates incoming
  messages into the reader's language wants the translation in front.
* `copyWith` on `ChatMessage`, `ChatMessageRef`, `ChatConversation`,
  `ChatPresence`, `ChatParticipant`, `ChatAttachment`, and `MailMessage`
  gained a `clearX` switch (e.g. `clearAvatarUrl: true`) for every nullable
  field, so a field can be reset to `null` — something `field ?? this.field`
  alone can't express, since there is no way to tell "leave it" apart from
  "set it back to null" through that value alone. Passing both `clearX:
  true` and a non-null value for the same field is a programming error and
  triggers an assertion.

## 0.14.0

**Behavior changes for existing users** (nothing here breaks the API — every
call site still compiles — but bubbles render differently after upgrading,
even for hosts that never touch `ChatColors` or `ChatTheme` directly):

* Timestamps and status ticks (sending/sent/delivered) no longer render in
  text color at 70% opacity; they render in the new derived muted ink
  instead. This applies to **every** theme, not only the `whatsApp`/`iMessage`
  presets. The read-receipt blue is nudged towards black or white until it
  reaches 3:1 against the bubble fill, keeping its own hue; it is never
  replaced by the muted ink.
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
* `BubbleInk.forSurface` gained an optional `textColor` parameter, and
  `ChatColors.inkFor` now passes it (`outgoingText`/`incomingText`) so a
  bubble's derived timestamp, reply name and quote bar follow the polarity
  of the message text actually painted on it, instead of independently
  picking whichever of black/white contrasts more. `line` still guarantees
  3:1; `text`/`muted` reach 4.5:1 wherever that polarity allows it, and fall
  back to that same 3:1 floor where it doesn't. On the standard blue
  `#3478F6` outgoing bubble with white `outgoingText`, this deliberately
  caps `text` around 4.07:1 and `muted` around 3:1 instead of the usual
  4.5:1 — a known trade-off in favor of one consistent, non-clashing tone
  across the bubble rather than maximum contrast; `forSurface` still falls
  back to the higher-contrast polarity when the requested one can't clear
  even 3:1.
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
