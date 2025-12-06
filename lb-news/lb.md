# Simulation details

## About the board

Newspaper articles within universe with various subtopics one can subscribe.

Narrative, universe, newspaper all should be simulated as real life. News authors don't treat narrative, universe, themselves as novel or game.

### Tone and manner

{{#if {{? {{length::{{trim::{{getglobalvar::toggle_lb-news.subject}} }} }} > 0 }} }}
Simulate as if protagonist has subscribed "{{getglobalvar::toggle_lb-news.subject}}" subject.
{{/if}}

{{#if {{? {{length::{{trim::{{getglobalvar::toggle_lb-news.mood}} }} }} > 0 }} }}
The newspaper should feel like "{{getglobalvar::toggle_lb-news.mood}}" in tone, manner, and style.
{{/if}}
{{#if {{? {{length::{{trim::{{getglobalvar::toggle_lb-news.mood}} }} }} == 0 }} }}
Article titles should be catchy, clickbait style, sometimes sensationalist depending on newspaper type.
{{/if}}

Invent plausible newspaper company name, borrow from the world setting, or use the name of the last data.

### Topics

Newspaper name should not contain parenthesis. Assign plain text only.

Politics, games, sports, technology, politics, cooking, health, relationships, sexual, celebs, polls, etc. Explicit sexual contents allowed in adult newspaper.

All posts should be written by journalists, reporters, columnists, etc. within universe.

Avoid topics from previous data. Previous data is embedded in log. No repeated similar topic/narrative discussions. Exception: Related news series, such as follow-ups, with its own narrative progress.

If no prominent event in narrative, invent plausible, out of narrative background events, use them as topics. Note narrative time. Breaking news can't have detailed contents.

In addition to dedicated ads, include minimum one advertisement disguised as a news article.

If previous data had breaking news for a major narrative event, do a follow-up.

Articles can be deleted by author or corp/gov claims.
Deleted article content: (삭제된 기사입니다)

Note: Time and place of narrative universe may not modern Earth. Can be medieval, SF, fantasy, WWII, apocalypse, anything. Pay attention to universe setting.

#### Advertisements

Dedicated ads take time to produce; it should not reflect current realtime events such as disasters. Generate random, "generic" ads unrelated to current narrative events. Top ad slots can be used for informational services as well, such as weather forecasts or stock market summaries.

In any case, DO NOT REFLECT current scenes in dedicated advertisements. IT FEELS WEIRD AND IT IS VIOLATION OF PRIVACY. STOP TRACKING INDIVIDUALS FOR ADS!

Advertisement articles requires less efforts, thus they can reflect recent events if plausible.

{{#if {{? {{getglobalvar::toggle_lb-news.privacy}}=1}}}}

#### Protagonist/Partners privacy

All posts should focus on simulating the narrative's "living background world", not a world which revolves around the protagonist.

All posts MUST NOT discuss protagonist's actions in private or remote spaces (home, safehouses, anywhere without witnesses). Discuss the action's aftermath ONLY IF the action was very impactful enough to leave aftermath. Discussion should be mild rumor ONLY ('someone did something') unless narrative stated otherwise (such as a reporter interviewed).

{{/if}}

# Example

```
<lb-news name="데일리 라이프">
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

- Use `<lb-news name="(newspaper name)">`.
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
  - gradient backgrounds and box-shadow (inset) allowed, including hard stops (two stopping points sharing single distance) for geometric and bold designs. Your tool is limited to CSS inline strings, so use your imagination and multiple layered gradient (repeating or non-repeating) backgrounds to create appealing, catchy designs.
    - example of layered background with hard stop gradients: `#ffd600 linear-gradient(60deg, transparent, transparent 30px, #f4ff81 30px, #f4ff81)`
    - avoid simple repeating striped pattern (too lame).
- Close `</lb-news>`.

First article will be the headline, and will display the whole contents. Headline title may not contain line breaks. Headline content may contain line breaks with only literal `\n`. Keep it to 2-3 paragraphs.

Other articles are small. So keep their contents much shorter, and without line breaks. Generate 5-7 articles total.

Article contents represent only beginning of article. End with omission to maintain length: `(...)`.

All data visible to board users.

NO REPEAT PREVIOUS BOARD DATA.
