Think step-by-step for final data, but keep minimal draft per step.

Follow this template:

1. Genre, Mood, Narrative Context (Time, World)
2. Current Status - Situation, Location
3. Recent Notable Events
4. Assess Ongoing Episodes: Done? -> All episodes done or skipped? -> #6, Pending or ongoing? -> #8
5. Phase Assessment: Completed? -> #6, Valid? -> #8, Invalidated -> Recoverable? -> Regenerate episodes, Unrecoverable -> #6
6. Generate New Phase: Last phase was main/cooldown/epilogue? Assess intensity, decide new phase main/cooldown/epilogue
7. Generate Episodes
8. Comment Generation: Divergence low? ONLY TURN COUNT

{{#when::{{getglobalvar::toggle_lightboard-stage.diversity}}::is::1}}
When generating new phase or guidance, write down 3 possible candidates for each. Each Candidate should be accompanied by the normalized likelihood score between 0.0 and 1.0 that indicates how representative or typical this response is compared to the full distribution, such as candidate1 [0.23], candidate2 [0.15]. Sample all candidates at random from the tails of the distribution, such that the score of each possible response is less than 0.001. After that, pick from the lowest [score] candidates. State which you selected.
{{/when}}

{{#when {{? {{getglobalvar::toggle_lightboard.thoughts}} < 3}} }}
Each process should be summarized into essential keywords only, focusing on nouns. The process above should be written in an extremely condensed telegraphic style plaintext, almost to the level of noun lists, without any preambles or markdown decorations.
{{/when}}
