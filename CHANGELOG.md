
### 🎉 New Features
* [905936a4](https://github.com/aayush2622/Dartotsu/commit/905936a4): feat: long press a manga page to save, share or copy it, with a reader setting to turn it off
* [08c68690](https://github.com/aayush2622/Dartotsu/commit/08c68690): feat: submit skip times to AniSkip from the player
* [30b71504](https://github.com/aayush2622/Dartotsu/commit/30b71504): feat: remember the save progress choice for a single series
* [bf439535](https://github.com/aayush2622/Dartotsu/commit/bf439535): feat: compact playback speed sheet and remember the last used speed
* [2b636653](https://github.com/aayush2622/Dartotsu/commit/2b636653): feat: discord presence shows real playback position and a paused state in the player
* [343cfd5e](https://github.com/aayush2622/Dartotsu/commit/343cfd5e): feat: progress bar thumb with press feedback
* [1cd697f2](https://github.com/aayush2622/Dartotsu/commit/1cd697f2): feat: build seek previews from the buffered video and drop the live screenshots
* [ffa12b56](https://github.com/aayush2622/Dartotsu/commit/ffa12b56): feat(reader): port Rust image processing (vips-rs & SIMD) & add selectable image filter quality (#159)
* [77abd9c0](https://github.com/aayush2622/Dartotsu/commit/77abd9c0): feat: send desktop analytics to GA4 so Linux and Windows users show up
* [000d6a14](https://github.com/aayush2622/Dartotsu/commit/000d6a14): feat: optional app passcode lock with a one-minute grace period
* [a14d32f4](https://github.com/aayush2622/Dartotsu/commit/a14d32f4): feat: include extension bridge settings in backups
* [e385a423](https://github.com/aayush2622/Dartotsu/commit/e385a423): feat: open player fullscreen and pause when the app loses focus, fold player settings sections
* [768e05d8](https://github.com/aayush2622/Dartotsu/commit/768e05d8): feat: player tracks sheet tabs for subtitle settings
* [fda461e6](https://github.com/aayush2622/Dartotsu/commit/fda461e6): feat: add strings for app lock, player options and updater messages, translate them

### 🛠️ Bug Fixes & Improvements
* [d79521a3](https://github.com/aayush2622/Dartotsu/commit/d79521a3): fix: simkl trending movies row goes last
* [f2c0c3b8](https://github.com/aayush2622/Dartotsu/commit/f2c0c3b8): fix: detect blank android frame captures by size so the shader preview gets a real frame
* [9283ada0](https://github.com/aayush2622/Dartotsu/commit/9283ada0): fix: start the app when libmpv can't load on old android and disable only the player
* [67cb6e8a](https://github.com/aayush2622/Dartotsu/commit/67cb6e8a): fix: remove invisible characters from fastlane paths
* [3c49eacd](https://github.com/aayush2622/Dartotsu/commit/3c49eacd): fix: simkl country and mini-series rows built from trending files
* [cda0bc90](https://github.com/aayush2622/Dartotsu/commit/cda0bc90): fix: detail title fits 3-4 lines within the cover height
* [6882f8c8](https://github.com/aayush2622/Dartotsu/commit/6882f8c8): fix: match display refresh rate to the video and idle the hidden player controls
* [0bfccdda](https://github.com/aayush2622/Dartotsu/commit/0bfccdda): fix: seek pill no longer flashes +0s while fading out
* [dbef9b35](https://github.com/aayush2622/Dartotsu/commit/dbef9b35): fix: bottom sheets focus the drag handle first for keyboard navigation
* [d536a504](https://github.com/aayush2622/Dartotsu/commit/d536a504): fix: save progress choice can only be remembered per series
* [04c5ae06](https://github.com/aayush2622/Dartotsu/commit/04c5ae06): fix: shader and seek previews use the same android video output setup as the player
* [0b246244](https://github.com/aayush2622/Dartotsu/commit/0b246244): fix: dns resolver never throws so the app no longer aborts without internet
* [729cab20](https://github.com/aayush2622/Dartotsu/commit/729cab20): fix: remove button backgrounds from the manga reader controls
* [74e70d8c](https://github.com/aayush2622/Dartotsu/commit/74e70d8c): fix: crop border listener removed twice from a disposed image stream
* [9e171057](https://github.com/aayush2622/Dartotsu/commit/9e171057): fix: resume opens the saved episode and shows the main series name
* [b183d4ca](https://github.com/aayush2622/Dartotsu/commit/b183d4ca): fix: skip stream recovery when playback is still alive after an error log
* [65edba27](https://github.com/aayush2622/Dartotsu/commit/65edba27): fix: reload the detail page from the api after editing the list instead of using the cache
* [1bd242c9](https://github.com/aayush2622/Dartotsu/commit/1bd242c9): fix: clear the list entry on the series after it is removed from MAL, Kitsu, Simkl, MangaBaka and local lists
* [0cfeeee5](https://github.com/aayush2622/Dartotsu/commit/0cfeeee5): fix: novel reader rendered at zero size, drop icon backgrounds in its bars
* [25abba51](https://github.com/aayush2622/Dartotsu/commit/25abba51): fix: delay and shrink cover colour extraction so opening a series does not lag
* [5b6cb2d0](https://github.com/aayush2622/Dartotsu/commit/5b6cb2d0): fix: reopen the stream at the last position when playback errors after a long pause
* [afc91cd4](https://github.com/aayush2622/Dartotsu/commit/afc91cd4): fix: send a plain Accept header when gradle downloads the libmpv jars [build.all] [ping]
* [41d3cbb2](https://github.com/aayush2622/Dartotsu/commit/41d3cbb2): fix: record native crashes and previous exit reasons, flush logcat promptly and drop its noise
* [ffbd3246](https://github.com/aayush2622/Dartotsu/commit/ffbd3246): fix: finish mobile OAuth logins from the deep link when the browser session is dropped
* [fdc9d5b0](https://github.com/aayush2622/Dartotsu/commit/fdc9d5b0): fix: let long reply code blocks scroll without trapping the page
* [8ba869a4](https://github.com/aayush2622/Dartotsu/commit/8ba869a4): fix: report APK install failures and cancellation instead of crashing
* [c0c6dcc1](https://github.com/aayush2622/Dartotsu/commit/c0c6dcc1): fix: smoother scrolling and no replayed entrance animation in the continue watching shelf
* [a867544f](https://github.com/aayush2622/Dartotsu/commit/a867544f): fix: lift bottom sheets above the keyboard
* [370617db](https://github.com/aayush2622/Dartotsu/commit/370617db): fix: only show libass subtitles for ass tracks, swap gesture indicators and ignore top-edge swipes

### 🧹 Chores & Documentation
* [f5246197](https://github.com/aayush2622/Dartotsu/commit/f5246197): chore: bump version to 1.1.1
* [694fdd06](https://github.com/aayush2622/Dartotsu/commit/694fdd06): chore: pub upgrade [build.all] [ping]
* [623cdbb1](https://github.com/aayush2622/Dartotsu/commit/623cdbb1): chore: consistency pass with shared spinner, chips and sheet padding, and remove dead code
* [f71aed92](https://github.com/aayush2622/Dartotsu/commit/f71aed92): chore: bump nix channels.json
* [4bc556d5](https://github.com/aayush2622/Dartotsu/commit/4bc556d5): chore: trigger build [build.all] [ping]
* [a26a737a](https://github.com/aayush2622/Dartotsu/commit/a26a737a): chore: pub upgrade [build.all] [ping]
* [9aefc177](https://github.com/aayush2622/Dartotsu/commit/9aefc177): chore: pub upgrade [build.all] [ping]
* [7b4bc5ab](https://github.com/aayush2622/Dartotsu/commit/7b4bc5ab): chore: trigger build [build.all] [ping]
* [0d1695df](https://github.com/aayush2622/Dartotsu/commit/0d1695df): chore: trigger build [build.all] [ping]
* [0c847124](https://github.com/aayush2622/Dartotsu/commit/0c847124): chore: regenerate localizations for the reader filter strings
* [78f5560d](https://github.com/aayush2622/Dartotsu/commit/78f5560d): chore: bump nix channels.json
* [e102bd5d](https://github.com/aayush2622/Dartotsu/commit/e102bd5d): chore: trigger build [build.all] [ping]
* [8940c952](https://github.com/aayush2622/Dartotsu/commit/8940c952): chore: use precompiled cargokit binaries [build.all]
* [7d81ab6f](https://github.com/aayush2622/Dartotsu/commit/7d81ab6f): chore: bump nix channels.json
* [d91a8cdc](https://github.com/aayush2622/Dartotsu/commit/d91a8cdc): chore: bump nix channels.json

