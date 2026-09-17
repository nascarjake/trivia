# Millionaire: game, asset, and technical research

Research date: 17 September 2026. This is a development shortlist, with verified listings distinguished from leads whose original downloads or permissions remain unverified. No paid assets were purchased and no fan assets were incorporated into the prototype.

## Direction

Build the familiar 15-question climb inside a 3D circular studio: opposing seated host and contestant, shared monitors, surrounding audience, blue/purple light, dramatic pauses, orange answer selection and green correct-answer reveal. Add changing topic packs, sourced questions, and fallible AI helpers. Keep the question text readable throughout camera movement.

The linked reference is the **2020 Microids game**, developed by Appeal Studios/Balio Studio. Its current Steam description advertises over 6,000 questions, more than 15 topics, a 15-question climb, topic selection, family modes, local competition, and online play for up to 50 players. Its credits explicitly identify production under license from Sony Pictures Television. [Steam product page](https://store.steampowered.com/app/1356240/Who_Wants_To_Be_A_Millionaire/)

The older games are useful references for different parts of the experience:

| Reference | What to study |
| --- | --- |
| [1999 game and subsequent early adaptations](https://en.wikipedia.org/wiki/Who_Wants_to_Be_a_Millionaire_(1999_video_game)) | Host pacing, suspense, sound transitions, concise question presentation |
| [Special Editions](https://www.mobygames.com/game/159514/who-wants-to-be-a-millionaire-special-editions/) | Themed question packs and social play; regional releases differ, so avoid treating one release date as universal |
| [2020 game](https://store.steampowered.com/app/1356240/Who_Wants_To_Be_A_Millionaire/) | The requested 3D studio/character reference and topic selection |
| [Microids launch details](https://www.microids.com/microids-shares-more-details-on-its-videogame-adaptation-of-the-famous-game-show-who-wants-to-be-a-millionaire/) | Original mode descriptions; distinguish launch content from later DLC |

For this prototype, use the classic US-style dollar ladder: $100, $200, $300, $500, $1,000, $2,000, $4,000, $8,000, $16,000, $32,000, $64,000, $125,000, $250,000, $500,000, $1,000,000. Safeguards at questions 5 and 10. This is a deliberate ruleset selection; international and later TV formats differ.

## Strongest fan project

**[ua2004/Millionaire-3D](https://github.com/ua2004/Millionaire-3D)** is the closest open-source lead. Its README reports a studio, host/player models, armchairs, dual monitors and classic answer-bar sprites. It is an older Unity project, with a GPL-2.0 repository license. The README includes unfinished plans; do not assume all advertised format variants or moving lights are complete.

I inspected its GitHub file tree, rather than relying on screenshots. Relevant files include:

| File | Source file size, approximately |
| --- | ---: |
| `Assets/3D/Studio/studio_fbx.fbx` | 73.8 MB |
| `Assets/3D/Studio/studio_empty_fbx.fbx` | 51.2 MB |
| `Assets/3D/Studio/studio_big.dae` | 21.1 MB |
| `Assets/3D/Studio/armchair_fbx.fbx` | 8.8 MB |
| `Assets/3D/Studio/double_monitor_fbx.fbx` | 5.0 MB |
| `Assets/3D/Characters/SuitedMan/Models/suit_F01.fbx` | 0.62 MB |
| `Assets/3D/Characters/Cowboy/Model/Cowboy 1.1.FBX` | 0.40 MB |
| `Assets/Animations/Player/m01@sit_00.fbx`, `m01@sit_01.fbx` | 3.3 / 6.6 MB |

The exact source commit, paths, blob identifiers, and sizes are preserved in [fan-model-inventory.json](fan-model-inventory.json). File size is not a polygon count or a runtime memory measurement. The repository also bundles third-party components/character content; the top-level GPL label alone does not establish the provenance of every asset. Best next step: review asset authorship, then convert permitted geometry through Blender to GLB and rebuild materials, scene hierarchy, lights and animations in Godot. Unity scenes and C# gameplay do not automatically become Godot scenes.

## Other studio and visual assets

| Lead | Verified finding | Suitability / unresolved work |
| --- | --- | --- |
| [TurboSquid UK 2 studio, FCG Studio](https://www.turbosquid.com/3d-models/who-wants-to-be-a-millionaire-tv-studio-set-uk-2-3d-model-2211622) | Listed at $179; FBX/OBJ/C4D/MAX; editorial use only | Good classic blue-set reference. Metadata says 60,000 polygons while description says 600,000: confirm with seller. Neither count nor license should be guessed. |
| [TurboSquid UK studio](https://www.turbosquid.com/FullPreview/Index.cfm/ID/2193728) | Dedicated UK set listing found | Additional variant; inspect exact license, geometry and included files before purchase. |
| [TurboSquid US studio](https://www.turbosquid.com/FullPreview/1920878) | Dedicated US set listing found | Useful comparison with the Steam presentation. Download not inspected. |
| [TurboSquid international studio](https://www.turbosquid.com/FullPreview/1921036) | International set listing found | Alternative architecture; download not inspected. |
| [CGTrader modern US set, FCGStudio](https://www.cgtrader.com/3d-models/architectural/decoration/millionaire-tv-studio-us-modern-set) | 600,000 polygons; C4D/MAX and FBX/OBJ; listing says FBX/OBJ omit materials/textures; royalty-free label | Render-oriented. Requires optimization and material work. Marketplace label does not itself resolve depicted show branding. |
| [CGTrader studio, fominykh](https://www.cgtrader.com/3d-models/interior/other/millionaire-tv-studio-set-3d) | C4D, FBX, OBJ; FBX group listed at 47.3 MB; textures at 751 MB; royalty-free label | Potential source geometry, but unmodified texture payload is unsuitable for a small web build. |
| [Worthy Edge: US 2020 logo, Sketchfab](https://sketchfab.com/3d-models/who-wants-to-be-a-millionaire-us-2020-logo-eec78fb977d6493fa796a5402fd96787) | Free downloadable listing; CC Attribution; 373,600 triangles | Far too detailed for a background logo without reduction/baking. Attribution does not establish permission for the underlying brand. |
| [Roblox Season 21 model](https://create.roblox.com/store/asset/9001861477/Who-Wants-To-Be-A-Millionaire-Season-21) | Creator Store model listing exists | Treat as reference until provenance and permitted use outside Roblox are established. |

Some marketplace entries may be variants or cross-posts from the same creator. A large search-result count does not necessarily mean many independent usable sets. Prices and availability can change.

### SketchUp fan sets: useful leads, not verified downloads

[3D Model Database indexes 20 WWTBAM-related listings](https://3dmdb.com/en/3d-models/wwtbam/), chiefly pointing to 3D Warehouse. It lists modern US/UK sets, Romanian/Bulgarian, French, Polish and Vietnamese variants, seating, monitor podiums, and other set pieces. Original download pages were not successfully verified in this session.

Concrete leads to revisit:

- [Modern 2020 set](https://3dmdb.com/en/3d-model/who-wants-to-be-a-millionaire-2020/9503919/)
- [UK set](https://3dmdb.com/en/3d-model/who-wants-to-be-a-millionaire-uk/9502455/)
- [Romanian studio with Bulgarian logo](https://3dmdb.com/en/3d-model/wwtbam-romanian-studio-2000-2003-with-bulgarian-logo/11049956/)
- [Vietnam studio](https://3dmdb.com/en/3d-model/who-wants-to-be-a-millionaire-studio-3d-vietnam-ai-la-trieu-phu/6481261/)
- [Polish Milionerzy set](https://3dmdb.com/en/3d-model/milionerzy-2020-re-boarding/9497356/)
- [French set](https://3dmdb.com/en/3d-model/plateau-qui-veut-gagner-des-millions-depuis-2014/6666578/)

These are discovery links, not proof of file availability or reuse rights. If obtained, SketchUp geometry would need unit/axis checks, normal cleanup, texture consolidation, collision removal, and conversion to GLB.

## Fan software, graphics, and audio

- [TheMillionaireGame](https://github.com/Macronair/TheMillionaireGame): host-controlled simulator with separate host/contestant/audience screens, question editing and customizable lifelines. Useful for show-control logic and presentation references. Its README explicitly distinguishes self-created visuals from its music/sounds. It is not a ready-made Godot game.
- [Millionaire With Friends](https://github.com/michael-rutledge/millionaire): multiplayer web implementation with Fastest Finger and continuing audience participation. Useful for future party-mode design. Its README says licensed fonts are not included.
- [TamasPetii’s SDL version](https://github.com/TamasPetii/Who-wants-to-be-a-millionaire): classic lifeline and UI reference, with thousands of translated questions. The author warns about translation quality. Do not import its question bank as verified current trivia.
- [jQuizShow](https://quizshow.sourceforge.net/): older customizable questions, prize ladder, and sound effects. Useful as a historical implementation reference.
- [Music-score reference](https://millionaire.fandom.com/wiki/Music_scores): helpful taxonomy for studying the dramatic structure. Availability of recordings on a fan wiki or YouTube is not an asset license. Commission or generate original tension beds, lock-in cues, reveals, and audience sounds for the production game.
- [Mixamo and its official FAQ](https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html): practical source for humanoid characters/animations, including game use. An Adobe ID is required. Review relevant terms and avoid redistribution as a standalone asset pack. Evaluate seated idle, thinking, pointing, disappointment and celebration animation coverage in the catalog.
- [Kenney asset catalog](https://kenney.nl/assets/): browse animated-character and audio packs for simpler substitutes; check each selected pack’s license and rig before adopting it.

**Asset decision:** the included prototype uses original procedural meshes and synthesized tones. Fan downloads remain a shortlist for a later art pass. An exact branded release needs a rights decision; the official Steam game credits Sony licensing, and the verified TurboSquid UK listing explicitly restricts use to editorial contexts. No asset purchase or distribution clearance is implied by this research.

## AI questions and trend feeds

Recommended pipeline: **trend signals → factual source research → structured question pack → review → cached playable pack**. A trending title identifies a subject; it is not evidence that a proposed answer is true.

**YouTube:** `videos.list` with `chart=mostPopular`, `regionCode`, and optionally `videoCategoryId` supplies chart metadata. The method is documented at one quota unit. Since 21 July 2025, the chart draws from trending music, movies and gaming, rather than the old general Trending Now list. Broader coverage needs curated channels, category searches, or another source. Avoid assuming transcripts are freely available through the Data API. [Endpoint](https://developers.google.com/youtube/v3/docs/videos/list), [official revision history](https://developers.google.com/youtube/v3/revision_history)

**X/Twitter:** `/2/trends/by/woeid/:id` returns location-based topic names. The official guide requires an approved developer account, project/app and bearer token. US WOEID is `23424977`; worldwide is `1`. API availability and usage cost should be checked in the account before deployment. [Official X guide](https://docs.x.com/x-api/trends/trends-by-woeid/introduction)

**Question generation:** the implemented local service uses OpenAI Responses with web-search citations, then a strict JSON schema and a separate model review. It checks four distinct options, a valid answer index, difficulty order, duplicate questions and citation membership. This reduces failure modes; it does not mathematically prove factual accuracy. Production needs a report-question flow, reviewed fallback packs, and measured question difficulty. [Structured outputs](https://developers.openai.com/api/docs/guides/structured-outputs), [web search](https://developers.openai.com/api/docs/guides/tools-web-search)

**Lifelines:** 50:50 remains deterministic and always removes two wrong answers. Phone a Friend generates a short uncertain explanation without the answer key. Ask the Audience generates a labeled simulated distribution, totaling 100%, respecting eliminated choices. AI hints can be wrong. The local practice substitutes are explicitly labeled simulations rather than live AI or real viewers.

Initial categories: Internet & creators; Gaming; Music; Film & TV; Science & space; Technology; Sports; Culture & food; mixed play. Suggested later packs include creator launches, esports, movie trailers, new albums, space missions, food trends and retro internet. Sensitive rumors and moving follower/view counts are poor quiz material; prefer dated, attributable facts associated with the topic.

## Godot and web implementation

Use Godot 4 with GDScript and the Compatibility renderer. The web platform requires WebAssembly/WebGL 2; Godot 4 C# web export is not supported by the referenced guide. Single-thread export avoids cross-origin isolation requirements. The project uses matching 4.7.2 web templates. [Godot web export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)

The engine splash image is disabled by `application/boot_splash/show_image=false`; minimum display time is zero. A custom HTML shell omits the Godot logo entirely and shows only a small loading/progress message while engine bytes arrive. Removing a logo does not eliminate network/loading time. [Project settings](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html#class-projectsettings-property-application-boot-splash-show-image), [custom HTML shell](https://docs.godotengine.org/en/stable/tutorials/platform/web/customizing_html5_shell.html)

Proposed art targets, to be validated on real devices: 100–200k visible triangles, under 200 draw calls, baked lighting, 1k/2k atlases, instanced audience, and under 25 MB compressed total transfer where practical. These are project targets, not Godot guarantees. The procedural prototype is a layout/gameplay foundation and is not yet an optimized or photorealistic art pass.

## Remaining production work

1. Choose an asset/branding route, establish provenance, then replace placeholder characters and stage meshes.
2. Add rigged performance, lip sync, camera cuts, original music and more precise classic answer-bar graphics.
3. Configure and live-test AI and feed credentials; pre-generate/refresh packs so players do not wait on multiple model calls.
4. Add topic discovery tiles with actual provider timestamps, question reporting, persistence and stronger editorial review.
5. Move scoring and answer keys server-side before competitive or multiplayer play. The prototype is a single-player client-authoritative game.
6. Add deployment authentication, per-user quotas, spend limits, a production server and compressed static hosting. The included server intentionally binds only to localhost.
7. Test mobile/touch layouts, accessibility, low-power GPUs and Safari. Desktop landscape is the current layout target.
