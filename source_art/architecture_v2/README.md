# 房屋与家具第二版源文件

2026-09-11，用户授权为《雪线以北》制作的原创程序建模细化；沿用项目原有林场木屋语言与材料，不包含新增下载的第三方网格、贴图或文字牌。原始美术尚未选择开源许可证，本说明不授予额外授权。沿用资产来源及材质说明见 docs/06_POLISH.md。

- `cabin_lived.blend` → `assets/architecture/cabin_lived.glb`：保留原小屋外壳；移动床位以避开无线电桌，重新制作软床垫、垂毯、枕头、混合收纳、生活椅、桌抽屉、炉门与烟管接头。
- `station_workshop.blend` → `assets/architecture/station_workshop.glb`：10×8 米室内、低屋顶、横向木板、长窗和封闭服务窗；长工作台/台钳、工具墙、零件柜、抽屉柜、折叠床。
- Blender 文件保留独立对象和结构/家具分组；运行 GLB 按组/材质合并，保留 `Roof`、`CutawayFront`、`CutawayRight`、`FireWindow`、升级组和 `ModuleSurface` / `ModulePickup` 定位点。
- 全部坐标使用 Godot X右/Y上/Z前，工具统一转换到 Blender。两屋运行根节点离世界地面 0.24 米；脚部碰撞以同一布局输出到 `scripts/building_layouts.gd`。

## 定向重建

```sh
blender --background --python tools/refine_buildings.py
```

脚本从自身位置定位仓库，只输出上述两套资产和布局文件。它读取 `tools/build_architecture.py` 的几何辅助定义及原小屋构建段，**不执行旧 export 调用、桥梁/营地/其他物件生成段**。不要用历史全量构建脚本替代此命令。Blender 保存源文件后再为 GLB 合并，不覆盖可编辑对象。导出时保留资源旁 `.import`；二进制使用 Git LFS，`.blend1` 备份不提交。

修改尺寸后同步检查碰撞、床铺交互、门廊、室内区域与剖切；维修反馈以导出的定位点为准。运行 `python3 tools/run_checks.py --godot <引擎>`，原生检查可追加 `--building-preview` 输出截图（不录像、不写玩家存档）。当前已验证 Blender 5.2.1 LTS / Mac；Windows 需要独立复验。

## 流程 1–4 追加（2026-09-11）

维修间柜体改为空心分层结构，导出 CabinetDoorLeft / CabinetDoorRight 铰链与 CabinetStock 物资组；游戏按 Expedition.collected 驱动开门和库存显示。小屋增加 DepartureTrace 的旧手套、空挂带与浅色痕迹。运行目标尺寸与原碰撞保持兼容，详见 docs/31_CHAPTER_FLOW_RELEASE.md。
