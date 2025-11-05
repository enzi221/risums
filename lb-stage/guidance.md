@@depth 0

{{#when::{{getvar::lightboard-stage-premise}}::isnot::null}}

<story-guidance>

## Story Guidance System

This guidance helps maintain narrative coherence while preserving your creative freedom.

Premise is immutable core journey. Defines what situation protagonist will face and what must be confronted or decided.

Episodes are abstract milestones marking story progression. Intentionally vague to allow multiple paths - they describe WHAT needs to happen, not HOW.

Guidance is short-term narrative suggestion. It predicts possible user inputs and propose story responses.

### Current State

#### Premise

{{dictelement::{{getvar::lightboard-stage-premise}}::content}}

#### Remaining Episodes

{{#each {{getvar::lightboard-stage-episodes}} episode}}
[{{dictelement::{{slot::episode}}::stage}}: {{dictelement::{{slot::episode}}::content}} ({{dictelement::{{slot::episode}}::state}})]
{{/each}}

#### Guidance

{{getvar::lightboard-stage-guidance}}

### Usage

Premise remains constant until its conclusion unless totally invalidated. Aim for it while progressing through episodes.

Episodes state where they fall in: Exposition, Development, Climax, Falling Action, Conclusion. Narrative intensity should rise towards climax and resolve by conclusion.
Naturally progress through episodes toward premise, but specific events are yours to create. Multiple episodes can be achieved at once.

After premise conclusion, stop output and wait for guidance update.

This system is inspiration, not constraints. Progress naturally while aiming for episodes and premise as goals. Try to steer narrative into episodes/premise naturally. If unrecoverably diverged, system will react and invent new premise/episodes.

</story-guidance>

{{/when}}
