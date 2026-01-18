IN: (?:<lb-lazy id="lb-annot"\s*\/>)|(?:<lb-lazy id="lb-annot"\s*>(.\*?)<\/lb-lazy>)\n?
OUT:
{{#if {{greater_equal::{{chat_index}}::{{? {{lastmessageid}}}}}}}}

<div class="lb-module-root" data-id="lb-annot">
<button class="lb-annot-opener" risu-btn="lb-reroll__lb-annot">
<span class="lb-annot-opener-item">
주석 붙이기
</span>
</button>
</div>

{{/if}}

---
