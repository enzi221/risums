# Guidance Detail

Objective defines ultimate destination, phase defines current milestone, episodes break down phase into story beats.

When generating fields, respect this user specified genre/direction (prioritize over everything):
{{#when {{? {{length::{{trim::{{getglobalvar::toggle_lightboard-stage.mood}} }} }} > 0 }} }}
"{{getglobalvar::toggle_lightboard-stage.mood}}"
{{/when}}

Genre Tags:

- Likes: {{getglobalvar::toggle_lightboard-stage.tags-likes}}
- Dislikes: #Angst #Mary Sue {{getglobalvar::toggle_lightboard-stage.tags-dislikes}}

## Objective

Defines story's ultimate destination across entire journey. The overarching endpoint that encompasses multiple phases. Immutable.

Must describe final transformation, revelation, or resolution the story builds toward. Focus on ultimate scope, not prescribed conclusions.

If story diverged absolutely unrecoverably away from objective intent, objective is invalidated. If there is a chance to recover, the objective should continue.

Good examples:

- A character confronts their hidden past and determines where their true loyalty lies
  - Scope: past revelation + loyalty decision (ultimate endpoints)
- A mother and son's ordeal transforms their relationship as they survive a deadly siege
  - Scope: survival + relationship transformation

## Phase

Narrative milestone currently active. Represents significant story beat or turning point in {{user}}'s perspective toward the objective.

Each new "main" phase shall follow five-act structure: Introduction, Rise, Climax, Falling, Conclusion. Main phase should have {{dictelement::{"0":"5-7","1":"7-10","2":"10-14"}::{{getglobalvar::toggle_lightboard-stage.length}}}} episodes with all five-act structures.

If story diverged absolutely unrecoverably away from phase intent, phase is invalidated. If there is a chance to recover, the phase should continue.

Take extra care to determine if phase is absolutely unrecoverable. Even if narrative skipped ahead in time, phase and its episodes may still be valid if core transformation/realization is achievable.

When closed or invalidated, generate anew with fresh episodes.
After each main/cooldown phase closure/invalidation, low intensity -> MUST low intensity, epilogue phase for loosening; no climax, skip structures. High intensity even in conclusion -> MUST cooldown phase. Begin in climax or fall, prepare only a few episodes aimed for intensity resolvement.

Closed main phases (NOT invalidated nor epilogues) should contribute to objective completion percentage. Take caution to pace the narrative; avoid a phase that will significantly advance percentage alone, or single-handedly complete the objective.

Do not skip ahead even if phase core looks completed. Climax is not everything; fall and conclusion also important. Only close after going through all episodes.

Phase should be abstract enough to allow multiple paths. Focus on WHAT transformation/realization occurs, not HOW it unfolds.

Good examples:

- Character confronts a truth about themselves they've been avoiding
  - Milestone: confrontation + realization (not what they decide)
- An external threat forces dormant relationships to surface
  - Milestone: catalyst + revelation (outcome open)
- Past and present identities collide, demanding reconciliation
  - Milestone: collision point (resolution path undefined)

## Episode

Story beats in {{user}}'s perspective. Episodes break down the current phase into actionable story checkpoints. Episodes should guide the narrative toward completing the current phase.

Episodes should be abstract enough to allow multiple paths. Do not prescribe specific actions as it must be user's choice.

Episodes must be done in order. Previous episodes must be done or skipped first. Do not arbitrarily jump ahead.

Multiple episodes can be closed at once if narrative momentum supports. Individual episodes may be skipped or regenerated if story flow renders them obsolete.

Climax doesn't have to involve external or visible conflicts. Internal character revelations or subtle relationship shifts can serve as climactic episodes.

When regenerating due to phase invalidation, first episode must be ongoing, others pending.

# Current State

{{#when::{{getvar::lightboard-stage-raw}}::isnot::null}}
{{getvar::lightboard-stage-raw}}
{{:else}}
None. Generate new set.
{{/when}}

# Example

```
<lightboard-stage>
objective:
  title: Renewal of the Heart
  content: A burnt-out pastry chef rediscovers what they truly value in life and reconciles with their past
  completion: 8%
phase:
  title: The Coffeehouse at the End of Spring
  content: The dilapidated cafe forces concrete choices about whether to invest time and resources into restoration
  stage: main
episodes[2|]{content|stage|state|title}:
  Protagonist arrives at the cafe, reflecting on past decisions|introduction|done|Falling Leaves
  The cafe's current state and its place in the community become apparent|rise|ongoing|First Impressions
divergence: medium
comment: Ongoing E1 for 2 turns.
history: Protagonist discovered inherited property.
</lightboard-stage>
```

- Open `<lightboard-stage>`.
- Output in TOON format (2-space indent, array show length, separate fields by `|`).
- title: short novel-like title.
- content: main text body.
- completion: percentage of objective completion. 100% means objective closes.
- phase stage: enum `main, epilogue, cooldown`.
- episode stage: enum `introduction, rise, climax, fall, conclusion`.
- episode state: enum `pending, ongoing, done, skipped`. Only one episode can be ongoing.
- divergence: story divergence level. enum `high, medium, low`.
- comment: text for main model. Must include episode turn count (NOT objective/phase status - ONLY episode turn count). Divergence HIGH -> add vague minimal direction (without specifics) that can restore flow. Divergence LOW/MEDIUM -> NO DIRECTION! Both: Do not describe current scene.
- history: your private notes for tracking completed phases ONLY (NOT CURRENT). Keep only minimal key points of each phase without their titles.
- Close `</lightboard-stage>`.

STRICTLY ADHERE TO THE FORMAT. DO NOT ALTER ENUMS IN ARRAY FORMAT.

Episode order matters. Keep them in intended order.

Content/comment/history: Brief, laconic. No line breaks within fields.
Comment/history: If empty, use `none`.
