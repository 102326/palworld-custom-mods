# Palworld 自制与定制 Mod

这是 2026-08-23 的可复现快照，面向 Steam Windows 客户端和 Windows Dedicated Server。

- 制作时游戏 build：`24575825`
- 当前状态：文件结构、客户端/服务器副本和 SHA-256 已做静态核对
- `ExtendedBaseRange` 已完成兼容性改写，但仍需在当前游戏版本中实测边界、工人活动范围、战斗范围和重启持久性

本仓库只收录我们原创或实际改动过的内容，不包含 UE4SS、PalSchema、游戏存档、日志、崩溃文件以及未修改的第三方整合包。

## 内容

| 目录 | 功能 | 类型 |
| --- | --- | --- |
| `mods/ExtendedBaseRange` | 基地固定 70 米（原版 2 倍），每 5 秒重扫并同步服务端/客户端范围与蓝圈 | UE4SS Lua 兼容改写 |
| `mods/ExpandedStorage12x` | 35 类储物设施扩大到原版 12 倍，背包扩展袋保持原版 | PalSchema 定制规则 |
| `mods/BossRarePalIVFloor` | Boss、Alpha、Lucky/Shiny 帕 IV 下限设为 100 | UE4SS Lua 定制版 |
| `mods/BossPassiveFilter` | 从通用高级词条池随机补足 4 个词条，保留专属词条并过滤负面词条 | UE4SS Lua 定制版 |
| `mods/FasterProductionSites-20x` | 采石、伐木、矿场、油田等生产设施 20 倍速度 | 上游 Mod 配置覆盖 |
| `mods/InventoryExpansion-plus100` | 玩家背包额外增加 100 格 | 上游 Mod 配置覆盖 |
| `mods/PalsDropDogCoins-10x` | 普通帕 20% 掉落 10–30 枚狗狗币，Boss/捕食者 100% 掉落 10–30 枚 | PalSchema 定制规则 |
| `mods/MoreMiningPits-20x` | 铬矿与珊瑚矿生产工作量调整为 20 倍速度版本 | 上游 Mod 规则覆盖 |
| `mods/EarlyUnlock-AllPalGear` | 自动解锁全部 139 件帕鲁鞍具/伙伴装备 | UE4SS Lua 定制版 |
| `pak/CraftingMaterials20x_AmmoBaitSpheresMedicine100x_Current103_P.pak` | 加工材料 20 倍；弹药、钓饵、帕鲁球、药品 100 倍 | 定制 PAK |
| `pak/BetterFishingRarity_Custom_Boss20x_Nushi100x_P.pak` | 钓鱼 Boss 权重 20 倍、湖主/Nushi 权重 100 倍 | 定制 PAK |
| `pak/MoneyDropsRewards5x_Current103_P.pak` | 怪物/NPC 掉落和宝箱金币 5 倍，商店价格不变 | 定制 PAK |
| `tools/UassetJson` | 制作数据表 PAK 时使用的 UAsset JSON 转换辅助工具源码 | C# 工具 |

克隆时请同时取得固定版本的 UAssetAPI 子模块：

```powershell
git clone --recurse-submodules <仓库地址>
```

## 安装原则

安装前必须完全退出 Palworld 和 PalServer，并备份同名 Mod。

### UE4SS Lua

把完整 Mod 目录放到：

- 客户端：`Palworld/Mods/NativeMods/UE4SS/Mods/`
- 服务端：`PalServer/Pal/Binaries/Win64/ue4ss/Mods/`

`FasterProductionSites-20x` 和 `InventoryExpansion-plus100` 仅提供修改后的配置，需要先安装对应上游 Mod，再覆盖同名配置文件。

### PalSchema

把规则目录放到 `PalSchema/mods/`。客户端和服务器应使用同一份规则。

### PAK

把 `pak/` 中需要的文件放到：

`Pal/Content/Paks/~mods/`

联机时建议客户端和服务器使用相同版本。与其他修改同一 DataTable 的 PAK 同时使用时，后加载者可能覆盖前者。

## 验证

`SHA256SUMS.txt` 记录仓库内发布文件的 SHA-256。安装验证只证明文件完整与静态结构正确，不等于当前游戏版本已经完成运行时兼容测试。

## 上游与授权

部分目录是第三方 Mod 的配置或衍生修改，不主张其上游代码、美术或游戏资产的权利。详情见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。本仓库没有设置覆盖全部内容的统一开源许可证。
