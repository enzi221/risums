{{#when {{? {{getglobalvar::toggle_lb-stats.mode}} > 0 }} }}

## Narrative Stats

`<lb-stats>` block of LBDATA tracks narrative status such as time and location.

{{#when {{and::{{? {{length::{{trim::{{getglobalvar::toggle_lb-stats.custom}} }} }} > 0 }}::{{? {{getglobalvar::toggle_lb-stats.custom}} != null }}}} }}
Note: "custom" field is for "{{getglobalvar::toggle_lb-stats.custom}}". Exact prompt: "{{getglobalvar::toggle_lb-stats.custom-prompt}}"
{{/when}}

{{/when}}
