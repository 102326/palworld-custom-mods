using UAssetAPI;
using UAssetAPI.ExportTypes;
using UAssetAPI.PropertyTypes.Objects;
using UAssetAPI.PropertyTypes.Structs;
using UAssetAPI.UnrealTypes;
using UAssetAPI.Unversioned;
using System.Text.Json;
using System.Text.Json.Nodes;

if (args.Length < 3)
{
    Console.Error.WriteLine("usage: uassetjson-palworld tojson <in.uasset> <out.json> [mappings.usmap]");
    Console.Error.WriteLine("       uassetjson-palworld fromjson <in.json> <out.uasset> [mappings.usmap]");
    Console.Error.WriteLine("       uassetjson-palworld patchrecipe <in.uasset> <targets.json> <out.uasset> <mappings.usmap>");
    Console.Error.WriteLine("       uassetjson-palworld patchfishing <in.uasset> <out.uasset> <mappings.usmap> [boss-factor] [nushi-factor]");
    Console.Error.WriteLine("       uassetjson-palworld patchmoney <in.uasset> <out.uasset> <mappings.usmap> [factor]");
    return 1;
}

switch (args[0])
{
    case "tojson":
    {
        Usmap mappings = args.Length > 3 ? new Usmap(args[3]) : null;
        var asset = new UAsset(args[1], EngineVersion.VER_UE5_1, mappings);
        File.WriteAllText(args[2], asset.SerializeJson(true));
        Console.WriteLine($"OK {args[1]} -> {args[2]}");
        return 0;
    }
    case "fromjson":
    {
        var asset = UAsset.DeserializeJson(File.ReadAllText(args[1]));
        asset.Mappings = args.Length > 3 ? new Usmap(args[3]) : null;
        asset.Write(args[2]);
        Console.WriteLine($"OK {args[1]} -> {args[2]}");
        return 0;
    }
    case "patchrecipe":
    {
        if (args.Length != 5)
        {
            Console.Error.WriteLine("patchrecipe requires <in.uasset> <targets.json> <out.uasset> <mappings.usmap>");
            return 1;
        }

        using var targetDocument = JsonDocument.Parse(File.ReadAllText(args[2]));
        var targetTable = targetDocument.RootElement.GetProperty("DT_ItemRecipeDataTable");
        var targets = targetTable.EnumerateObject().ToDictionary(
            entry => entry.Name,
            entry => entry.Value.GetProperty("Product_Count").GetInt32(),
            StringComparer.Ordinal);

        var asset = new UAsset(args[1], EngineVersion.VER_UE5_1, new Usmap(args[4]));
        var export = asset.Exports.OfType<DataTableExport>().Single();
        var changed = new Dictionary<string, (int OldValue, int NewValue)>(StringComparer.Ordinal);

        foreach (StructPropertyData row in export.Table.Data)
        {
            var rowName = row.Name.ToString();
            if (!targets.TryGetValue(rowName, out var targetValue)) continue;

            var countProperty = row.Value
                .OfType<IntPropertyData>()
                .Single(property => property.Name.ToString() == "Product_Count");
            changed.Add(rowName, (countProperty.Value, targetValue));
            countProperty.Value = targetValue;
        }

        var missing = targets.Keys.Except(changed.Keys, StringComparer.Ordinal).OrderBy(name => name).ToArray();
        if (missing.Length != 0)
        {
            Console.Error.WriteLine($"Missing recipe rows: {string.Join(", ", missing)}");
            return 2;
        }
        if (changed.Count != targets.Count)
        {
            Console.Error.WriteLine($"Expected {targets.Count} changes, found {changed.Count}");
            return 3;
        }

        asset.Write(args[3]);
        foreach (var entry in changed.OrderBy(entry => entry.Key))
        {
            Console.WriteLine($"{entry.Key}: {entry.Value.OldValue} -> {entry.Value.NewValue}");
        }
        Console.WriteLine($"OK patched {changed.Count} recipe rows -> {args[3]}");
        return 0;
    }
    case "patchfishing":
    {
        if (args.Length is < 4 or > 6)
        {
            Console.Error.WriteLine("patchfishing requires <in.uasset> <out.uasset> <mappings.usmap> [boss-factor] [nushi-factor]");
            return 1;
        }

        var bossFactor = args.Length > 4 ? float.Parse(args[4], System.Globalization.CultureInfo.InvariantCulture) : 5.0f;
        var nushiFactor = args.Length > 5 ? float.Parse(args[5], System.Globalization.CultureInfo.InvariantCulture) : 10.0f;

        var asset = new UAsset(args[1], EngineVersion.VER_UE5_1, new Usmap(args[3]));
        var export = asset.Exports.OfType<DataTableExport>().Single();
        var rows = export.Table.Data.Select(row =>
        {
            var lottery = row.Value.OfType<NamePropertyData>()
                .Single(property => property.Name.ToString() == "LotteryName").Value.ToString();
            var shadow = row.Value.OfType<NamePropertyData>()
                .Single(property => property.Name.ToString() == "FishShadowId").Value.ToString();
            var weight = row.Value.OfType<FloatPropertyData>()
                .Single(property => property.Name.ToString() == "Weight");
            var factor = shadow.EndsWith("_Boss", StringComparison.Ordinal) ? bossFactor
                : shadow.EndsWith("_Nushi", StringComparison.Ordinal) ? nushiFactor
                : shadow.EndsWith("_Common", StringComparison.Ordinal) ? 1.0f
                : 0.0f;
            return new { Row = row, Lottery = lottery, Shadow = shadow, Weight = weight, Factor = factor };
        }).ToArray();

        var changed = 0;
        foreach (var group in rows.GroupBy(row => row.Lottery, StringComparer.Ordinal))
        {
            if (group.Any(row => row.Factor == 0.0f)) continue;
            var originalTotal = group.Sum(row => (double)row.Weight.Value);
            var boostedTotal = group.Sum(row => (double)row.Weight.Value * row.Factor);
            var scale = originalTotal / boostedTotal;
            foreach (var row in group)
            {
                row.Weight.Value = (float)(row.Weight.Value * row.Factor * scale);
                changed++;
            }
        }

        asset.Write(args[2]);
        Console.WriteLine($"OK patched {changed} fishing weights (Common 1x, Boss {bossFactor}x, Nushi {nushiFactor}x) -> {args[2]}");
        return 0;
    }
    case "patchmoney":
    {
        if (args.Length is < 4 or > 5)
        {
            Console.Error.WriteLine("patchmoney requires <in.uasset> <out.uasset> <mappings.usmap> [factor]");
            return 1;
        }

        var factor = args.Length > 4 ? int.Parse(args[4], System.Globalization.CultureInfo.InvariantCulture) : 5;
        if (factor < 1) throw new ArgumentOutOfRangeException(nameof(factor));

        var source = new UAsset(args[1], EngineVersion.VER_UE5_1, new Usmap(args[3]));
        var root = JsonNode.Parse(source.SerializeJson(true))!;
        var changes = new List<(string ItemProperty, string CountProperty, int OldValue, int NewValue)>();

        void Walk(JsonNode? node)
        {
            if (node is JsonArray array)
            {
                var properties = array.OfType<JsonObject>()
                    .Where(item => item["Name"] is not null && item["Value"] is not null)
                    .ToArray();

                foreach (var item in properties)
                {
                    var itemName = item["Name"]!.GetValue<string>();
                    if (item["Value"]!.GetValueKind() != JsonValueKind.String ||
                        item["Value"]!.GetValue<string>() != "Money") continue;

                    string[] countNames;
                    if (itemName == "StaticItemId")
                    {
                        countNames = ["MinNum", "MaxNum"];
                    }
                    else if (itemName.StartsWith("ItemId", StringComparison.Ordinal))
                    {
                        var suffix = itemName["ItemId".Length..];
                        countNames = [$"min{suffix}", $"Max{suffix}"];
                    }
                    else
                    {
                        continue;
                    }

                    foreach (var countName in countNames)
                    {
                        var count = properties.SingleOrDefault(property =>
                            property["Name"]!.GetValue<string>() == countName);
                        if (count is null || count["Value"]!.GetValueKind() != JsonValueKind.Number) continue;
                        var oldValue = count["Value"]!.GetValue<int>();
                        if (oldValue <= 0) continue;
                        var newValue = checked(oldValue * factor);
                        count["Value"] = newValue;
                        changes.Add((itemName, countName, oldValue, newValue));
                    }
                }

                foreach (var child in array.ToArray()) Walk(child);
            }
            else if (node is JsonObject obj)
            {
                foreach (var child in obj.ToArray()) Walk(child.Value);
            }
        }

        Walk(root);
        if (changes.Count == 0)
        {
            Console.Error.WriteLine("No positive Money quantity fields found");
            return 2;
        }

        var patched = UAsset.DeserializeJson(root.ToJsonString());
        patched.Mappings = new Usmap(args[3]);
        patched.Write(args[2]);
        foreach (var change in changes)
            Console.WriteLine($"{change.ItemProperty}/{change.CountProperty}: {change.OldValue} -> {change.NewValue}");
        Console.WriteLine($"OK patched {changes.Count} Money quantity fields ({factor}x) -> {args[2]}");
        return 0;
    }
    default:
        Console.Error.WriteLine($"unknown mode: {args[0]}");
        return 1;
}
