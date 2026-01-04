@@depth 0

{{#when {{? {{getglobalvar::toggle_lightboard.active}} > 0 }} }}
{{#when {{? {{getglobalvar::toggle_lb-stage.mode}} > 0 }} }}

<story-guidance>

This system helps maintain story coherence.

## Story Guidance System

Objective: Ultimate story destination. Final transformation, revelation, or resolution the entire story builds toward.

Phase: Active milestone representing significant turning point toward the objective. When concluded, new phase generates to continue.

Episodes: Concrete story checkpoints through current phase. Intentionally abstract to allow multiple paths - describes WHAT situations occur. HOW is yours.

Objective and phase remains constant until achieved or totally invalidated.

{{#when {{? {{getglobalvar::toggle_lb-stage.direction}} == 1 }} }}

### User Direction

The user wants to guide story toward:
{{#when {{? {{length::{{trim::{{getglobalvar::toggle_lb-stage.mood}} }} }} > 0 }} }}
"{{getglobalvar::toggle_lb-stage.mood}}"
{{:else}}
(No input)
{{/when}}

Genre Tags:

- Likes: {{getglobalvar::toggle_lb-stage.tags-likes}}
- Dislikes: #Mary Sue {{getglobalvar::toggle_lb-stage.tags-dislikes}}

{{/when}}

### Current State

<lb-stage-reserve />

### Usage

Naturally progress through episodes toward phase/objective completion. Single episode may span multiple outputs. Multiple episodes can be concluded at once if momentum enough. Proceed at pace directed if any.

When phase or objective completion is reached, output `<lb-stage-marker>Phase Complete</lb-stage-marker>` (or Objective Complete) at the end and stop output so system can evaluate.

Episodes state where they fall in: Introduction, Rise, Climax, Fall, Conclusion.

- Introduction/Rise: Build tension naturally
- Climax: Peak intensity
- Fall/Conclusion: Wind down. No new characters, conflicts, or plot threads. Focus on resolving established elements.

Avoid unspecified escalations and prolonged intensity.

Try to align story to this system. But user input must take precedence, even if it'll cause unrecoverable divergence. System will adapt and generate new ones for you.

</story-guidance>

{{/when}}
{{/when}}
