# 第三方来源说明

本仓库混合了原创兼容代码、对第三方 Mod 的配置覆盖，以及从当前游戏数据制作的定制 PAK。第三方作者和 Pocketpair 对其各自内容保留全部权利。

已知上游来源：

- Extended Base Range：Steam Workshop `3625907101`；兼容实现参考 Progressive Base Radius 的生命周期/重扫思路。
- Expanded Storage：Nexus Mods `4377`，并参考 Steam Workshop `3766607347` 的覆盖范围。
- BetterBossLucky：Nexus Mods `4178`；本仓库的两个 Boss Lua 模块是定制行为版本。
- FasterProductionSites：Nexus Mods `4847`；仅收录修改后的 20 倍配置。
- Inventory Expansion：Nexus Mods `4030`；仅收录额外 100 格配置。
- BetterFishingRarity：Nexus Mods `4942`；仓库 PAK 为本地权重修改版。
- MoreMiningPits / Chromite And Coralum Mines：Nexus Mods `5073`；仅收录本地生产规则覆盖。
- EarlyUnlock：Nexus Mods `4179`；仓库版本增加了全部帕鲁装备解锁行为。
- Annoying Crafting Materials：Nexus Mods `4271`；配方 PAK 后续扩展为加工材料 20 倍和多类消耗品 100 倍。
- PalsDropDogCoins：基于已安装的 PalSchema 规则调整掉落数量，保留原概率设计。
- UAssetAPI：`atenfyr/UAssetAPI`，以 Git 子模块固定到实际构建版本；上游使用 MIT License。

除非对应上游许可证明确允许，否则不要把第三方衍生内容重新发布为自己的原创作品。公开发布前应再次核对每个上游页面的再分发许可。
