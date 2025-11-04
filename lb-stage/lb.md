# Guidance Detail

Premise defines overall mood and direction of current flow of narrative.

Each new "main arc" premise shall follow five-act structure: Exposition, Development, Climax, Falling Action, Conclusion. Standard main arcs should have {{#when::{{getglobalvar::toggle_lightboard-stage.length}}::is::0}}around 5-7 episodes.{{/when}}{{#when::{{getglobalvar::toggle_lightboard-stage.length}}::is::1}}around 7-10 episodes.{{/when}}{{#when::{{getglobalvar::toggle_lightboard-stage.length}}::is::2}}around 10-14 episodes.{{/when}}

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

The key decision doesn't only have to be at the last episode but also climax (if any).

{{#when {{? {{length::{{trim::{{getglobalvar::toggle_lightboard-stage.mood}} }} }} > 0 }} }}
User specified premise direction (prioritize over everything): "{{getglobalvar::toggle_lightboard-stage.mood}}"
{{/when}}

### Episodes

Story beat list guiding narrative towards premise. Quantity may vary depending on the premise.

Episodes should be abstract enough to allow multiple paths. Focus on WHAT needs to happen (milestones), not HOW it happens (specific events).

Multiple episodes can be concluded at once. If premise's core user-decision lies in the middle of episode list renders rest of them irrelevant, those episodes may be skipped or regenerated. Otherwise, these should be immutable.

When regenerating whole premise, all episodes newly generated must be all `Done: false`.

Climax doesn't have to be about external conflicts. Small but distinct bumps in character arcs can serve as climactic episodes.

### Guidance

Provide ongoing narrative tracking and suggestions to guide the story toward the next episode in short term. Predict user input, list possible story reactions.

Each new guidance should actively progress the story to the next milestone but not necessarily complete it at one shot.

Do not include "analyze", "logics", or any other similar terms in any guidance.

# Current State

{{#when::{{getvar::lightboard-stage-premise}}::isnot::null}}

## Premise

{{dictelement::{{getvar::lightboard-stage-premise}}::title}}
{{dictelement::{{getvar::lightboard-stage-premise}}::content}}

## Episodes

{{#each {{getvar::lightboard-stage-episodes}} episode}}
[{{dictelement::{{slot::episode}}::stage}}, {{dictelement::{{slot::episode}}::title}}: {{dictelement::{{slot::episode}}::content}} ({{dictelement::{{slot::episode}}::state}})]
{{/each}}

## Guidance

{{getvar::lightboard-stage-guidance}}
{{:else}}
None. Generate new set.
{{/when}}

# Example

```
<lightboard-stage>
premise:
  title: The Coffeehouse at the End of Spring
  content: Burnt-out pastry chef must decide whether to restore the countryside cafe to life or close it for good
  stage: main
episodes[2|]{content|stage|state|title}:
  Protagonist arrives at the cafe, reflecting on past decisions|introduction|done|1. Falling Leaves
  The cafe's current state and its place in the community become apparent|rise|ongoing|2. First Impressions
guidance: Episode 1 ongoing for 2 turns. Assess the cafe's reputation. If something, something. If something else, other thing. If something different, different thing.
</lightboard-stage>
```

- Use `<lightboard-stage>`.
- Output in TOON format (2-space indent, array show length, separate fields by `|`).
- title: short novel-like title.
- content: main text body.
- premise stage: enum `main`, `epilogue`.
- episode stage: enum `introduction`, `rise`, `climax`, `fall`, `conclusion`.
- episode state: enum `pending`, `ongoing`, `done`, `skipped`. Only one episode can be ongoing. Newly generated: pending or ongoing.
- guidance content: Story state (premise or episode began, MUST include episode turn count), goal, user action predictions.
- Close `</lightboard-stage>`.

STRICTLY ADHERE TO THE FORMAT. DO NOT ALTER ENUMS FOR ARRAY FORMAT.

Guidance should list 3 user actions as action reaction pairs, formatted as "If action, then reaction. If action, then reaction. If action, then reaction."

All content fields: Brief, laconic. No line breaks within fields. Write in English.
