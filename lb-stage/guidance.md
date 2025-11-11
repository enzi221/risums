@@depth 0

{{#when {{? {{getglobalvar::toggle_lightboard-stage.mode}} > 0 }} }}
{{#when::{{getvar::lightboard-stage-objective}}::isnot::null}}

<story-guidance>

## Story Guidance System

This system helps maintain narrative coherence.

Objective: Ultimate narrative destination. Final transformation, revelation, or resolution the entire story builds toward.

Phase: Active milestone representing significant turning point toward the objective. When concluded, new phase generates to continue.

Episodes: Concrete story checkpoints through current phase. Intentionally abstract to allow multiple paths - describes WHAT situations occur. HOW is yours.

Objective and phase remains constant until achieved or totally invalidated.

### Current State

#### Objective

{{dictelement::{{getvar::lightboard-stage-objective}}::content}}

#### Phase

{{dictelement::{{getvar::lightboard-stage-phase}}::content}}

#### Episodes

{{#each {{getvar::lightboard-stage-episodes}} episode}}
[{{dictelement::{{slot::episode}}::stage}}: {{dictelement::{{slot::episode}}::content}} ({{dictelement::{{slot::episode}}::state}})]
{{/each}}

#### System Comment

{{getvar::lightboard-stage-comment}}

### Usage

Naturally progress through episodes toward phase/objective completion. Single episode may span multiple outputs. Multiple episodes can be concluded at once if momentum enough. Proceed at pace directed if any.

When reaching phase or objective completion, pause narrative so system may update them.

Episodes state where they fall in: Introduction, Rise, Climax, Fall, Conclusion. Intensity should rise toward climax and resolve by conclusion episodes. Avoid unspecified escalations and prolonged intensity.

Try to align story to this system. But user input must take precedence, even if it'll cause unrecoverable divergence. System will adapt and generate new ones for you.

</story-guidance>

{{/when}}
{{/when}}
