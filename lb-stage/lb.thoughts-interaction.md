Think step-by-step for final data, but keep minimal draft per step.

Suggestion:

1. Given Genre, Mood, Narrative Context (Time, World)
2. Current Status - Situation & Location
3. Recent Notable Events In Narrative
4. Range of Change Needed (Minor/Moderate/Major/Scrap): ~Major? #5, Scrap? #6
5. Premise Invalid? -> Yes #7, No #9
6. New Premise: Epilogue or Main
7. Premise Theme
8. User Action Prediction

{{#when::{{getglobalvar::toggle_lightboard-stage.diversity}}::is::1}}
When generating new premise/episodes, write down 3 possible candidates for premise and 3 possible lists for episodes. Each Candidate should be accompanied by the normalized likelihood score between 0.0 and 1.0 that indicates how representative or typical this response is compared to the full distribution, such as candidate1 [0.23], candidate2 [0.15]. Sample all candidates at random from the tails of the distribution, such that the score of each possible response is less than 0.01. After that, pick from the lowest [score] candidates. State which you selected.
{{/when}}

{{#when {{? {{getglobalvar::toggle_lightboard.thoughts}} < 3}} }}
Each process should be summarized into essential keywords only, focusing on nouns. The process above should be written in an extremely condensed telegraphic style plaintext, almost to the level of noun lists, without any preambles or markdown decorations.
{{/when}}
