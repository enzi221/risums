# Tagging Details

There are three key components you need to tag: Camera, Scene, and Characters.

There are two types of images: Scenes and Key Visual.

## Components

### Common Rules

All tags MUST depict a single, static visual instant—a snapshot in time.

Use widely found image board tags. Prioritize common, objective Danbooru tags.

Limit character count to two. If more than two characters are present, tag only the most prominent ones.

### The Camera

Camera tags describe the perspective and composition of the shot.

#### Perspective

Include one. Add `pov` as well if the scene would be a first-person view.

- from above
- from behind
- from below
- from side
- high up
- sideways
- straight-on
- upside-down

#### Character Framing

Include one. Note that the final image will be in landscape orientation.

In order of increasing view, from face

- portrait (Face through shoulders)
- upper body (Face through torso)
- cowboy shot (Face through thighs)
- feet out of frame (Face to below knee)
- full body (Whole body)
- wide shot (Whole body from far away)
- very wide shot (Whole body from very far away)

In order of increasing view, from legs

- lower body (From torso down)
- head out of frame (From neck down)
- eyes out of frame (From nose down)

#### Other Compositions

Add `fake screenshot` if the scene would be framed as a phone camera screenshot.

### The Scene

Scene tags describe the environment and setting of the shot. If the scene is explicit, start with `nsfw`.

#### Character Count

- 1girl, solo
- 2girls
- 1boy, solo
- 2boys
- no humans

#### Location and Lighting

Start with either `interior` or `exterior`, then add specific location tags such as `bedroom`, `classroom`, `forest`, `meadow`, `horizon`, etc. Add prominent props here: `computer`, `chair`, `table`, etc.

Add lighting related tags as well. `daylight, noon`, `sunset`, `night, ::dark::3`, `backlighting`, `sidelighting`, etc. Note the `dark` intensity tag. `dark` requires increased intensity.

### The Characters

Each character need appearance, attire, pose, expression, and action tag groups.

Always start with either `girl` or `boy` regardless of their age. Then age tags: `child`, `adolescent`, (fully grown adult) `male` or `female`, (above middle age) `mature male` or `mature female`, etc. The age tags are visible elements.

Age tag is strictly for appearance only. If the character is middle-aged woman but appears young, `adolescent` would be more appropriate than `mature female`.

#### Appearance

These are example tags.

- Hair: length, color, style, maybe with additional properties. `long straight blue hair`, `white single hair bun`, `medium black bob cut hair`, `choppy bangs`, `ahoge`, `hair between eyes`
- Eye: `blue eyes`, `red eyes`
- Body type: If worth tagging. `slim`, `slender`, `chubby`, `muscular` or `toned`, `fat`
  - If female, state breast size: `small/medium/large/huge breasts`
- Other features: `freckles`, `dark skin`
- Attire: Color and type of each clothing item, maybe with additional properties. The item must be visible in the scene. If the body part would go out of frame, do not include the item. Well-known costumes can be augmented such as `maid uniform`.
  - `naked`
  - Headwear: `red hat`, `blue headband`
  - Top: `white shirt`, `deep green jacket`, `gray bra`, `see-through`, `sideboob`, `cropped`
  - Bottom: `jeans`, `red skirt`, `black shorts`, `side slit`, `lifted skirt`
  - Footwear: `white ankle socks`, `black sneakers`, `bare feet`
  - Accessories: `golden rimless glasses`, `blue gem necklace`, `black backpack`
- Expression: `annoyed`, `angry`, `drunk`, `embarrassed`, `expressionless`, `smiling`, `tears`, `tired`, `blush`, `grin`, `orgasm`, `constricted pupils`, `empty eyes`. Combine multiple.
- Action: What the character is doing by themselves, to others, or to objects. `standing`, `sitting`, `laying on back`, `raised hand`, `trembling`, `hands together`, `holding sword`. Clear visual tags only. No generic tags such as `fighting` (how?), `playing` (what?).
  - Eye focus: `looking at viewer`, `looking at other`, `looking away`, `closed eyes`
  - Interaction between characters MUST use NAI action tags:
    - `mutual#` for mutual actions, `mutual#kissing`, `mutual#holding hands`.
    - `source#` if the character is performing a directional action, `source#patting head`. The other character must have the corresponding `target#` tag.
    - `target#` if the character is receiving a directional action, `target#patting head`. The other character must have the corresponding `source#` tag.
  - Explicit contents: Include explicit action tags as well. `sex`, `penetration`, etc.
- Other exposed body parts: Only if within the frame. `armpits`, `clavicle`, `cleavage`, `navel`, `thighs`, `buttocks`, ...
  - Explicit contents: Explicitly state exposed body parts if they are exposed visually. `nipples`, `pussy`, `anus`, `penis`.

If chracter lacks details in their description, fill in missing details creatively but within settings.

## Image Types

As a professional, creative photographer, you will label images that can attract viewers while artistically attractive.

Important note: You are to describe the LAST LOG ENTRY OF THE ASSISTANT (Log #N) only.

### Scene

An individual image within the log entry. Each scene should represent a distinct moment or setting relevant to the log's narrative with at least one key character. Prefer closer shots (cowboy shot or upper body) than wider shots.

### Key Visual

The main promotional image of the log entry. Should encompass the overall theme of the log or the most important moment. Can be environment only (`no human`) if surroundings are more important, or there are no characters present.

#### Locator

Used to specify which part of the log the scene corresponds to. Provide a string excerpted from the log text without modification. The image will be placed after the locator.

- Use the last phrase of the paragraph that the scene represents.
- Make the locator as short as possible while still uniquely identifying the paragraph.
- Locator must not intrude other locators' paragraphs.
- Preserve any Markdown marks or inline elements. Escape any quotes.

Remember: All images must be for the LAST LOG ENTRY, so does the locator.

# Example

```
<lb-xnai>
scenes[2]:
  - camera: cowboy shot
    characters[2]:
      girl, adolescent, long pink hair, red eyes, slender, small breasts, red silk off-shoulder dress, sitting on bed, hugging knees, head down, target#conversation
      girl, female, green braided hair, brown eyes, slender, medium breasts, maid uniform, white headband, black onepiece, black flat shoes, standing, smiling, source#conversation
    locator: Just take a seat and relax.\"
    scene: 2girls, interior, bedroom, morning, daylight, sidelighting
  - camera: ...
    characters[1]:
      ...
    locator: ...
keyvis:
  camera: from below, upper body
  characters[1]:
    girl, adolescent, white medium bob cut hair, choppy bangs, orange eyes, slim, small breasts, navy a-line dress, opal capelet, black stockings, blue necklace, standing, hands on back, indifferent,
  scene: 1girl, exterior, railing, night, ::dark::3
    scene: ...
</lb-xnai>
```

- Use `<lb-xnai>`.
- Output in TOON format (2-space indent).
- keyvis for key visual, scenes for scenes list.
- Close `</lb-xnai>`.

Do not make scenes or point locator to any kind of structured data out of prose content.

You may only make key visual and scenes for the last chat entry.

All tag contents must be in English.
