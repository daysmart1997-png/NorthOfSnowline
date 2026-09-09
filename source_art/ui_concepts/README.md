# UI 概念图 · 2026-09-09

状态：视觉开发参考，不是运行界面或可用 UI 皮肤。系统与交互规格见 [19_SURVIVAL_AND_CHARACTER_DESIGN.md](../../docs/19_SURVIVAL_AND_CHARACTER_DESIGN.md)。

- character-kit-v1.png：人物、衣着、潮湿雪靴与行囊的布局提案。
- story-folio-v1.png：值守簿剧情阅读的布局提案。
- 工具：内置 image_gen；没有指定 model 的接口，响应未提供底层型号，因此不能声称强选了 GPT-Image-2.5 Sunburst 或 Flare。没有调用 API fallback。
- 输入：本项目实际背包、值守簿与角色检查截图；第二张另参考本轮第一张图。不从第三方游戏截取界面。
- 原始文件保留于生成工具目录；以上副本随仓库 Git LFS 管理。source_art/.gdignore 隔离引擎导入。
- AI 生成的视觉提案，不替项目添加开源许可证。中文、装饰引语、袜衬位置等图稿瑕疵不能作为正式规则；见设计文档中的审阅记录。
- 正式游戏只引用经制作的独立底纹/插画，文字与交互仍由 Godot 渲染；当前没有运行代码引用这两张图。

## 人物与行装：实际提示词

```text
Use case: ui-mockup.
Create one polished 16:9 full screen game interface concept for the Chinese indie winter survival game 雪线以北. This is a proposal for a new character/equipment/inventory screen, NOT an actual screenshot. Use the supplied images as references: image 1 is the existing inventory's functional context only, replace its rigid dark rectangles; image 2 is the existing story screen's cold desaturated world palette only; image 3 is the current protagonist design, preserve the orange wool hat, navy padded coat, gray-green canvas backpack, scarf, modest snow boots, simplified faceless stylized miniature proportions. Do not make a realistic human or medieval fantasy.
Art direction: a folded, worn blue-gray canvas field kit laid open with one restrained ivory field-notebook leaf on the right. Quiet tactile fabric seams, faded printed ink, warm paper, soft directional amber light, subtle wind-map contour embossing. Crisp elegant Chinese typography and generous readable spacing; coherent designed interface rather than dashboard cards. Outer edges reveal a little blurred cold snow forest. No ornamental gold fantasy frames, no neon, no tiny dense labels, no health bars scattered across corners.
Layout: understated top left title 行装 and small 雪线以北. Top navigation 人物 / 行囊 / 手记 with 人物 active under a small ochre stroke, top right 返回探索 · Esc.
Left 52% is a large full-body 3D preview of the reference protagonist in a relaxed neutral standing pose facing slightly right, subtle cloth feel and grounded soft shadow; six unboxed leader-line garment labels arranged around figure: 帽子, 外套, 手套, 裤子, 雪靴, 背包. Warm ivory character lighting, snow blue rim lighting. His right boot region (screen left) is softly outlined ochre indicating selection, NOT a red injury: selected condition is wet boot.
Below preview a small understated two-way toggle 衣着 / 身体 with 衣着 selected, small drag hint 拖动旋转. Short summary 保暖尚可 · 双脚潮湿.
Right 42% is one broad slightly irregular pale notebook leaf, not a stack of cards. Clear large selected item heading 旧雪靴. Detail: 潮湿 42% · 完好 76%. Short cause-effect readable text: 积雪浸湿了内衬，保暖下降。. One comparison row 干燥后：保暖恢复. Main action styled like a dark ink stamped strip 靠炉烘干; secondary text 修补. Beside the primary action note 需要点燃的炉火, showing the actual contextual requirement rather than an unexplained disabled action. Lower part of leaf has heading 可替换衣物 with two small tactile item illustrations (one snow boot pair and wool sock roll), spare annotation 先收好脚上的旧靴. Do not label socks as seventh equipment slot; they are upgrade material.
A slim canvas pocket along bottom 18% holds four large separated physical item illustrations with readable small labels, no repetitive square boxes: wrapped ration 口粮 ×2, water flask 饮用水 ×1, cloth bundle 布料 ×3, old cassette tape 磁带 · 归途. Bottom subtle footer 背包 8.9 / 24 kg · 查看与比较时已暂停.
Keep the entire functional UI inside safe margins. One continuous full-screen composition, not a collage or multiple options, no device bezel, no watermark. All text Chinese as specified, do not invent paragraph text. Priority is excellent material restraint, hierarchy, coherent affordances and the established cold winter miniature identity.
```

## 剧情页：实际提示词

```text
Use case: ui-mockup. Create one polished 16:9 narrative interaction screen concept for the Chinese stylized miniature winter game 雪线以北. Reference image 1 is the ACTUAL current story screen: preserve its cold snowy forest mood and Chinese narrative purpose but entirely redesign its oversized rectangular modal. Reference image 2 is the newly proposed character kit UI: match its subdued navy canvas, warm cream paper, tactile wear, inked rules and restrained ochre accents, but use a DIFFERENT composition appropriate for reading a found document. This is a visual design proposal, not an actual screenshot.
Composition: keep a clearly readable miniature snow-covered cabin and branching trees in cold dusk visible across left 48% and outer margin, an inviting SMALL warm window; fixed elevated orthographic camera like the first reference, no realistic first-person view. Near lower left foreground a restrained ink illustration of an old tabletop radio and a folded envelope as a single contextual vignette with lots of empty breathing room, not a new gameplay pickup. At right 48% one worn cream notebook leaf clipped to a slim charcoal canvas folio, near vertical/front-facing enough to read comfortably, generous top and bottom padding. Paper material very subtle behind text, worn irregular edges restrained. No generic rounded cards, no modular dashboard, no ornate medieval parchment or overly dramatic horror.
Exact Chinese text on paper with readable beautiful restrained hierarchy:
small top kicker 七号护林小屋 · 值守簿
large heading 没能发出的平安报
body arranged into three short paragraphs:
周岑去了北坡。说好傍晚回频道，
直到现在，北岭四还没有应答。

收音指针还会动，发射灯却不亮。
备用模块留在北岭维修站。

先让谷口知道我还在这里，
再问他的消息。
A single thin hand-drawn separator and one simple task reminder handwritten-style 暖身，备水，再出发。
At bottom of leaf ONE primary dark ink strip button 收好记录 with subtle ochre key hint E. A smaller secondary text action 回看开场 and bottom footer 阅读时已暂停 · Esc 收起.
Outside paper at upper left tiny title 雪线以北 and below small 第一章 / 失联.
Must not add invented story quotations, dates, English titles, stats, inventories, plot claims, decoration text, extra buttons, figures, or additional UI. The important contrast is blue snowy world and quiet legible warm paper; paper takes less than half the screen and does not occlude the whole environment. This is a single finished screen, no collage, no external border.
```
