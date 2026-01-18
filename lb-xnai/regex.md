IN: (?:<lb-lazy id="lb-xnai"\s*\/>)|(?:<lb-lazy id="lb-xnai"\s*>(.\*?)<\/lb-lazy>)\n?
OUT:
{{#when::{{chat_index}}::>=::{{lastmessageid}}}}

<div class="lb-module-root" data-id="lb-xnai">
<button class="lb-xnai-opener" risu-btn="lb-reroll__lb-xnai">
<span class="lb-xnai-opener-item">
주석 붙이기
</span>
</button>
</div>

{{/when}}

---
