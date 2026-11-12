import 'dart:io';

/// Generates a review artifact, never an automatic visual approval.
void writeComparison(Directory output) {
  const pages = ['home', 'me', 'editor', 'voices', 'connecting', 'call'];
  final cells = <String>[];
  for (var i = 0; i < pages.length; i++) {
    cells.add(
      '''<article><h2>${pages[i]}</h2><div class="variants">
      <figure><figcaption>design.html</figcaption><img src="design-${i + 1}.png" alt="Design reference ${pages[i]}"></figure>
      <figure><figcaption>Android · Skia Lite · 离线夹具</figcaption><img src="../../test/ui/goldens/android_${pages[i]}.png" alt="Android ${pages[i]}"></figure>
      <figure><figcaption>iOS · Skia Lite · 离线夹具</figcaption><img src="../../test/ui/goldens/iOS_${pages[i]}.png" alt="iOS ${pages[i]}"></figure>
      </div><details><summary>叠加对照（拖动调整实现图透明度）</summary>
      <input aria-label="实现图透明度" type="range" min="0" max="100" value="50" oninput="this.nextElementSibling.lastElementChild.style.opacity=this.value/100">
      <div class="overlay"><img src="design-${i + 1}.png" alt="设计参考"><img src="../../test/ui/goldens/iOS_${pages[i]}.png" alt="iOS Skia Lite 实现"></div></details></article>''',
    );
  }
  File('${output.path}/design-comparison.html').writeAsStringSync(
    '''<!doctype html><html lang="zh"><meta charset="utf-8"><title>小遇设计对照 · 待审查</title>
<style>body{background:#08090d;color:#f5f5f7;font:16px system-ui;margin:24px}article{margin:32px 0}.variants{display:flex;gap:16px;flex-wrap:wrap}figure{margin:0}img{width: min(100%,402px);border:1px solid #444}figcaption{padding:8px;color:#c2b7ff}.overlay{position:relative;width:402px;height:874px}.overlay img{position:absolute;inset:0;width:402px;height:874px}.overlay img:last-child{opacity:.5}summary{padding:16px 0}</style>
<h1>小遇六屏设计对照 · 待审查</h1><p>黄金图只检测回退。设计稿远程示例头像不可用时会留空；不将其导入产品。此文件不构成用户确认。</p>
<p>保留 PRD 的 30 字角色名、50000 字人设；未实现的知识库和试听明确标示。当前真实内容数量、官方目录与画面夹具不同。图片缺失时重新生成对应黄金图或参考渲染，不能把缺图认作通过。</p>${cells.join()}<p>代码、构建、设备与视觉审查分别见 summary.md。</p></html>''',
  );
}
