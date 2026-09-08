# v0.4 完成情况与验证

更新：2026-09-09，Godot 4.7.2 / Windows / Compatibility。当前包含 14 类物品、9 处探索地点、7 项配方、庇护所与营地、磁带机以及旧存档兼容。

本轮完成地形高低差与冻湖、独立雪深分布、对称腿部动画与足部贴坡 IK、实际落脚坐标驱动鞋印和深雪拖痕、统一建筑风格及室内陈设、界面字体与材质、旧纸地图。详见 07_FRONTIER.md；动画及音频来源保留在 06_POLISH.md。

## 最终验证

- 36 项规则检查：artifacts/v04-rules.log，EXPEDITION_RESULT failures=0。
- 出入建筑、实体墙、桥头斜坡与桥面、建造、储物、拾取、声音、存档和无线电：artifacts/v04-final-integration.log，INTEGRATION_OK。
- 步态与音频/脚印同步、降雪覆盖、六类物品、真实鼠标拖放装带、帆布开合中断、暂停恢复、呼吸：artifacts/v04-final-polish-test.log，POLISH_OK。
- 地形、积雪、深雪连续沟痕、冰面断痕、实时足部射线与 IK、步行连续帧鞋底朝向、冰面碰撞、室内模块：artifacts/v04-final-frontier-test.log，FRONTIER_OK。
- 上述最终检查日志无脚本错误或资源泄漏警告。测试只写 artifacts/test-save.json。
- Godot 实际渲染检查小屋外观/内部、木桥、营地、行囊、地图、深雪与步态关键帧，截图位于 artifacts/。
- 本机 1280×720 移动场景短测：1 秒预热后采样 6 秒，1451 帧，平均 4.14 ms，P95 4.21 ms，约 92 万三角面、479 次绘制调用。原始结果 artifacts/v04-performance.json；仅代表这段林间场景，不作为全地图或最终美术负载的性能承诺。

## 后续内容

角色造型和衣物细节、手部精准交互、更多树种与手工关卡、冰裂与涉水风险、天气事件、磁带剧情、音量设置、建造自由度。脚印为局部渲染形变，碰撞使用基础地形；背包为二维展开效果。完整剧情内容和独立 Windows 发布包尚未完成。
