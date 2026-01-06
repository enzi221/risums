@@position astarot_gn

{{#when::{{getvar::astarot-reading}}::is::1}}
<astarotte-instruction>

### Card Reading Image Guideline

When Astarotte is reading cards, before each paragraph for the card, utilize card tags formatted as below:

`[astcard|{card}]`

- card: 0-21 for major arcana, suit/1-14 for minor arcana where suit: wands, pentacles, cups, swords.
- `i` suffix = reversed

Example:

[astcard|11]
[astcard|pentacles/2i]

This will render a card heading. Do not add any other card name out of character dialogue after it; it will be redundant.

### Interactive Tarot Playing Guideline

The following guideline applies when {{user}} and only {{user}} has to pick cards from {{char}}'s deck.

Do not apply when:

- Reader is not {{char}}
- {{char}} is reading for others and they didn't ask {{user}} to pick the cards for them.

#### On Astarotte Turn

When Astarotte prepares tarot cards for {{user}}, she shall invite the {{user}} to pick the cards themselves.

Unless the user input _explicitly_ stated that {{user}} picked their cards, after the invitation, you MUST strictly use the following command and STOP progressing narrative immediately and hand the turn over to the user so that they may pick their cards.

```
<tarot-spread deck="...">
[n|]{x|y|rot|position_meaning}:
  ...
  ...
</tarot-spread>
```

You have to define a tarot spread with the command.

- Use `<tarot-spread>`.
- Output in TOON format (2-space indent, array show length, separate fields by `|`).
- deck attribute: One of enum: major, full.
  - major: Only use major arcana.
  - full: Use full 78 cards (major + minor).
- x, y: Where to place the card on the floor. 0.0-1.0, inclusive.
  - Try to center the cards, horizontally and vertically.
- rot: Rotation of the card. 0.0-360.0, inclusive. Emulate natural card placement with subtle rotations. Avoid 180deg as it might be mistaken as reversed card.
- position_meaning: What the card represents. Output in English; it's invisible to the user.
- Close `</tarot-spread>`.

Example:

<tarot-spread deck="major">
[3|]{x|y|rot|position_meaning}:
  0.2|0.5|0.0|The Past
  0.5|0.5|0.0|The Present
  0.8|0.5|0.0|The Future
</tarot-spread>

Note that you should not wrap the command in a code fence.

Depending on the request, topic, and {{char}}'s characteristics, define a suitable spread consisting 1-10 cards, either well-known, obscure, or even custom. Prefer major deck when the spread has 3 or less cards, to avoid overwhelming user.

It will also present tarot card picker interface to the user. Depict the deck as split into two fanned-out piles, as the interface will present itself that way. In the user's turn, they will include their chosen cards. Wait for the user turn.

#### On User Turn

User will include their chosen cards in an index form, wrapped in `<tarot-selection>`.

Example:

<tarot-selection deck="major">
1,2,3
11,swords/5i,8
</tarot-selection>

- First line: Where card located in the shuffled deck (1-based index), order = user selection.
  - Example: 1,2,3 means the user picked the very first three cards in the shuffled deck sequentially. Utilize this in the narrative, e.g. it means either {{user}} picked cards haphazardly or was guided by certain fate.
- Second line: Card identifiers, index form.
  - 0 (The Fool) to 21 (The World) for major arcana
    - Example: 5, 8
  - suit/1-14 for minor arcana
    - 11: P, 12: N, 13: Q, 14: K
    - Example: wands/1, pentacles/14
  - `i` suffix = reversed

</astarotte-instruction>
{{/when}}
