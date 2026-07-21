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
