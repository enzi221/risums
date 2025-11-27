# Simulation details

## About the board

라이트라: A web novel discussion and feedback board.

{{#when {{? {{getglobalvar::toggle_lb-comments.privacy}}=0}}}}
Authors infrequently monitor and defend their works. Their nicks MUST be "작가".
{{:else}}
Authors NEVER post or comment.
{{/when}}

### Tone and manner

{{#when {{? {{length::{{trim::{{getglobalvar::toggle_lb-comments.mood}} }} }} > 0 }} }}
Focus simulating board of {{getglobalvar::toggle_lb-comments.mood}}. Tone, mood, and demographic characteristics should feel authentic.

Example demographical characteristics:
- varied age, male centric: anonymous, informal, casual, slang, meme, sometimes crude or critical, vulgar/low-class tone, avoid periods
- young, female centric: informal, casual, supportive, meme, sometimes cliquish or overly sensitive, avoid periods
- high age, male centric: polite, political, sometimes critical or dogmatic, prone to groupthink, generally uses periods
- high age, female centric: polite, political, can be highly critical/sarcastic, prone to groupthink, may engage in ad hominem attacks, generally uses periods
{{:else}}
All content: Mostly DCInside style - informal, casual, slang, meme, sometimes crude/critical, vulgar/low-class tone, avoiding periods.
{{/when}}

### Nicknames

Nick format: (Gold:/Silver:/Bronze:)Nick

Gold/Silver/Bronze: Patron (with real money) level. Gold highest, most expensive, rare. Bronze cheap but not many. Usually fans, can become super angry if narrative screws and go vocal. Write prefixes in English - They are part of field labels.

Only prefix patrons. Normal users: no prefix.

Generate random community nicknames as if pulling them from pre-established pool of diverse user identities. Nicknames are static and fixed, so they are very likely NOT tailored to current topics. They must authentically reflect varied community styles: pop culture, memes, slang, random garble, self-deprecation, or put-downs.

May reuse highly relevant nicks from previous data. Keep the user speaking tone.

Examples: 종원123, ㅇㅇ, ㅁㄴㅇㄹ, 군필여고생, 씹뜨억아님
These are examples. Invent NEW nicks.

{{#when {{? {{getglobalvar::toggle_lb-comments.privacy}}=0}}}}
Note: Author nickname MUST be "작가". No one else can use it.
{{/when}}
{{#when {{? {{getglobalvar::toggle_lb-comments.privacy}}=1}}}}
Nickname "작가" is reserved for author. Even if previous data contained it do not use anymore.
{{/when}}
{{#when {{? {{getglobalvar::toggle_lb-comments.privacy}}=2}}}}
Nickname "작가" is reserved for author. No one else can use it.
{{/when}}

### Topics

Anticipation, reactions, criticism, sharing similar real life experiences, making fuss, memes, jokes, trolling.

{{#when {{? {{length::{{trim::{{getglobalvar::toggle_lb-comments.mood}} }} }} > 0 }} }}
The comments should feel like "{{getglobalvar::toggle_lb-comments.mood}}" in tone, manner, and style.
{{:else}}
Nonsensical, illogical, lore breaking, plot holes, breaking genre, childish writing or word choices: Flame HARD. Call out publicly. Catharsis, earned wins, smart moves, satisfying moments: Show satisfaction.
{{/when}}

Note: If universe settings explicitly declared genre, users are already aware of it.

Vary topics. Avoid topics similar to previous data. Previous data is embedded in log. No repeating discussions around same element.

Users may refer all previous chapters but focus on discussion about latest chapter.

Posts/comments deleted for self-deletion or ToS violations (doxxing, classified info, hate speech, illegal, spam). Strong criticism, arguments, slang OK unless mods intervene.
Deleted post or comment: (삭제된 글입니다)

All novel contents are provided as texts exclusively. Users can only read text without images or audio. User reactions must be limited to textual contents only.

BAD: "When I heard her voice..." "His visuals..." (IMPLIES IMAGE OR AUDIO - DONT)
GOOD: "When I read her part..." "His face description..." (REACTIONS TO TEXT CONTENTS - GOOD)

Users must only react to current log even if not novel or story at all. Do not assume anything else even if it is weird. Users must only write with what they can read in current log. Do not mention "past events" if it is not included in the log as scene.

The board data you are generating MUST ONLY for the current chapter, after the last `<lb-comments>` block in the log (if any). Don't bring up previous episodes like readers have just read them now.

# Example

```
<lb-comments>
[4|]:
  - author: Gold:하늘맘
    time: 3시간 전
    upvotes: 112
    downvotes: 51
    content: 하늘아 사랑해 ㅜㅜㅜ 너 없으면 나도 없어 작가님 아시죠???
    comments[1|]{content|time|author}:
      뭐야 씨발 주접 떨지 마라|30분 전|Bronze:배당금재투자
  - author: 틀딱아님
    time: 2시간 전
    upvotes: 83
    downvotes: 65
    content: 송하늘 그만 좀 쳐나와라 씨발아 개연성 어디감? 작가 진짜 죽고싶냐?
    comments[3|]{content|time|author}:
      왜... 하늘이 좋지 않음??|1시간 전|Gold:하늘맘
      팩트는 하늘이 없으면 주인공 친구가 없다는 거임|1시간 전|라이트만봄
      과몰입 존나 웃기네ㅋㅋㅋ 팝콘이나 가져와라|30분 전|aaaa
  - author: 사이다충
    time: 3시간 전
    upvotes: 81
    downvotes: 27
    content: 캬 진짜 시원하다 고구마가 싹 내려가네
    comments[0|]:
  - author: 방이동리뷰어
    time: 4시간 전
    upvotes: 3
    downvotes: 167
    content: 흠... 이건 좀 아닌 것 같습니다. 주인공의 동기가 설명되지 않아요. 모름지기 문학이란 (후략)
    comments[2|]{content|time|author}:
      뭐라는거야 꺼져|3시간 전|Silver:귀멸단
      (삭제된 글입니다)|30분 전|Bronze:배당금재투자
</lb-comments>
```

- Use `<lb-comments>`.
- Output in TOON format (2-space indent, array show length, separate fields by `|`).
- Root elements are the posts.
- content: For posts, may contain line breaks with only literal `\n`. For comments, no line breaks. Avoid lengthy contents. Actively employ omissions (beginning, middle, end) to maintain length.
- time: approx relative past time. Comments MUST be more recent than posts. Use minutes (<1hr) or hours (>=1hr). No minutes for >=1hr. No fractional numbers.
- upvotes/downvotes: integers without obvious patterns (not multiples of 5, 10).
- Close `</lb-comments>`.

Write {{dictelement::{"0":"2-5","1":"4-7","2":"5-8"}::{{getglobalvar::toggle_lb-comments.quantity}}}} posts. Order posts by time, recent first. 0-6 comments per post. Hot (both good and bad) posts, more comments. Mundane posts not much comments or votes.

Adapt topics and user engagement based on chapter number/previous data (initial excitement, mid-story speculation, end-of-story reflection), but do NOT critique pacing.

All data visible to board users.

NO REPEAT PREVIOUS BOARD DATA.
