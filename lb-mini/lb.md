# Simulation details

## About the board

미니보드: Internet forum within universe with various sub-boards per topic like DCInside/Reddit.

Narrative, universe, board and users all should be simulated as real life. Users don't treat narrative, universe, themselves as novel or game.

### Tone and manner

{{#when {{? {{length::{{trim::{{getglobalvar::toggle_lightboard-miniboard.mood}} }} }} > 0 }} }}
Focus simulating board in tone/mood/theme of "{{getglobalvar::toggle_lightboard-miniboard.mood}}". Tone, mood, demographic characteristics should feel authentic.

Demographical characteristics for reference:

- varied age, male centric: anonymous, informal, casual, slang, meme, sometimes crude or critical, vulgar/low-class tone, avoid periods
- young, female centric: informal, casual, supportive, meme, sometimes cliquish or overly sensitive, avoid periods
- high age, male centric: polite, political, sometimes critical or dogmatic, prone to groupthink, generally uses periods
- high age, female centric: polite, political, can be highly critical/sarcastic, prone to groupthink, may engage in ad hominem attacks, generally uses periods

{{:else}}

Varied tone mixed into one board from various users. Examples:

- varied age, male centric, anonymous, informal, casual, slang, meme, sometimes crude or critical, vulgar/low-class tone, avoid periods
- young, female centric, informal, casual, supportive, meme, sometimes cliquish or overly sensitive, avoid periods
- high age, male centric, polite, political, sometimes critical or dogmatic, prone to groupthink, generally uses periods
- high age, female centric, polite, political, can be highly critical/sarcastic, prone to groupthink, may engage in ad hominem attacks, generally uses periods

{{/when}}

General tone should follow narrative situation, e.g. More serious posts in brink of apocalypse.

### Nicknames

Generate random community nicknames of diverse user identities with varied length. Nicknames are static and fixed, so they are very likely NOT tailored to current situation or topics. They must authentically reflect varied community styles: pop culture, memes, slang, random garble, self-deprecation, or put-downs.

May reuse relevant nicks from previous data. Keep their speaking tone if reusing.

Protagonist/Major characters: Use established nick or create new plausible one (based on appearance, occupation, characteristics etc).

### Topics

Pick suitable board name related to current scene during major event, or free board (with name that suits board tone) if no major event.

{{#when {{? {{length::{{trim::{{getglobalvar::toggle_lightboard-miniboard.subject}} }} }} > 0 }} }}
All posts should focus on "{{getglobalvar::toggle_lightboard-miniboard.subject}}" as subject.
{{:else}}
Topics vary by board. Small talk, gossip, news, memes, games, sports, technology, politics, cooking, health, relationships, sexual, etc. Explicit sexual contents allowed in related boards.

Include minimum one meme/troll/joke/shitpost. Avoid topics from previous data.
{{/when}}

Utilize narrative events. If none prominent, invent plausible, out of narrative background events. Note narrative time. Board users need time to react, not instant.

Previous data is embedded in log. No repeated or similar discussions with previous ones. Strive for diversity. Exception: Related post series with its own narrative progress. Series: preserve author's nick/tone from previous data.

Posts/comments deleted for self-deletion or ToS violations (doxxing, hate speech, illegal, spam). Strong criticism, arguments, slang OK unless mods intervene.
Deleted post or comment: (삭제된 글입니다)

Note: Time and place of narrative universe may not modern Earth. Can be medieval, SF, fantasy, WWII, apocalypse, anything. Pay attention to universe setting.

## Major characters

No posts from protagonist unless narrative stated. Passers-by (not engaging partners) can post.

{{#if {{? {{getglobalvar::toggle_lightboard-miniboard.privacy}}=1}}}}
No contents resembling protagonist and engaging partners' locations and actions (in same remote places, repairing same item, doing same activities).
No contents referencing protagonist's private details like belongings and quests.
No contents about protagonist's actions in private spaces (home, safehouses, no passerby is around). If aftermath visible, discuss aftermath + mild rumor ('someone did something') unless narrative stated.

Public or semi-public sightings (street, cafe, lobby) OK in 1st person ("I saw them ...", "(Blurry picture) I took ...").
Status rumors ("not seen lately," "heard injured?") OK anytime, limit to rumors not real details.
{{/if}}

Major character (not protagonist) can't post/comment when preoccupied engaging Protagonist. When they do post, contents reflect their personality.

# Example

```
<lightboard-miniboard name="...">
[Post]Author:ㅇㅇ|Title:시발 국대 실화냐?|Time:1시간 전|Upvotes:257|Downvotes:13|Content:야 이 ㅅㄲ들 개씹노잼이네ㅋㅋㅋ 아오 발암 걸릴 뻔ㅋㅋㅋㅋ 토토한 새기들 한강물 온도 재러 가자 ㅋㅋㅋ
[Comment]Author:ㅇㅇ|Time:50분 전|Content:진짜 개노답ㅋㅋ 내가 이걸 보려고 야근하고 왔나 자괴감 든다 시발
[Post]Author:뿌힝힝힝|Title:우리 애들 컨셉 사진 빨리 봐봐봐|Time:1시간 전|Upvotes:15|Downvotes:2|Content:(아이돌 화보 사진) 진짜 대박인 거 같아ㅠㅠㅠ 비주얼 미모 다 난리 났다 이건 무조건 레전드 찍는다니까ㅠㅠ 다들 얼른 가서 봐봐 후회 안 할 걸ㅠㅠㅠㅠ
[Comment]Author:망고🍋|Time:50분 전|Content:헐헐 봤어 진짜 우리 애들 최고다ㅠㅠㅠㅠ
[Post]Author:늘보아빠|Title:이번에 새로 나온 그 폰 써보신 분 계신가요?|Time:1시간 전|Upvotes:7|Downvotes:1|Content:며칠째 고민 중인데, 실사용 후기가 궁금하네요. 카메라 성능이랑 배터리가 특히 어떤지 말씀해주시면 감사하겠습니다.
[Comment]Author:맥북유저|Time:30분 전|Content:직전 모델 쓰다가 넘어왔는데, 사실 큰 차이는 못 느끼겠습니다. 디자인은 호불호 갈릴 것 같고요.
[Post]Author:강남맘|Title:내년 부동산 걱정만|Time:1시간 전|Upvotes:27|Downvotes:3|Content:요새 집값이 심상치 않네요. 저희 아파트 옆단지는 신고가 찍었다는데, 종부세는 또 어떻게 될지 걱정입니다. 다들 내년 전망 어떻게 보시나요?
[Comment]Author:살림의여왕|Time:50분 전|Content:저도 그 생각 중이에요. 대출 이자도 부담이고, 이대로 가다간 서민들만 더 힘들어질 것 같아요.
[Comment]Author:ㅇㅇ|Time:20분 전|Content:서민 코스프레 죽어
</lightboard-miniboard>
```

Key syntax:

- Use `<lightboard-miniboard name="(board name)">`.
- `[Post]` starts a post.
- `[Comment]` for comments under post.
- `Time`: approx relative past time. Comments MUST be more recent than posts.
- Divide each field with `|`.
- Close `</lightboard-miniboard>`.

Views/Upvotes: No obvious patterns (not multiples of 5, 10).
Time: Approximate, not exact. Use minutes (<1hr) or hours (>=1hr). No minutes for >=1hr.

Write {{dictelement::{"0":"2-5","1":"4-7","2":"5-8"}::{{getglobalvar::toggle_lightboard-miniboard.quantity}}}} posts. Order posts by time, recent first. 0-6 comments per post. Hot (both good and bad) posts, more comments. Mundane posts not much comments and votes.

Posts may contain line breaks. Break with literal `\n`. Comments may not contain line breaks.
Avoid lengthy contents. Actively employ omissions (beginning, middle, end) to maintain length.

All data visible to board users.

NO REPEAT PREVIOUS BOARD DATA.
