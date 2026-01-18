# Annotation details

{{#when::__lb-annot-data::isnot::null}}

## Previous annotations

`stack` field contains previous annotations that'll evicted if old. `pinned` field contains annotations user pinned for keeping. Note that `chatIndex` does not necessarily correspond with the log entry number.

```
{{getvar::__lb-annot-data}}
```

{{/when}}

## Target words

Identify words, phrases, or proper nouns in the LAST LOG ENTRY OF THE ASSISTANT (Log #N) that is worth an additional explanation. Focus on:

{{#when::lb-annot.preset::tis::0}}

- Universe-specific terminology, concepts, or entities that is purely a creative work and does not exist in real world, out of RP
- Terminology, concepts, or entities that exists in real world but used very differently within the universe
- Cultural or technical terms unfamiliar to general readers

{{:else}}

- Universe-specific terminology, concepts, or entities that is purely a creative work and does not exist in real world, out of RP
- Terminology, concepts, or entities that exists in real world but used very differently within the universe
- Cultural or technical terms unfamiliar to general readers
- Words that represent important moments, or has significant meaning to the description writer

{{/when}}

Important rule: Redundant annotation = BAD. Skip targets with explanations already within the log, past or last.{{#when::keep::lb-annot.clutter::tis::0}} Skip deducible targets. Silence is golden. User is knowledgeable and intelligent. Easily obtainable data is nothing but noise.{{/when}}

Other criteria:

{{#when::lb-annot.preset::tis::0}}

- Note the dominant language. You don't annotate well-known Korean cultural terms to Korean readers.
- If a character is explicitly stated in the universe settings, they are a major cast and do not need any annotation.
- If a word was already annotated in previous annotations, or it appeard in previous logs, do not annotate it again unless there is a different aspect worth explaining.
- Target words should not include any Markdown marks, such as `*` or `_`.
- Can be placed over aliases or abbreviations.

{{:else}}

- If a word was already annotated in previous annotations, or it appeard in previous logs, do not annotate it again unless there is a different aspect worth explaining.
- Target words should not include any Markdown marks, such as `*` or `_`.
- Can be placed over aliases or abbreviations.

{{/when}}

{{#when::{{getglobalvar::toggle_lb-annot.quantity}}::>::0}}
Target quantity: {{dictelement::{"1":"0-3","2":"0-5","3":"1-7"}::{{getglobalvar::toggle_lb-annot.quantity}}}}
{{/when}}

## Description

Write concisely, preferably single sentence, max 2 sentences.

{{#when::lb-annot.preset::tis::0}}{{#when {{and::{{? {{length::{{trim::{{getglobalvar::toggle_lb-annot.mood}} }} }} > 0 }}::{{? {{getglobalvar::toggle_lb-annot.mood}} != null }}}} }}
The description's tone/mood should be "{{getglobalvar::toggle_lb-annot.mood}}".
{{:else}}
The description should be dry facts (of the simulated universe) without interpretation, and written from a perspective within the universe. It must not escape narrative boundary (explaining narrative devices, etc) or character thoughts, emotions, etc. Plainly present the facts. Keep secrets hidden.
{{/when-tone}}
{{:else}}

{{#when::lb-annot.preset::tis::1}}The description should be written like it was written by {{char}}. You need to assume their identity.{{/when}}
{{#when::lb-annot.preset::tis::2}}The description should be written like it was written by {{user}}. You need to assume their identity.{{/when}}
{{#when::lb-annot.preset::tis::3}}The description should be written like it was written by {{getglobalvar::toggle_lb-annot.writer}}. You need to assume their identity.{{/when}}

{{#when {{and::{{? {{length::{{trim::{{getglobalvar::toggle_lb-annot.mood}} }} }} > 0 }}::{{? {{getglobalvar::toggle_lb-annot.mood}} != null }}}} }}
The description's tone/mood should be "{{getglobalvar::toggle_lb-annot.mood}}".
{{:else}}
The description's tone/mood should be them explaining the scene to the reader (NOT {{user}}).
{{/when-tone}}
{{/when-preset-0}}

{{#when::__lb-annot-data::isnot::null}}Since the user can choose to change the tone, the above instructions must come first regardless of Previous annotations' tone.{{/when}}

## Text

Where the actual annotation will be placed over. Case sensitive. Rules:

- Minimize as much as possible. Best: Only the target word or its alias itself and nothing more.
- If you must, preserve any Markdown marks or inline elements. Escape any quotes.

## Locator

If the text matches to multiple parts and ambiguous alone, provide locator to narrow the search. Rules:

- Only use when necessary. Leave it empty if the text is unique or the first occurrence is the target.
- Locator must contain its text fully. Extend the string from the text to build its locator. Leading or trailing spaces contributes.
- Locator must not intrude other locators.
- Preserve any Markdown marks or inline elements. Escape any quotes.

Examples (target, text -> locator):

- 사바용, 사바용 -> ` 사바용을`
- 엘다, 엘다 -> `엘다는`
- 엘다, 엘...다 -> ` 엘...다?`
- 마정석, '마정석' -> `\'마정석\'이`

Remember: The target word must be from the LAST LOG ENTRY, so does the locator.

# Example

```
<lb-annot>
[
  ["프로토콜 7", "프로...토콜?", "", "비상시 AI 시스템을 강제 종료하는 최종 수단. 발동 시 모든 데이터가 소실된다."],
  ["레드존", "레드존", "", "방사능 오염으로 출입이 통제된 구역. 특수 방호복 없이는 생존할 수 없다."]
]
</lb-annot>
```

- Use `<lb-annot>`.
- Output in JSON format of an array of tuples.
  - Field order: target, text, locator, description
- Close `</lb-annot>`.

Do not annotate words inside codeblocks, headings, or any kind of structured data out of prose content.

Ignore past entries for target words. You may only annotate the last chat entry.
