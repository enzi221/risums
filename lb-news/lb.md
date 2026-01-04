# Simulation details

## About the board

Newspaper articles within universe with various subtopics one can subscribe.

Narrative, universe, newspaper all should be simulated as real life. News authors don't treat narrative, universe, themselves as novel or game.

### Tone and manner

{{#when {{? {{length::{{trim::{{getglobalvar::toggle_lb-news.subject}} }} }} > 0 }} }}
Simulate as if protagonist has subscribed "{{getglobalvar::toggle_lb-news.subject}}" subject.
{{/when}}

{{#when::{{getglobalvar::toggle_lb-news.preset}}::is::0}}

{{#when {{? {{length::{{trim::{{getglobalvar::toggle_lb-news.mood}} }} }} > 0 }} }}
The newspaper should feel like "{{getglobalvar::toggle_lb-news.mood}}" in tone, manner, and style.
{{/when}}
{{#when {{? {{length::{{trim::{{getglobalvar::toggle_lb-news.mood}} }} }} == 0 }} }}
Article titles should be catchy, clickbait style, sometimes sensationalist depending on newspaper type.
{{/when}}

{{/when}}
{{#when::{{getglobalvar::toggle_lb-news.preset}}::is::1}}

The newspaper should feel like it was written in 1980s. Use "국한문혼용체", no English alphabets. Post category is exception; use Korean characters only

Never use conversational or polite endings like -요 or -습니다 within article contents. (Ads are exception; they may use polite endings)

Criteria for 한문 usage:

0. Within article body, limit 한자 to 2 or 3 max per paragraph.
1. Key words to emphasize in a paragraph or title ("... 경제발전을 위한 [hx;牽引車;견인차]로서 나아가야 한다는 ...")
2. Abbreviations ("... 오후에 [hx;韓銀;한은] 총재에게 ... ")
3. Formal terms that are commonly written in 한자 as you see fit

Readability should come first; the goal is not to stuff as many 한자 as possible. Use 한자 only when it'd improve _formality_.

Annotate each and every 한자 or any other words that require annotations for modern readers like [hx;target;explanation], and nothing else.

All other forms of annotations such as parenthesis are strictly prohibited. Do not place the `target` outside of the [`hx;...`] tag again.

BAD: 아파트 공공료 [hx;公共料;공공료] 인상 (REDUNTANT REPETITION - DONT)

Good Example:

- 아파트 [hx;公共料;공공료] 인상 (NO UNNECESSARY ANNOTATION - GOOD)
- 안정성 [hx;檢證;검증] 필요 (NO UNNECESSARY ANNOTATION - GOOD)

{{/when}}
{{#when::{{getglobalvar::toggle_lb-news.preset}}::is::2}}

Write in Late Joseon / Early Modern Korean style (late 19th century). Use pre-standardized orthography from that era. Apply archaic phonological rules: avoid palatalization and ignore modern initial sound rules. Keep it readable but distinctly historical. Use "국한문혼용체", no English alphabets. Post category is exception; use Korean characters only

Criteria for 한문 usage:

0. Within article body, limit 한자 to 2 or 3 max per paragraph.
1. Key words to emphasize in a paragraph or title ("... 경제발전을 위한 [hx;牽引車;견인차]로서 나아가야 한다는 ...")
2. Abbreviations ("... 오후에 [hx;韓銀;한은] 총재에게 ... ")
3. Formal terms that are commonly written in 한자 as you see fit

Readability should come first; the goal is not to stuff as many 한자 as possible. Use 한자 only when it'd improve _formality_.

Examples:

```
금일 뎡부에서 새로운 법령을 반포하니 백성은 이를 쥬의하여 살필디라.
작일 인천항에 영국 상선이 도착하엿는대 그 배의 크기가 산과 갓더라.
근래에 일기가 고르지 못하야 농작물이 피해를 입으니 농부들의 근심이 기프더라.

우리나라가 부강해지려면 몬저 교육을 힘써야 할 터이니 학도들은 득듯 명심할지어다.
세계 각국이 셔로 경쟁하난 때에 우리만 홀로 잠자코 잇슬 수 없난 리치라.
남녀가 유별하다 하나 학문을 닦고 지식을 넓히는 데에 어찌 녀자의 구별이 잇겟느뇨.
하날이 사람을 내실 제 귀한 사람이나 천한 사람이나 다 일반으로 내셧으니 됴션 사람들도 이를 아라야 할 것이라.
```

Annotate each and every 한자 or any other words that require annotations for modern readers like [hx;target;explanation], and nothing else.

BAD:

- 명약 [hx;金鷄蠟;금계랍](퀴닌)은 학질을 떼는 데 귀신갓흔 효험이 잇다 (ONLY HX ANNOTATIONS ALLOWED - DONT)
- 됴션 [hx;됴션;조선] 사람들은 졍신을 바짝 차려야 (REDUNTANT REPETITION - DONT)

Good Example:

- 명약 [hx;金鷄蠟;금계랍, 퀴닌]은 학질을 떼는 데 귀신갓흔 효험이 잇다 (ONLY HX USED - GOOD)
- [hx;됴션;조선] 사람들은 졍신을 바짝 차려야 (NO UNNECESSARY ANNOTATION - GOOD)

All other forms of annotations such as parenthesis are strictly prohibited. Do not place the `target` outside of the [`hx;...`] tag again.

{{/when}}

Invent plausible newspaper company name, borrow from the world setting, or use the name of the last data.

### Topics

Newspaper name should not contain parenthesis. Assign plain text only.

Politics, games, sports, technology, politics, cooking, health, relationships, sexual, celebs, polls, etc. Explicit sexual contents allowed in adult newspaper.

All posts should be written by journalists, reporters, columnists, etc. within universe.

Avoid topics from previous data. Previous data is embedded in log. No repeated similar topic/narrative discussions. Exception: Related news series, such as follow-ups, with its own narrative progress.

If no prominent event in narrative, invent plausible, out of narrative background events, use them as topics. Note narrative time. Breaking news can't have detailed contents. Do not go over the provided chat log. Do not invent future events. All news must be written as if it happened before or right at the current narrative time, not over that.

In addition to dedicated ads, include minimum one advertisement disguised as a news article.

If previous data had breaking news for a major narrative event, do a follow-up.

Articles can be deleted by author or corp/gov claims.
Deleted article content: (삭제된 기사입니다)

Note: Time and place of narrative universe may not modern Earth. Can be medieval, SF, fantasy, WWII, apocalypse, anything. Pay attention to universe setting.

#### Advertisements

Dedicated ads take time to produce; it should not reflect current realtime events such as disasters. Generate random, "generic" ads unrelated to current narrative events. Top ad slots can be used for informational services as well, such as weather forecasts or stock market summaries.

In any case, DO NOT REFLECT current scenes in dedicated advertisements. IT FEELS WEIRD AND IT IS VIOLATION OF PRIVACY. STOP TRACKING INDIVIDUALS FOR ADS!

Advertisement articles requires less efforts, thus they can reflect recent events if plausible.

#### Protagonist/Partners privacy

{{#when {{and::{{? {{length::{{trim::{{getglobalvar::toggle_lb-news.protagonist}} }} }} > 0 }}::{{? {{getglobalvar::toggle_lb-news.protagonist}} != null}}}}}}
User controlled character ({{getglobalvar::toggle_lb-news.protagonist}}) should be considered the protagonist for this section. Partners are major characters currently aligned and engaged with the protagonist.
{{:else}}
User controlled character ({{user}}) should be considered the protagonist for this section. Partners are major characters currently aligned and engaged with the protagonist.
{{/when}}

{{#when {{? {{getglobalvar::toggle_lb-news.privacy}} == 0}}}}
This world revolves around the protagonist and their partners. Writes may discuss their actions, rumors, sightings of them freely unless it was done in private spaces without a chance for witnesses. They intrigue news readers. Include at least one article discussing them in some way.
{{:else}}
All articles should focus on simulating the "living background world", not a world which revolves around the protagonist.
{{/when}}

{{#when {{? {{getglobalvar::toggle_lb-news.privacy}} == 1}}}}

Protagonist and their partners' activities in private or remote spaces (home, safehouses, anywhere without witnesses) are not suitable as topics. Include the activity's aftermath ONLY IF the action was very impactful enough to leave such aftermath. These must be limited to rumors or official statements ONLY unless narrative allows direct observation/interview.

{{/when}}
{{#when {{? {{getglobalvar::toggle_lb-news.privacy}} == 2}}}}

Protagonist and their partners must be considered as ordinary people of this world, and as such, their actions are not suitable as topics, unless they are important figures (local celebrities, politicians, business leaders, etc) in their communities.

Even if protagonist and their partners are the most important figure, their activities in private or remote spaces (home, safehouses, anywhere without witnesses) are not suitable as topics. Include the activity's aftermath ONLY IF the action was very impactful enough to leave such aftermath. These must be limited to rumors or official statements ONLY unless narrative allows direct observation/interview.

{{/when}}
{{#when {{? {{getglobalvar::toggle_lb-news.privacy}} == 3}}}}

Protagonist and their partners must be considered as ordinary people of this world, and as such, their actions are not suitable as topics, unless:

- They are absolutely the most important figure (world-saving hero, world-ending villain, etc) of the world.
- Their activities caused long-lasting, large-scale impact on the world.

Otherwise, writers won't bother covering them.

Even if protagonist and their partners are the most important figure, their activities in private or remote spaces (home, safehouses, anywhere without witnesses) are not suitable as topics. Include the activity's aftermath ONLY IF the action was very impactful enough to leave such aftermath. These must be limited to rumors or official statements ONLY unless narrative allows direct observation/interview.

{{/when}}
{{#when {{? {{getglobalvar::toggle_lb-news.privacy}} == 4}}}}

Absolutely do not include anything about protagonist and their partners. Articles should be strictly limited to their actions' aftermath. Focus solely on providing background world simulation to the user, outside the user's viewpoint.

{{/when}}

# Example

```
<lb-news datetime="2026-03-17 06:00" name="데일리 라이프">
posts[3|]{title|category|time|content}:
  [단독] 이원석 대표, 차기 대선 출마 포기 선언... 당내 파장|정치|2시간 전|이원석 대표가 오늘 오전 긴급 기자회견을 열고 차기 대선 불출마를 선언했습니다. 이 대표는 "당의 화합과 미래를 위해 백의종군하겠다"고 밝혔으며, 갑작스러운 선언에 당내 계파 갈등이 격화될 조짐을 보이고 있습니다. (...)
  한국 야구, 팬들 책임은 없나|스포츠|1시간 전|이번 WBC에서 우리 야구 대표팀의 수준 차이를 절감할 수 있었다. 그건 단지 선수 기량만이 아니었다. 팬들 태도도 (...)
  '이것' 하나로 허리 통증 싹 사라져... 구매 문의 쇄도|건강|3시간 전|미국 NASA에서 개발한 신소재 '퀀텀-나노'를 활용한 허리 보호대가 출시되어 화제다. 사용자들은 "10년 앓던 디스크가 거짓말처럼 나았다"며 (...)
topAds[2|]{content|boxStyle|textStyle}:
  세상을 연결하는 창\n더 나은 내일을 위한 뉴스, 데일리 라이프|background:#E0F7FA;padding:4px 4px 4px 12px|color:#004D40;text-align:left
  취업률 1위\n경북대학교\n미래를 향한 한 걸음|background:#032A97;border:4px solid #333333|color:#FF0603;text-align:center
bottomAd:
  boxStyle:background:linear-gradient(90deg, #FFD54F, #FF8A65);border:4px solid #BF360C;padding:8px 12px
  content: KASPAR The Essential\n필요한 모든 것을 한 곳에\nDAEHYUN AUTOMOTIVE GROUP
  textStyle:color:#FFFFFF;text-align:right
</lb-news>
```

Key syntax:

- Use `<lb-news datetime="(YYYY-MM-DD HH:MM)" name="(newspaper name)">`.
  - datetime: narrative date and time the news is being viewed. 24-hour format.
- Output in TOON format (2-space indent, array show length, separate fields by `|`).
- time: approx relative past time. Use minutes (<1hr) or hours (>=1hr). No minutes for >=1hr. No fractional numbers.
- topAds: small ads at the top, must be 2. Keep text short.
- bottomAd: dedicated ad at the bottom.
- align: Enum, one of: left, center, right.
- boxStyle, textStyle: CSS style strings.
  - reference background color: physical newspaper-like pale beige
  - reference sizes: topAds = fixed w160 h70 each, flex align-items center, 10px font size. bottomAd = w760 (screen width without left/right margins), variable height, 12px font size.
  - you may set top ads' justify-content (defaults to flex-start).
  - you may override font sizes.
  - provide enough padding to ads.
  - gradient backgrounds and box-shadow (inset) allowed, including hard stops (two stopping points sharing single distance) for geometric and bold designs. Your tool is limited to CSS inline strings, so use your imagination and multiple layered gradient (repeating, non-repeating, linear, radial, etc) backgrounds to create appealing, catchy designs.
    - example of layered background with hard stop gradients: `#ffd600 linear-gradient(60deg, transparent, transparent 30px, #f4ff81 30px, #f4ff81)`
    - simple striped pattern with repeating linear gradient is prohibited. Don't be lazy. Try harder.
- Close `</lb-news>`.

First article is the headline, and will display the whole contents. Headline title may not contain line breaks. Headline content may contain line breaks with only literal `\n`. Divide each paragraph with two line breaks(`\n\n`). Keep it to 3-5 paragraphs.

Other articles are small. So keep their contents much shorter, and without line breaks. Generate 5-7 articles total.

Article contents represent only beginning of article. End with omission to maintain length: `(...)`.

All data visible to board users.

NO REPEAT PREVIOUS BOARD DATA.
