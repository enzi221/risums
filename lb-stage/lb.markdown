# Guidance Detail

Premise defines overall mood and direction of current flow of narrative.

Each new "main arc" premise shall follow five-act structure: Exposition, Development, Climax, Falling Action, Conclusion. Standard main arcs generated without prior story should have 10 episodes. Subsequent main arcs can be shorter.

When current premise concludes or invalidated, generate anew with fresh episodes. If main arc premise concluded, or invalidated after high intensity, generate a new short, relaxed Epilogue premise for break unless forced intensity continues. Generate less episodes. Epilogue may skip many stages.

Accomplishing the final episode means conclusion of current premise.

You may skip some structure stages in episodes if genre or prior story suggests so. (e.g. mystery may go straight to Climax, romance comedy can skip Climax and Falling Action even in main arc)

## Field Descriptions

### Premise

One sentence defining story's core journey from beginning to end. Immutable. Must be achieved.

Content must include who, when, what - Character, Situation, What they must confront/decide. (NOT what they choose)
Must describe concrete situation AND its resolution/transformation. Not just setup - include endpoint.

Premise MUST remain open-ended for user choices. Do NOT predetermine specific decisions or outcomes that user-controlled character will make. Focus on journey, not destination.

Bad examples:

- Story about redemption (abstract theme)
- What if veteran protects enemy soldier (setup only, no endpoint)
- Detective hunts killer (no transformation/resolution)
- War veteran forgives enemy and joins them (predetermined user choice - FORBIDDEN)

Good examples:

- A detective discovers they themselves are the murderer they've been hunting
  - Endpoint: discovers (not "what they do about it")
- An amnesiac city surveyor confronts conflicting truths about their past and decides who to stand with
  - Journey: confronts past, decides allegiance
- A young mother and her son survive being trapped by rabid dogs
  - Resolution: survive (clear endpoint, no user choice involved)

User choice doesn't have to be at the last episode but in either climax (if any) or conclusion.

{{#when {{? {{length::{{trim::{{getglobalvar::toggle_lightboard-stage.mood}} }} }} > 0 }} }}
User specified direction for new premise:
{{getglobalvar::toggle_lightboard-stage.mood}}
{{/when}}

### Episodes

Story beat list guiding narrative towards premise. Quantity may vary depending on the premise.

Episodes should be abstract enough to allow multiple paths. Focus on WHAT needs to happen (milestones), not HOW it happens (specific events).

Multiple episodes can be concluded at once. If premise's core user-decision lies in the middle of episode list renders rest of them irrelevant, those episodes may be skipped or regenerated. Otherwise, these should be immutable.

When regenerating whole premise, all episodes newly generated must be all `Done: false`.

Climax doesn't have to be about external conflicts. Small but distinct bumps in character arcs can serve as climactic episodes.

### Guidance

Suggestions to guide the next immediate story toward the next episode. Predict user input, list possible story reactions. {{#when::{{getglobalvar::toggle_lightboard-stage.future}}::is::1}}Also list possible major characters (EXPLICITLY PROVIDED IN UNIVERSE SETTINGS) for the next scene up to 3 except {{user}}. Actively suggest new characters.{{/when}}

Each new guidance should actively progress the story to the next milestone but not necessarily complete it at one shot.

Do not include "analyze", "logics", or any other similar terms in any guidance.

# Current State

{{#when::{{getvar::lightboard-stage-premise}}::isnot::null}}

## Premise

{{dictelement::{{getvar::lightboard-stage-premise}}::Title}}
{{dictelement::{{getvar::lightboard-stage-premise}}::Content}}

## Episodes

{{#each {{getvar::lightboard-stage-episodes}} episode}}
[{{dictelement::{{slot::episode}}::Stage}}, {{dictelement::{{slot::episode}}::Title}}: {{dictelement::{{slot::episode}}::Content}} ({{#when::{{dictelement::{{slot::episode}}::Done}}::is::true}}done{{/when}}{{#when::{{dictelement::{{slot::episode}}::Done}}::is::false}}not done{{/when}})]
{{/each}}

## Guidance

{{dictelement::{{getvar::lightboard-stage-guidance}}::Content}}
{{:else}}
None. Generate new set.
{{/when}}

# Example

```
<lightboard-stage>
[Premise]Title:The Coffeehouse at the End of Spring|Content:Burnt-out pastry chef must decide whether to restore the countryside cafe to life or close it for good|Stage: main
[Episode]Title:1. Falling Leaves|Content:Protagonist arrives at the cafe, reflecting on past decisions|Stage:introduction|Done:false
[Episode]Title:2. First Impressions|Content: The cafe's current state and its place in the community become apparent|Stage:rise|Done:false
[Guidance]Content:Assess the cafe's reputation. If something, something. If something else, other thing. If something different, different thing. Starring: A, B, C.
</lightboard-stage>
```

Key syntax:

- Use `<lightboard-stage>`.
- `Title`: short title.
- `Content`: main text body.
- Premise `Stage`: `main`, `epilogue`.
- Episode `Stage`: `introduction`, `rise`, `climax`, `fall`, `conclusion`.
- `Done`: `true` or `false`. When newly generated, must be `false`. Skipped episodes are `true`.
- Divide each field with `|`.
- Close `</lightboard-stage>`.

Guidance should first state which "goal" it seeks. It then should list 3 user actions as action-reaction pairs, formatted as `If action, then reaction. If action, then reaction. If action, then reaction.`

All `Content` must be brief, laconic, telegraphic style. No extra flourishes.
