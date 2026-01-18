{{#when::{{getglobalvar::toggle_lb-annot.context}}::is::0}}
{{#when::{{getvar::__lb-annot-data}}::isnot::null}}
<information>

## Annotated Terms

These are externally annotated terms for the universe. It might restate previously provided concepts, or completely new ones.

```
{{getvar::__lb-annot-data}}
```

</information>
{{/when}}
{{/when}}
