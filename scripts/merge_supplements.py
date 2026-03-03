"""iHerb 스크래핑 데이터 → supplements_db.json 머지"""
import json, re, os

EXISTING = r"C:\juji\yak-biseo_mvp\assets\db\supplements_db.json"
NEW_DATA = r"C:\juji\iherb-scrap\data\products.json"
OUTPUT   = EXISTING

def norm_name(name):
    if not name: return ""
    c = re.sub(r'\(.*?\)', '', name)
    c = re.sub(r'[^\w\s]', '', c).strip().lower()
    return re.sub(r'\s+', '_', c)

def convert(p):
    pid = p.get("productId", "")
    ings = []
    for i in p.get("ingredients", []):
        ings.append({
            "name": i.get("name",""), "name_ko": i.get("name_ko"),
            "amount": i.get("amount"), "unit": i.get("unit",""),
            "dailyValue": i.get("dailyValue"),
            "name_normalized": norm_name(i.get("name",""))
        })
    return {
        "id": f"iherb_{pid}", "productId": pid, "source": "iherb",
        "name": p.get("name",""), "name_ko": p.get("name_ko"),
        "brand": p.get("brand",""), "price": p.get("price"),
        "currency": p.get("currency","KRW"),
        "servingSize": p.get("servingSize"), "servingSize_ko": None,
        "categories": p.get("categories",[]), "categories_ko": [],
        "rating": p.get("rating"), "reviewCount": p.get("reviewCount"),
        "ingredients": ings,
    }

print("Loading existing DB...")
with open(EXISTING, "r", encoding="utf-8") as f:
    existing = json.load(f)
print(f"  Existing: {len(existing)}")

print("Loading new data...")
with open(NEW_DATA, "r", encoding="utf-8") as f:
    new_data = json.load(f)
print(f"  New: {len(new_data)}")

merged = {}
for p in existing:
    pid = p.get("productId", p.get("id",""))
    src = p.get("source","")
    key = f"{src}_{pid}" if src != "iherb" else pid
    merged[key] = p

updated, added = 0, 0
for p in new_data:
    pid = p.get("productId","")
    if not pid: continue
    c = convert(p)
    if pid in merged:
        old = merged[pid]
        c["servingSize_ko"] = old.get("servingSize_ko")
        c["categories_ko"] = old.get("categories_ko",[])
        updated += 1
    else:
        added += 1
    merged[pid] = c

result = list(merged.values())
print(f"\n=== Result ===\n  Updated: {updated}\n  Added: {added}\n  Total: {len(result)}")

with open(OUTPUT, "w", encoding="utf-8") as f:
    json.dump(result, f, ensure_ascii=False, indent=2)

size = os.path.getsize(OUTPUT) / (1024*1024)
print(f"  Output: {size:.1f} MB\nDone!")
