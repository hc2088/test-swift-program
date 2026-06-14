# 拆了胡彦斌「彦火」APK：它确实是 Flutter App，为什么体积还能这么小？

最近胡彦斌的粉丝社区 App「彦火」挺有话题度。作为开发者，我更好奇另一件事：这个 App 到底是原生写的，还是跨端框架做的？

我拿到了一份 Android APK，做了一次非常轻量的静态包结构分析。先说结论：

> 从 Android APK 的文件结构看，「彦火」Android 端可以确认是 Flutter App。

这篇文章不反编译业务代码，也不分析接口和业务逻辑，只看 APK 里的公开文件结构，聊聊两个问题：

1. 怎么判断它是 Flutter？
2. 为什么 Flutter App 的体积看起来还能这么小？

## 一、判断 Flutter App，看哪些证据？

APK 本质上是一个 zip 包，所以直接列文件就能看到很多信息：

```bash
unzip -l yanhuo-android.apk
```

在「彦火」APK 里，可以看到非常典型的 Flutter 结构：

```text
lib/arm64-v8a/libapp.so
lib/arm64-v8a/libflutter.so
lib/armeabi-v7a/libapp.so
lib/armeabi-v7a/libflutter.so
lib/x86_64/libapp.so
lib/x86_64/libflutter.so
assets/flutter_assets/AssetManifest.bin
assets/flutter_assets/FontManifest.json
assets/flutter_assets/NativeAssetsManifest.json
assets/flutter_assets/shaders/ink_sparkle.frag
assets/flutter_assets/packages/cupertino_icons/assets/CupertinoIcons.ttf
```

这里面最关键的是两个东西。

## 二、证据 1：`libflutter.so`

`libflutter.so` 是 Flutter engine 在 Android 端的 native 动态库。

如果一个 APK 里出现：

```text
lib/arm64-v8a/libflutter.so
```

基本就已经能说明它使用了 Flutter。因为原生 Android、React Native、普通 Kotlin/Java App 都不会天然带这个库。

这份 APK 里不止一份 `libflutter.so`，而是包含了多个 ABI：

```text
lib/arm64-v8a/libflutter.so
lib/armeabi-v7a/libflutter.so
lib/x86_64/libflutter.so
```

这说明这份 APK 是一个包含多架构 native 库的包。

## 三、证据 2：`libapp.so`

Flutter 在 release 模式下，Dart 代码通常会 AOT 编译成 native 产物。在 Android 端，一个典型产物就是：

```text
libapp.so
```

这份 APK 里也有：

```text
lib/arm64-v8a/libapp.so
lib/armeabi-v7a/libapp.so
lib/x86_64/libapp.so
```

这也符合 Flutter release 包的结构。

简单理解：

```text
libflutter.so  -> Flutter engine
libapp.so      -> Dart 业务代码 AOT 后的产物
flutter_assets -> Flutter 资源目录
```

这三者一起出现，Flutter 身份基本就坐实了。

## 四、证据 3：`assets/flutter_assets`

Flutter App 的资源会放到：

```text
assets/flutter_assets/
```

「彦火」APK 里也能看到：

```text
assets/flutter_assets/AssetManifest.bin
assets/flutter_assets/FontManifest.json
assets/flutter_assets/assets/images/brand_title.png
assets/flutter_assets/assets/images/hero_huyanbin.png
assets/flutter_assets/assets/images/little_tiger.png
assets/flutter_assets/packages/cupertino_icons/assets/CupertinoIcons.ttf
assets/flutter_assets/packages/flutter_map/lib/assets/flutter_map_logo.png
```

其中 `FontManifest.json`、`AssetManifest.bin`、`packages/cupertino_icons` 都是 Flutter 项目里很常见的资源结构。

所以从 APK 结构上看，「彦火」Android 端不是“像 Flutter”，而是非常明确地带着 Flutter 的运行时和资源结构。

## 五、那为什么体积看起来还挺小？

我手里的这份 Android APK 大约是 61MB。这里需要先把口径说清楚：这个数字只对应我手里的 Android APK。

如果你在 iPhone 12、iOS 26 的 App Store 页面上看到「彦火」显示 29.2MB，那是 iOS 端的 App Store 展示体积。它和这份 Android APK 属于不同操作系统、不同平台、不同安装包格式，不能直接横向比较。

