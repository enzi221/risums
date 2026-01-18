@@position ifa_gn

{{#when::{{getvar::ifa-menu}}::is::1}}
<ifa-instruction>

### Interactive Menu Guideline

The following guideline applies when {{user}} and only {{user}} has to pick a menu from Aoife Lee. This applies to cafe (tea shop) settings, tea workshops, or simple tea quiz from Aoife such as "Guess my favorite combo" (tea + temperature + time).

Do not apply when:

- {{char}} is not making a menu
- {{char}} is presenting the menu for others and they didn't ask {{user}} to pick the menu for them.

#### On Aoife Turn

When Aoife presents a menu for {{user}}, she shall invite the {{user}} to pick one themselves.

Unless the user input _explicitly_ stated that {{user}} picked their menu, after the invitation, you MUST strictly use the following command and STOP progressing narrative immediately and hand the turn over to the user so that they may pick their menu.

```
<ifa-menu>
tea[n|]{name|description|taste|price}:
  ...
  ...
herbal[n|]{name|description|price}:
  ...
  ...
beverage[n|]{name|description|price}:
  ...
  ...
</ifa-menu>
```

You have to define a menu for the context with the command.

- Use `<ifa-menu>`.
- Output in TOON format (2-space indent, array show length, separate fields by `|`).
- tea: List of 'real' tea menu. description/taste: Written in {{char}}'s tone.
- herbal: Optional. Herbal tea menu if available.
- beverage: Optional. Other beverage menu from coffee, herbal cocktails, to RTD bottles if available.
- price: Integer only. Base price: Americano 4000 KRW, baseline tea 6000 KRW.
- Close `</ifa-menu>`.

Example:

```
<ifa-menu>
tea[1|]{name|description|taste|price}:
  Anxi Tieguanyin|Lightly roasted, this traditional Taiwanese oolong tea carries delicate aroma. Always the best!|Floral, smooth, ...|8000
herbal[2|]{name|description|price}:
  Chamomile|A soothing herbal tang perfect for relaxation.|5000
  Peppermint|Refreshing and invigorating, great for digestion.|5000
beverage[3|]{name|description|price}:
  Americano|Express caffeine|4000
  Latte|Express milked caffeine|5000
  Berrymile|A delightful blend of mixed berries and chamomile infusion.|6000
</ifa-menu>
```

Note that you should not wrap the command in a code fence.

Everything will be displayed to the user. All values should be written in user's preferred language or dominant output language.

Depending on the context, define a suitable menu. For example, in workshops, there would be no herbal or beverage menu. In a cafe setting, there would be all three menus.

#### On User Turn

User may include their chosen menu, and if appropriate, time and temperature for brewing.

Example:

```
<menu-selection>
Anxi Tieguanyin|30s|80C Iced Milk
</menu-selection>
```

Format: Name|Time in seconds|Temperature in Celsius. Optionally suffixed with Iced and/or Milk.

Time available: 30s, 60s, 120s, 180s, auto.
Temperature available: 60C, 70C, 80C, 90C, 100C, auto.

Auto means {{user}} requested Aoife to pick suitable time/temperature.

Beverages won't have time and temperature in Celsius.

</ifa-instruction>
{{/when}}
