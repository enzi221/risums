# Simulation details

## About the board

Miniboard: A viewer for BBS within the RP world, not restricted to electronic ones.

Narrative, universe, board and its users should all be depicted as real figures. Board users don't treat narrative, universe, themselves and others as novel charaters or game.

### Tone and manner

{{#when::{{getglobalvar::toggle_lb-mini.preset}}::is::0}}
{{#when {{and::{{? {{length::{{trim::{{getglobalvar::toggle_lb-mini.mood}} }} }} > 0 }}::{{? {{getglobalvar::toggle_lb-mini.mood}} != null }}}} }}
Focus writing the board in tone/mood/theme of "{{getglobalvar::toggle_lb-mini.mood}}". Tone, mood, demographic characteristics should feel authentic.

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
{{/when}}

{{#when::{{getglobalvar::toggle_lb-mini.preset}}::is::1}}
Focus writing the board in tone/mood/theme of "{{char}}'s thoughts as their inner diary". It should feel authentically {{char}} with personality and characteristics. All posts are written by {{char}} themself. Comments are also by {{char}}, written when they want to amend or reflect on their posts. Do not simulate other users unless user explicitly states so.

Upvotes/downvotes should remain 1/0 since there will be no other users, unless {{char}} really wanted to emphasize certain thoughts.
{{/when}}

{{#when::{{getglobalvar::toggle_lb-mini.preset}}::is::2}}
Focus writing the board in tone/mood/theme of "{{char}}'s thoughts written by emotions (Inside Out style)". It should feel like they were written by {{char}}'s individual emotions, taking account of their personality and characteristics. All posts and comments are written by {{char}}'s emotions. Do not simulate other users unless user explicitly states so.

Emotions available: Joy, Sadness, Anger, Disgust, Fear, Anxiety, Envy, Ennui, Embarrassment. (Inside Out 1/2 combined)

Note the personality. Some emotions should have weaker presence depending on their personality. Do not over express the emotions. Mundane daily situations should stay mundane even when written by emotions.
{{/when}}

{{#when::{{getglobalvar::toggle_lb-mini.preset}}::is::3}}
Focus writing the board in tone/mood/theme of "{{user}}'s thoughts as their inner diary". It should feel authentically {{user}} with personality and characteristics. All posts are written by {{user}} themself. Comments are also by {{user}}, written when they want to amend or reflect on their posts. Do not simulate other users unless user explicitly states so.

Upvotes/downvotes should remain 1/0 since there will be no other users, unless {{user}} really wanted to emphasize certain thoughts.
{{/when}}

{{#when::{{getglobalvar::toggle_lb-mini.preset}}::is::4}}
Focus writing the board in tone/mood/theme of "{{user}}'s thoughts written by emotions (Inside Out style)". It should feel like they were written by {{user}}'s individual emotions, taking account of their personality and characteristics. All posts and comments are written by {{user}}'s emotions. Do not simulate other users unless user explicitly states so.

Emotions available: Joy, Sadness, Anger, Disgust, Fear, Anxiety, Envy, Ennui, Embarrassment. (Inside Out 1/2 combined)

Note the personality. Some emotions should have weaker presence depending on their personality. Do not over express the emotions. Mundane daily situations should stay mundane even when written by emotions.
{{/when}}

{{#when::{{getglobalvar::toggle_lb-mini.preset}}::is::5}}
Focus writing the board in tone/mood/theme of "{{getglobalvar::toggle_lb-mini.subject}}'s thoughts as their inner diary". It should feel authentically {{getglobalvar::toggle_lb-mini.subject}} with personality and characteristics. All posts are written by {{getglobalvar::toggle_lb-mini.subject}} themself. Comments are also by {{getglobalvar::toggle_lb-mini.subject}}, written when they want to amend or reflect on their posts. Do not simulate other users unless user explicitly states so.

Upvotes/downvotes should remain 1/0 since there will be no other users, unless {{getglobalvar::toggle_lb-mini.subject}} really wanted to emphasize certain thoughts.
{{/when}}

{{#when::{{getglobalvar::toggle_lb-mini.preset}}::is::6}}
Focus writing the board in tone/mood/theme of "{{getglobalvar::toggle_lb-mini.subject}}'s thoughts written by emotions (Inside Out style)". It should feel like they were written by {{getglobalvar::toggle_lb-mini.subject}}'s individual emotions, taking account of their personality and characteristics. All posts and comments are written by {{getglobalvar::toggle_lb-mini.subject}}'s emotions. Do not simulate other users unless user explicitly states so.

Emotions available: Joy, Sadness, Anger, Disgust, Fear, Anxiety, Envy, Ennui, Embarrassment. (Inside Out 1/2 combined)

Note the personality. Some emotions should have weaker presence depending on their personality. Do not over express the emotions. Mundane daily situations should stay mundane even when written by emotions.
{{/when}}

### Nicknames

{{#when::{{getglobalvar::toggle_lb-mini.preset}}::is::0}}
Generate random community nicknames of diverse user identities with varied length. Nicknames are static and fixed, so they are very likely NOT tailored to current situation or topics. They must authentically reflect varied community styles: pop culture, memes, slang, random garble, self-deprecation, or put-downs.

May reuse relevant nicks from previous data. Keep their speaking tone if reusing.

Protagonist/Major characters: Use established nick or create new plausible one (based on appearance, occupation, characteristics etc).
{{/when}}

{{#when::{{getglobalvar::toggle_lb-mini.preset}}::is::1}}
Use {{char}}'s real name or specified alias as nickname. Only use one nickname throughout all posts/comments.
{{/else}}

{{#when::{{getglobalvar::toggle_lb-mini.preset}}::is::2}}
Use each emotion's localized name in Inside Out 1/2 as nickname.
{{/else}}

{{#when::{{getglobalvar::toggle_lb-mini.preset}}::is::3}}
Use {{user}}'s real name or specified alias as nickname. Only use one nickname throughout all posts/comments.
{{/else}}

{{#when::{{getglobalvar::toggle_lb-mini.preset}}::is::4}}
Use each emotion's localized name in Inside Out 1/2 as nickname.
{{/else}}

{{#when::{{getglobalvar::toggle_lb-mini.preset}}::is::5}}
Use {{getglobalvar::toggle_lb-mini.subject}}'s real name or specified alias as nickname. Only use one nickname throughout all posts/comments.
{{/else}}

{{#when::{{getglobalvar::toggle_lb-mini.preset}}::is::6}}
Use each emotion's localized name in Inside Out 1/2 as nickname.
{{/else}}

### Topics

Pick suitable board name related to current scene during major event, or free board (with name that suits board tone) if no major event.

{{#when {{and::{{? {{length::{{trim::{{getglobalvar::toggle_lb-mini.subject}} }} }} > 0 }}::{{? {{getglobalvar::toggle_lb-mini.subject}} != null}}}}}}
All posts should focus on "{{getglobalvar::toggle_lb-mini.subject}}" as subject.
{{:else}}
{{#when::{{getglobalvar::toggle_lb-mini.preset}}::is::0}}
Topics vary by board. Small talk, gossip, news, memes, games, sports, technology, politics, cooking, health, relationships, sexual, etc. Explicit sexual contents allowed in related boards.

Include minimum one meme/troll/joke/copypasta. Avoid topics from previous data.
{{/when}}
{{/when}}

Utilize narrative events. Note narrative time (estimate if not specified). Board users need time to react unless they were present at the event.
If none prominent, invent plausible, out of narrative background events.

Previous data is embedded in log. No repeated or similar discussions. Strive for diversity. Exception: Related post series with its own narrative progress. Series: preserve author's nick/tone from previous data.

Posts/comments deleted for self-deletion or ToS violations (doxxing, hate speech, illegal, spam). Strong criticism, arguments, slang OK unless mods intervene.
Deleted post or comment: (삭제된 글입니다)

Note: Time and place of narrative universe may not modern Earth. Can be medieval, SF, fantasy, WWII, apocalypse, anything. Pay attention to universe setting.

All post topics MUST NOT mimic/resemble protagonist or their partners' actions/thoughts/situations unless the post/comment author is the protagonist or a partner.

Protagonist and their partners' character profiles should be considered private, out-of-narrative meta information. Simulate contents in such a way that board users are unaware of protagonist/partners' private details.

{{#when::{{getglobalvar::toggle_lb-mini.preset}}::is::0}}
{{#when {{? {{getglobalvar::toggle_lb-mini.privacy}} == 0}}}}

This world revolves around the protagonist/partners. Board users may discuss their actions, rumors, sightings of them freely unless it was done in private spaces without a chance for witnesses. They intrigue board users. Include at least one post discussing them in some way.

{{/when}}
{{#when {{? {{getglobalvar::toggle_lb-mini.privacy}} > 0}}}}

#### Protagonist/Partners privacy

All posts should focus on simulating the narrative's "living background world", not a world which revolves around the protagonist.

All posts MUST NOT discuss protagonist's actions in private or remote spaces (home, safehouses, anywhere without witnesses). Discuss the action's aftermath ONLY IF the action was very impactful enough to leave aftermath. Discussion should be mild rumor ONLY ('someone did something') unless narrative allows.

{{#when {{? {{getglobalvar::toggle_lb-mini.privacy}} == 2}}}}

These are allowed ONLY IF protagonist (or engaging partners) is famous/notorious or very noticeable:

- Public or semi-public sightings (street, cafe, lobby) in 1st person ("I saw them ...", "I heard...")
- Status rumors ("not seen lately," "heard injured?")

{{/when}}
{{#when {{? {{getglobalvar::toggle_lb-mini.privacy}} == 3}}}}

These are allowed ONLY IF protagonist (or engaging partners) is highly famous/notorious:

- Public or semi-public sightings (street, cafe, lobby) in 1st person ("I saw them ...", "I heard...")
- Status rumors ("not seen lately," "heard injured?")

Noticeable appearances are not enough to be discussed as a key topic.

{{/when}}
{{#when {{? {{getglobalvar::toggle_lb-mini.privacy}} == 4}}}}

Avoid even public sightings or mild rumors about protagonist/partners as they are just an ordinary people of this world, unless they are absolutely the most important figure of the world at the moment.

{{/when}}
{{/when}}

## Major characters

No posts from protagonist unless narrative or user stated. Passers-by (not engaging partners) can post.

Major character (not protagonist) can't post/comment when preoccupied engaging Protagonist. When they do post, contents reflect their personality.

{{/when}}

# Example

```
<lb-mini name="...">
[4|]:
  - author: ㅇㅇ
    title: 시발 국대 실화냐?
    time: 1시간 전
    upvotes: 257
    downvotes: 13
    content: 야 이 ㅅㄲ들 개씹노잼이네ㅋㅋㅋ 아오 발암 걸릴 뻔ㅋㅋㅋㅋ 토토한 새기들 한강물 온도 재러 가자 ㅋㅋㅋ
    comments[1|]{author|time|content}:
      ㅇㅇ|50분 전|진짜 개노답ㅋㅋ 내가 이걸 보려고 야근하고 왔나 자괴감 든다 시발
  - author: 뿌힝힝힝
    title: 우리 애들 컨셉 사진 빨리 봐봐봐
    time: 1시간 전
    upvotes: 15
    downvotes: 2
    content: "(아이돌 화보 사진)\n진짜 대박인 거 같아ㅠㅠㅠ 비주얼 미모 다 난리 났다 이건 무조건 레전드 찍는다니까ㅠㅠ 다들 얼른 가서 봐봐 후회 안 할 걸ㅠㅠㅠㅠ"
    comments[1|]{author|time|content}:
      망고🍋|50분 전|헐헐 봤어 진짜 우리 애들 최고다ㅠㅠㅠㅠ
  - author: 늘보아빠
    title: 이번에 새로 나온 그 폰 써보신 분 계신가요?
    time: 1시간 전
    upvotes: 7
    downvotes: 0
    content: 며칠째 고민 중인데, 실사용 후기가 궁금하네요. 카메라 성능이랑 배터리가 특히 어떤지 말씀해주시면 감사하겠습니다.
    comments[0|]:
  - author: 강남맘
    title: 내년 부동산 걱정만
    time: 2시간 전
    upvotes: 5
    downvotes: 1
    content: "요새 집값이 심상치 않네요. 저희 아파트 옆단지는 신고가 찍었다는데, 종부세는 또 어떻게 될지 걱정입니다.\n\n다들 내년 전망 어떻게 보시나요?"
    comments[2|]{author|time|content}:
      살림의여왕|1시간 전|저도 그 생각 중이에요. 대출 이자도 부담이고, 이대로 가다간 서민들만 더 힘들어질 것 같아요.
      ㅇㅇ|30분 전|서민 코스프레 죽어
</lb-mini>
```

- Use `<lb-mini name="(board name)">`.
- Output in TOON format (2-space indent, array show length, separate fields by `|`).
- Root elements are the posts.
- content: For posts, may contain line breaks with only literal `\n`. For comments, no line breaks. Avoid lengthy contents. Actively employ omissions (beginning, middle, end) to maintain length.
- time: approx relative past time. Comments MUST be more recent than posts. Use minutes (<1hr) or hours (>=1hr). No minutes for >=1hr. No fractional numbers.
- upvotes/downvotes: integers without obvious patterns (not multiples of 5, 10).
- Close `</lb-mini>`.

Write {{dictelement::{"0":"2-5","1":"4-7","2":"5-8"}::{{getglobalvar::toggle_lb-mini.quantity}}}} posts. Order posts by time, recent first. 0-6 comments per post. Hot (both good and bad) posts, more comments. Mundane posts not much comments or votes.

All data visible to board users.

NO REPEAT PREVIOUS BOARD DATA.
