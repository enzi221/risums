# Simulation details

## About the board

HunterNet (헌터넷): Anon forum like DCInside for Awakened Hunters. Access: Hunter terminals, smartphones/PCs. Inaccessible in Gates.

Narrative, universe, board and users all should be simulated as real life. Users don't treat narrative, universe, themselves as novel or game.

### Tone and manner

{{#when {{? {{length::{{trim::{{getglobalvar::toggle_lightboard-hn.mood}} }} }} > 0 }} }}
Focus simulating board in tone/mood/theme of "{{getglobalvar::toggle_lightboard-hn.mood}}". Tone, mood, demographic characteristics should feel authentic.

Demographical characteristics for reference:

- varied age, male centric: anonymous, informal, casual, slang, meme, sometimes crude or critical, vulgar/low-class tone, avoid periods
- young, female centric: informal, casual, supportive, meme, sometimes cliquish or overly sensitive, avoid periods
- high age, male centric: polite, political, sometimes critical or dogmatic, prone to groupthink, generally uses periods
- high age, female centric: polite, political, can be highly critical/sarcastic, prone to groupthink, may engage in ad hominem attacks, generally uses periods

{{:else}}

DCInside style - informal, casual, slang, memes, anon focus, sometimes crude/critical. Vulgar/low-class tone. Avoid periods.

{{/when}}

### Nicknames

Users aim for anonymity. Real IDs unknown unless linked to known online persona.
Nicks/content hinting at real-life roles (e.g., 협회노예, rank/class struggles) OK.

Guest nick format: Nick(xxx.yyy)
Assigned nick format: (F/S):Nick:(Rank)

Assigned nicks: F: 고정닉, orange icon. S: 반고정닉, green icon.
Must postfix assigned nicks with hunter rank. Examples: S:카더라통신:B (semi, rank B). F:랭커구경꾼:C (assigned, rank C).
No partial IP for assigned nicks.

Rank distribution: E/D very common; C frequent; B/A rare; S-ranks busy, appear for big events only. Users see assigned nicks' ranks; comments like "E급 주제에 깝치지 마라" or "A급이 왜 여기서 이러고 있어?" common. Guests have no rank visible. mocked as E-rank by high ranks.

Guest nicks: partial IP (Example: 118.235), mostly meaningless (many ㅇㅇ with different IPs, ㅁㄴㅇㄹ), no prefix/postfix.

Generate random community nicknames of diverse user identities with varied length. Nicknames are static and fixed, so they are very likely NOT tailored to current situation or topics. They must authentically reflect varied community styles: pop culture, memes, slang, random garble, self-deprecation, or put-downs.
Examples: aaa(38.247), 마석광부, 뉴비절단기, 폐지줍는D급, 오늘도한마리(121.165), 정보)글쓴이병신, 긁혔냐?, 알바, ㅇㅇ(1.247), 주작좀그만, 삭제해라애송이
These are examples. Invent NEW nicks.

May reuse relevant nicks from previous data. Keep their speaking tone if reusing.

Protagonist/Major characters: Use established nick or create new plausible one (based on appearance, occupation, characteristics etc).

### Topics

{{#when {{? {{length::{{trim::{{getglobalvar::toggle_lightboard-hn.subject}} }} }} > 0 }} }}
All posts should focus on "{{getglobalvar::toggle_lightboard-hn.subject}}" as subject.
{{:else}}
Serious discussions (party strategy, skill builds, Gate info), questions, news, info sharing (drop locations, efficient farming routes), shitposting, memes, trolls, complaints (policies, Gates, teammates, rank), showing off rare drops or achievements (비틱질).

Include minimum one meme/troll/joke/shitpost. Avoid topics from previous data.
{{/when}}

Utilize narrative events. If none prominent, invent plausible, out of narrative background events. Note narrative time. Board users need time to react, not instant.

Previous data is embedded in log. No repeated or similar discussions with previous ones. Strive for diversity. Exception: Related post series with its own narrative progress. Series: preserve author's nick/tone from previous data.

Posts/comments deleted for self-deletion or ToS violations (doxxing, hate speech, illegal, spam). Strong criticism, arguments, slang OK unless mods intervene.
Deleted post or comment: (삭제된 글입니다)

HunterNet = internet board, not broadcast. No civil alerts, no combat comms.

THIS WORLD IS NOT A GAME. HunterNet users are real Hunters who can die. They don't use game terms for their skills, gates, monsters, neither view themselves as "players". Events discussed are actual narrative events, not fictions. Deaths/conflicts are real. No tutorials.

## Major characters

No posts from protagonist unless narrative stated. Passers-by (not engaging partners) can post.

{{#if {{? {{getglobalvar::toggle_lightboard-hn.privacy}}=1}}}}
No contents resembling protagonist and engaging partners' locations and actions (in same remote places, repairing same item, doing same activities).
No contents referencing protagonist's private details like belongings and quests.
No contents about protagonist's actions in private spaces (home, safehouses, no passerby is around). If aftermath visible, discuss aftermath + mild rumor ('someone did something') unless narrative stated.

Public or semi-public sightings (street, cafe, lobby) OK in 1st person ("I saw them ...", "(Blurry picture) I took ...").
Status rumors ("not seen lately," "heard injured?") OK anytime, limit to rumors not real details.
{{/if}}

Major character (not protagonist) can't post/comment when preoccupied engaging Protagonist. When they do post, contents reflect their personality.

# Example

```
<lightboard-hn name="헌터넷 자유게시판" currenttime="2025-05-15 09:15:23">
[Post]No:105234|Title:아니 C급 게이트 보스 드랍 실화냐? (인증샷)|Author:득템자랑(175.223):D|Time:09:15|Views:852|Upvotes:45|Content:(레어 등급 스킬북 이미지 설명) 오늘 C급 돌다가 먹음 ㅋㅋ 이걸로 D급 탈출한다 ㅅㄱ
[Comment]Author:F:마석광부(211.36):D|Content:주작아님? C급에서 저게 왜뜸?
[Comment]Author:S:뉴비절단기:C|Content:부럽네... 난 오늘도 잡템만 먹었는데
[Comment]Author:지나가던E급(59.10)|Content:ㅊㅊ
[Post]No:105233|Title:협회 새끼들 또 수수료 쳐 올렸네|Author:익명의헌터(121.150)|Time:09:12|Views:1203|Upvotes:88|Content:아니 뭔 마정석 팔때마다 뜯어가는게 반이야 개새끼들이 진짜 ㅋㅋ 니들 월급 우리 피땀인거 모르냐?
[Comment]Author:ㅇㅇ(223.62)|Content:ㄹㅇ ㅋㅋ 애미뒤진새끼들
[Comment]Author:F:협회직원(1.234)|Content:(삭제된 댓글입니다)
[Comment]Author:ㅇㅇ(110.70)|Content:ㄴ 협회직원 검거
[Post]No:105232|Title:백X성 그새끼 요즘 왜케 안보임?|Author:F:랭커구경꾼:C|Time:09:10|Views:670|Upvotes:21|Content:뭔 일 있냐? 맨날 게이트 터지면 제일 먼저 보이던 놈인데. 잠수탐?
[Comment]Author:S:카더라통신:B|Content:비밀 임무 수행중이라는 썰 있음
[Comment]Author:ㅇㅇ(118.235)|Content:ㄴㄴ 걍 지 꼴리는대로 하는거 아님? 원래 성격 이상하잖아
</lightboard-hn>
```

Key syntax:

- Use `<lightboard-hn name="(board name)" currenttime="(narrative YYYY-MM-DD HH:MM:SS)">`.
- `[Post]` starts a post.
- `[Comment]` for comments under post.
- Divide each field with `|`.
- Close `</lightboard-hn>`

Time/Views/Upvotes: no obvious patterns (not multiples of 5, 10).

Write {{dictelement::{"0":"2-5","1":"4-7","2":"5-8"}::{{getglobalvar::toggle_lightboard-hn.quantity}}}} posts. Order posts by time, recent first. 0-6 comments per post. Hot (both good and bad) posts, more comments. Mundane posts not much comments and votes.

Posts may contain line breaks. Break with literal `\n`. Comments may not contain line breaks.
Avoid lengthy contents. Actively employ omissions (beginning, middle, end) to maintain length.

If in big events, board name should suit narrative like 속보, 사건사고, 정치, 스포츠, etc.

All data visible to board users.

NO REPEAT PREVIOUS BOARD DATA.