所以这篇文章后面讨论的 61MB，只针对这份 Android APK 本身。

先看这份 APK 里的主要文件大小。注意，`unzip -l` 看到的是 APK 内条目的原始大小，不完全等于应用商店展示的压缩下载大小：

```text
arm64-v8a/libapp.so       约 8.2 MB
arm64-v8a/libflutter.so   约 11.3 MB

armeabi-v7a/libapp.so     约 9.1 MB
armeabi-v7a/libflutter.so 约 8.3 MB

x86_64/libapp.so          约 8.5 MB
x86_64/libflutter.so      约 12.6 MB
```

也就是说，光 Flutter engine 和 Dart AOT 产物，多 ABI 加起来就占了不少体积。

但用户实际下载时，不一定总是拿到“所有 ABI 都打在一起”的包。

## 六、先有个参照：官方最小 Flutter App 多大？

如果只是一个 Hello World 级别的 Flutter 页面，Flutter 官方 FAQ 里有一个很适合做背景的测量。

官方在 2021 年 3 月测过一个最小 Flutter App：不包含 Material Components，页面里只有一个 `Center` widget，用 `flutter build apk --split-per-abi` 构建 release 包。压缩后的下载大小大约是：

```text
ARM32  约 4.3 MB
ARM64  约 4.8 MB
```

再拆开看，官方给出的体积构成大概是：

```text
ARM32:
core engine              约 3.4 MB
framework + app code     约 765 KB
classes.dex              约 120 KB
LICENSE                  约 58 KB

ARM64:
core engine              约 4.0 MB
framework + app code     约 659 KB
classes.dex              约 120 KB
LICENSE                  约 58 KB
```

这说明两件事：

1. Flutter engine 确实会随 App 一起打进安装包里。
2. 每个 Flutter App 都是自包含的，不是依赖手机系统里预装一个公共 Flutter runtime。

所以讨论 Flutter 包体积时，要先承认它有一个固定基础成本。一个极简 Flutter App，在 Android 单 ABI release 下载口径下，也会有几 MB 的起步体积。

但这个基础成本不等于当前 APK 的全部体积。比如「彦火」这份 APK 里同时带了多套 ABI：

```text
arm64-v8a/
armeabi-v7a/
x86_64/
```

每套 ABI 下又各自有 `libflutter.so` 和 `libapp.so`。所以 61MB 的 universal APK，不能直接理解成“Flutter 框架本身占了 61MB”。这里面混合了 Flutter engine、Dart AOT 业务产物、插件 native 依赖、资源文件，以及多架构重复打包。

Flutter 官方的 App Size 文档也提醒：debug 包不代表生产包，上传到商店的包也不一定等于用户真实下载的包。商店可能会根据设备 CPU 架构、屏幕密度等条件过滤 native libraries 和资源。

参考资料：

