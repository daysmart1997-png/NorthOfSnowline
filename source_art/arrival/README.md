# 南侧求生路线与基础物资

2026-09-11，按用户授权为《雪线以北》原创程序建模；无新下载的第三方模型、纹理或录音。项目尚未选择开源许可证，此说明不额外授予授权。

- road_kiosk：窄单间、单坡金属屋顶、破窗、值班桌和长凳；无火炉、无卧铺。
- charcoal_lodge：坡屋顶、半隔断卧铺、旧炉、储物架与打包桌。与现有小屋、维修间的轮廓、尺度和通行布局不同。
- item_wood / water / food / cloth / bandage / battery：六种基础物资，同一 GLB 用于环境、背包近看和放置恢复。Cap、Seal 分组支持短动作。
- 每个 .blend 保留独立可编辑物件；对应 assets/arrival/*.glb 仅在保存源后按材质合并。修改源与运行资源须一起同步。

定向重建：`blender --background --python tools/build_arrival_assets.py`。该脚本只读取旧 tools/build_architecture.py 的几何辅助定义，不执行旧资产构建或导出，不修改现有 architecture/ 模型。工具版本：Blender 5.2.1 LTS / macOS。

声音源为 tools/build_arrival_audio.py，自行合成六种材质的短音草稿，写入 assets/arrival/foley_*.wav（PCM mono 22050 Hz）。用于物件接触反馈，不是演员配音或现场拟音；主观听感仍需人工验收。两个定向脚本均从自身位置定位仓库。
