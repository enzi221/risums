@@depth 0

{{#when::{{getvar::lightboard-stage-premise}}::isnot::null}}

<story-guidance>

## Story Guidance System

This guidance helps maintain narrative coherence while preserving your creative freedom.

### Components

Premise is immutable core journey. Defines what situation protagonist faces and what must be confronted or decided. This sets boundaries for the current narrative arc.

Episodes are abstract milestones marking story progression. Intentionally vague to allow multiple paths - they describe WHAT needs to happen, not HOW. Episodes follow five-act structure (introduction, rise, climax, fall, conclusion). Naturally progress through these beats, but specific events are yours to create.

Guidance is immediate next-step suggestion list formatted as action-reaction pairs. These predict possible user inputs and propose story responses. Guidance includes an importance level (important/moderate/optional) indicating narrative weight. Use these as inspiration, not constraints. User input takes precedence over guidance.

{{#when::{{getglobalvar::toggle_lightboard-stage.future}}::is::1}}Guidance also includes possible major characters for the next scene up to 3. You are free to star them none, one, some, or all.{{/when}}

### Current Story State

#### Premise

{{dictelement::{{getvar::lightboard-stage-premise}}::Content}}

#### Remaining Episodes

{{#each {{getvar::lightboard-stage-episodes}} episode}}
[{{dictelement::{{slot::episode}}::Stage}}: {{dictelement::{{slot::episode}}::Content}} ({{#when::{{dictelement::{{slot::episode}}::Done}}::is::true}}done{{/when}}{{#when::{{dictelement::{{slot::episode}}::Done}}::is::false}}not done{{/when}})]
{{/each}}

#### Guidance

{{dictelement::{{getvar::lightboard-stage-guidance}}::Content}}

### Usage

Premise remains constant until its conclusion unless totally invalidated. Aim for it following episodes.

After reaching premise end, stop the narrative there without further progression.

Multiple episodes can be achieved at once.

Episodes state where they fall in five-act story structure: Exposition, Development, Climax, Falling Action, Conclusion. Narrative intensity should rise towards climax and resolve by conclusion.

</story-guidance>

{{/when}}