- [Flutter FAQ：How big is the Flutter engine?](https://docs.flutter.dev/resources/faq#how-big-is-the-flutter-engine)
- [Flutter 文档：Measuring your app's size](https://docs.flutter.dev/perf/app-size)

## 七、原因 1：应用商店可能做了架构切片

Android App 如果通过 AAB 或分包方式发布，商店可以按设备下发对应 ABI 的包。

比如一台常见手机只需要：

```text
arm64-v8a/libapp.so
arm64-v8a/libflutter.so
```

它不需要同时下载：

```text
armeabi-v7a/
x86_64/
```

所以一个本地 Android universal APK 看起来是 61MB，但如果通过 Android App Bundle 或 ABI split 分发，真实下发到 Android 手机上的包可能会更小。

至于 iOS App Store 页面上看到的 29.2MB，只能说明 iOS 端在 App Store 当前设备口径下展示的大小。它可以作为另一个平台的背景信息，但不能拿来证明这份 Android APK 分发后一定会变成类似大小。

## 八、原因 2：资源本身并不重

Flutter App 体积大，很多时候不是因为 Flutter 本身，而是因为资源。

比如：

- 大图
- 视频
- 音频
- 多套分辨率素材
- 大量字体
- 内置模型

这份 APK 里 Flutter assets 并不算夸张，比较大的图片主要是：

```text
hero_huyanbin.png   约 2.5 MB
little_tiger.png    约 0.66 MB
brand_title.png     约 0.4 MB
```

也就是说，它不像一些内容型 App 那样把大量图片、音频、视频预置进包里。资源轻，包自然就不会特别离谱。

## 九、原因 3：Flutter 的固定成本不等于无限膨胀

Flutter App 会带 engine，这是固定成本。很多人一听 Flutter，就觉得包一定很大。

但实际要分场景：

```text
Flutter engine 固定成本
+ Dart AOT 业务代码
+ 图片/字体/资源
+ 原生依赖
+ 多 ABI native 库
```

如果业务代码不复杂，资源控制得好，再配合商店切片，Flutter App 的下载体积完全可以做到一个比较温和的范围。

「彦火」这个包就是一个例子：它确实是 Flutter，但它的资源负担并不重。

## 十、从字体看资源优化：Material Icons 已经被裁剪

Flutter 包里经常能看到两个图标字体：

```text
assets/flutter_assets/fonts/MaterialIcons-Regular.otf
assets/flutter_assets/packages/cupertino_icons/assets/CupertinoIcons.ttf
```

这份 APK 里，它们的大小差异很明显：

```text
MaterialIcons-Regular.otf  约 19KB
CupertinoIcons.ttf         约 252KB
```

为什么 `MaterialIcons-Regular.otf` 这么小？我解析了一下它的 cmap：

```text
glyphs: 133
codepoints: 132
```

这说明它不是完整 Material Icons 字体，而是 Flutter release 构建后做过 icon tree shaking，只保留了 App 实际用到的图标。

里面的 codepoint 也基本都在 Unicode 私用区，例如：

```text
U+E092  arrow_back_baseline
U+E098  arrow_drop_down_baseline
U+E122  calendar_today_baseline
U+E139  cancel_baseline
U+E15E  chevron_left_baseline
U+E15F  chevron_right_baseline
U+E16A  close_baseline
U+E21A  edit_baseline
U+E3DC  menu_baseline
U+F17A  local_fire_department_outlined
U+F737  favorite_border_rounded
U+F738  favorite_rounded
U+F7F5  home_rounded
```

也就是说，这不是“只保留常用汉字/英文字母”，而是只保留用到的图标 glyph。

相比之下，`CupertinoIcons.ttf` 还有：

```text
glyphs: 1257
codepoints: 1280
```

它更像是带了较完整的 `cupertino_icons` 图标字体。这里如果 App 实际没怎么用 Cupertino 图标，就还有优化空间。

Flutter 字体优化的思路可以总结成：

```text
1. 开启 release 构建的 icon tree shaking
2. IconData 尽量写成 const
3. 不要动态拼 icon codepoint
4. 不用 cupertino_icons 就移除依赖
5. 自定义字体用 pyftsubset 裁剪
6. 中文字体尽量用系统字体，不要整包塞进 APK
```

常用构建命令是：

```bash
flutter build apk --release --tree-shake-icons
```

如果代码里有动态 IconData，比如从服务端下发 codepoint，再运行时构造图标，Flutter 就很难判断哪些图标真正用到了，字体裁剪效果会变差。

## 十一、从 shader 看渲染资源：不是包体优化重点

这份 APK 里还有两个 shader 文件：

```text
assets/flutter_assets/shaders/stretch_effect.frag  约 17KB
assets/flutter_assets/shaders/ink_sparkle.frag     约 21KB
```

从文件内容看，能看到：

```text
stretch_effect_fragment_main
ink_sparkle_fragment_main
GLSL.std.450
#version 300 es
```

`ink_sparkle.frag` 大概率是 Flutter Material 的 InkSparkle 点击水波纹/闪光效果。按钮、`InkWell`、`ListTile` 这类 Material 组件按下时，可能会用到这类效果。

`stretch_effect.frag` 更像是滚动越界时的 stretch overscroll 拉伸效果。

这类 shader 通常来自 Flutter framework/engine，不是业务自己手写的。它们的体积也很小，几十 KB 级别，不是这份 APK 的主要体积来源。

最佳实践不是“删 shader”，而是：

```text
1. 不要手动删除 flutter_assets/shaders
2. 如果首帧或首次点击有卡顿，关注 shader 预热、Impeller、SkSL warmup
3. 自定义 shader 要控制数量和复杂度
4. 包体优化优先看图片、字体、ABI、native so
5. shader 这种几十 KB 的文件，通常不是优先优化目标
```

如果真的不想要 Material 3 的 InkSparkle 效果，可以从主题层面调整 `splashFactory`，但这属于交互风格选择，是否减少最终打包资源要以构建产物为准。

## 十二、从 `.9.png` 看图片资源：数量多，但总量很小

Android `res/` 目录里有很多 `.9.png`：

```text
res/qD.9.png
res/MF.9.png
res/zV.9.png
...
```

`.9.png` 是 Android Nine-Patch 图片，常用来做可拉伸背景，比如按钮、气泡、输入框、弹窗背景。它比普通 PNG 多了边缘 1px 的拉伸和内容区域标记。

这份 APK 中 `.9.png` 的数据是：

```text
数量：98 个
总大小：约 47.4KB
平均：约 0.5KB
最大：约 2.8KB
```

所以虽然数量看起来很多，但总量只有几十 KB。对这份 APK 来说，`.9.png` 不是包体大头。

图片资源优化可以这样做：

```text
1. 纯色、圆角、描边背景优先用 shape.xml
2. 简单图标优先用 VectorDrawable
3. 大图优先压缩成 WebP/AVIF
4. 删除不用的资源，开启 resource shrink
5. 控制多 dpi 资源，不要重复塞多套相近图片
6. PNG 可用 pngquant、zopflipng 做无损/有损压缩
7. .9.png 不要盲目转 WebP，避免丢失 nine-patch 拉伸信息
```

这份 APK 的图片优化重点其实不在 `.9.png`，而在 Flutter assets 里的大图，例如：

```text
hero_huyanbin.png   约 2.5MB
little_tiger.png    约 0.66MB
brand_title.png     约 0.4MB
```

如果继续压缩包体，优先看这些 Flutter 业务图片，而不是 Android res 里的 nine-patch。

## 十三、顺手看到的一些技术信号

APK 里还能看到一些 Android 侧依赖痕迹，比如：

```text
androidx.*
kotlinx_coroutines_android
play-services-location
okhttp3
```

这些说明它并不是“纯 Dart 世界”，而是和 Android 原生生态也有集成。Flutter App 很常见：UI 和大部分业务用 Flutter，部分能力通过插件或原生依赖接入。

这也能解释为什么 APK 里既有：

```text
assets/flutter_assets/
libflutter.so
libapp.so
```

也有：

```text
classes.dex
AndroidManifest.xml
res/
androidx/kotlin/google play services 相关依赖
```

Flutter App 仍然是一个 Android App，只是 UI 渲染和 Dart 业务运行在 Flutter 体系里。

## 十四、结论

基于这份 APK 的静态结构，可以得到几个结论：

1. 「彦火」Android 端可以确认是 Flutter App。
2. 关键证据是 `libflutter.so`、`libapp.so` 和 `assets/flutter_assets/`。
3. 61MB 只对应这份 Android universal APK；iOS App Store 页面看到的 29.2MB 是另一个平台的展示体积，不能直接和 Android APK 横向比较。
4. Flutter engine 会随 App 一起打包，官方最小 Android 单 ABI release 下载包也有几 MB 的固定基础成本。
5. 这份 APK 看起来体积不算夸张，主要原因是资源不重，而且实际下发时可能不会包含所有 ABI。
6. Material Icons 字体已经明显做过 tree shaking，只有 132 个 codepoint。
7. CupertinoIcons 字体相对完整，如果使用不多，可能还有优化空间。
8. Shader 和 `.9.png` 都不是这份 APK 的体积大头，优化优先级低于 ABI、native so、Flutter 大图和字体依赖。
9. Android APK 只能证明 Android 端技术栈；如果要确认 iOS 端，也需要分析 iOS 包或官方技术信息。

如果用一句话总结：

> 「彦火」不是因为 Flutter 才一定大，也不是因为体积小就不像 Flutter。看 APK 结构，Android 端 Flutter 特征非常明确；体积控制得住，更多是资源规模、ABI 切片和商店分发策略共同作用的结果。
