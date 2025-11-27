# Tracking Detail

You will track the narrative time, location, weather, and {{user}} outfit.

If there are lb-stats node in the log, it means you've already tracked stats for the log. Deduct the time passed since the last lb-stats node. Analyze the later logs without lb-stats for changes in time, location, etc.

If there are no previous lb-stats node, you MUST provide initial values for time, location, weather, and outfit based on the previous chat log and narrative context. Read the world settings, read the log, and deduce or invent plausible values, not simple `unknown`s.

## Time

Assess the time passage based on the narrative context, events, and dialogs count. Time should flow plausibly. Each dialog don't need a few minutes each. Speech will only take some seconds. Use granular time increments. Randomize minutes and seconds to avoid round numbers and give impression of natural slice of time.

If current narrative entered into a recalling of past events from either {{user}} or someone else, time should NOT change. Append "(Recalling)" to the end of the time field.

## Outfit

Track {{user}}'s outfit changes. Outfit should be limited to visible elements such as clothing, accessories, and footwear. Include each item's color. Do not include miscellaneous items.

{{#when {{? {{getglobalvar::toggle_lb-stats.equipments}} > 0 }} }}

## Equipments

Track {{user}}'s current, carried-on-body equipments such as gadgets and tools. Consumables should be removed from the list when used. Do not track items that were stored away.

{{#when {{? {{getglobalvar::toggle_lb-stats.equipments}} == 1 }} }}
Only include core items that are meaningful to the narrative.
{{:else}}
Include all items that {{user}} possesses in their inventory.
{{/when-eq1}}
{{/when-eq1+}}

{{#when {{and::{{? {{length::{{trim::{{getglobalvar::toggle_lb-stats.custom}} }} }} > 0 }}::{{? {{getglobalvar::toggle_lb-stats.custom}} != null }}}} }}

## Custom field

User has requested extra {{user}} tracking: {{getglobalvar::toggle_lb-stats.custom}}. If applicable, try your best to track it: "{{getglobalvar::toggle_lb-stats.custom-prompt}}"

Unless change is required, keep it as-is from the last lb-stats block.

{{/when-custom}}

# Example

```
<lb-stats>
time: 2077-12-31 (Fri) 14:31:00
location: Shibuya Crossing
weather: Cloudy, 3°C
outfit: Black leather jacket, white t-shirt, ripped jeans, combat boots
{{#when {{? {{getglobalvar::toggle_lb-stats.equipments}} > 0 }} }}equipments: Cyberdeck Mk.IV{{/when}}
{{#when {{and::{{? {{length::{{trim::{{getglobalvar::toggle_lb-stats.custom}} }} }} > 0 }}::{{? {{getglobalvar::toggle_lb-stats.custom}} != null }}}} }}custom: (the data user requested){{/when}}
</lb-stats>
```

- Open `<lb-stats>`.
- Output in TOON format (YAML-like).
- time: `YYYY-MM-DD (DayOfWeek) HH:MM:SS` in 24-hour format.
- location: Specific place name or description in dominant language of the log.
- weather: Current weather condition and temperature in dominant language of the log. Use Celsius.
- outfit: Comma separated list in dominant language of the log.
  {{#when {{? {{getglobalvar::toggle_lb-stats.equipments}} > 0 }} }}- equipments: Comma separated list in dominant language of the log.{{/when}}
- Close `</lb-stats>`.

If value is none, such as empty equipments, output only the key like: `equipments:`.

STRICTLY ADHERE TO THE FORMAT. FIELD ORDER MATTERS.
