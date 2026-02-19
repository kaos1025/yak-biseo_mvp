"""
iHerb + Oliveyoung 영양제 데이터 병합 스크립트

입력:
  - c:\juji\iherb-scrap\data\products_bilingual.json (iHerb 511개)
  - c:\juji\oliveyoung-scrap\data\oliveyoung_products.json (Oliveyoung 300개)

출력:
  - assets/db/supplements_db.json (병합된 811개)
"""

import json
import re
import os
from pathlib import Path

# ─── 성분명 정규화 매핑 테이블 ───
# IngredientCategory.koreanMapping과 동일한 로직
NORMALIZE_MAP = {
    # === Vitamins ===
    'vitamin a': 'vitamin_a',
    'beta carotene': 'vitamin_a',
    'beta-carotene': 'vitamin_a',
    'retinol': 'vitamin_a',
    'palmitate': 'vitamin_a',
    '비타민a': 'vitamin_a',
    '비타민 a': 'vitamin_a',

    'vitamin c': 'vitamin_c',
    'ascorbic acid': 'vitamin_c',
    '비타민c': 'vitamin_c',
    '비타민 c': 'vitamin_c',
    '아스코르브산': 'vitamin_c',

    'vitamin d': 'vitamin_d',
    'vitamin d3': 'vitamin_d',
    'cholecalciferol': 'vitamin_d',
    '비타민d': 'vitamin_d',
    '비타민 d': 'vitamin_d',
    '비타민d3': 'vitamin_d',
    '콜레칼시페롤': 'vitamin_d',

    'vitamin e': 'vitamin_e',
    'tocopherol': 'vitamin_e',
    'tocopheryl': 'vitamin_e',
    'd-alpha tocopherol': 'vitamin_e',
    '비타민e': 'vitamin_e',
    '비타민 e': 'vitamin_e',
    '토코페롤': 'vitamin_e',

    'vitamin k': 'vitamin_k',
    'vitamin k1': 'vitamin_k',
    'vitamin k2': 'vitamin_k',
    'phytonadione': 'vitamin_k',
    '비타민k': 'vitamin_k',
    '비타민 k': 'vitamin_k',

    'thiamin': 'vitamin_b1',
    'thiamine': 'vitamin_b1',
    'vitamin b1': 'vitamin_b1',
    'vitamin b-1': 'vitamin_b1',
    '비타민b1': 'vitamin_b1',
    '비타민 b1': 'vitamin_b1',
    '티아민': 'vitamin_b1',

    'riboflavin': 'vitamin_b2',
    'vitamin b2': 'vitamin_b2',
    'vitamin b-2': 'vitamin_b2',
    '비타민b2': 'vitamin_b2',
    '비타민 b2': 'vitamin_b2',
    '리보플라빈': 'vitamin_b2',

    'niacin': 'niacin',
    'niacinamide': 'niacin',
    '나이아신': 'niacin',
    '니아신': 'niacin',

    'vitamin b6': 'vitamin_b6',
    'vitamin b-6': 'vitamin_b6',
    'pyridoxine': 'vitamin_b6',
    'pyridoxal': 'vitamin_b6',
    '비타민b6': 'vitamin_b6',
    '비타민 b6': 'vitamin_b6',
    '피리독신': 'vitamin_b6',

    'folate': 'folate',
    'folic acid': 'folate',
    'methyltetrahydrofolate': 'folate',
    '엽산': 'folate',
    '폴산': 'folate',

    'vitamin b12': 'vitamin_b12',
    'vitamin b-12': 'vitamin_b12',
    'cobalamin': 'vitamin_b12',
    'methylcobalamin': 'vitamin_b12',
    'cyanocobalamin': 'vitamin_b12',
    '비타민b12': 'vitamin_b12',
    '비타민 b12': 'vitamin_b12',
    '코발라민': 'vitamin_b12',

    'biotin': 'biotin',
    '비오틴': 'biotin',

    'pantothenic acid': 'pantothenic_acid',
    'calcium pantothenate': 'pantothenic_acid',
    '판토텐산': 'pantothenic_acid',

    # === Minerals ===
    'calcium': 'calcium',
    '칼슘': 'calcium',

    'magnesium': 'magnesium',
    '마그네슘': 'magnesium',

    'zinc': 'zinc',
    '아연': 'zinc',

    'iron': 'iron',
    '철': 'iron',
    '철분': 'iron',

    'selenium': 'selenium',
    '셀렌': 'selenium',
    '셀레늄': 'selenium',

    'chromium': 'chromium',
    '크롬': 'chromium',

    'copper': 'copper',
    '구리': 'copper',

    'manganese': 'manganese',
    '망간': 'manganese',

    'iodine': 'iodine',
    '요오드': 'iodine',

    'potassium': 'potassium',
    '칼륨': 'potassium',

    'phosphorus': 'phosphorus',
    '인': 'phosphorus',

    'molybdenum': 'molybdenum',
    '몰리브덴': 'molybdenum',

    # === Carotenoids ===
    'lutein': 'lutein',
    '루테인': 'lutein',

    'zeaxanthin': 'zeaxanthin',
    '지아잔틴': 'zeaxanthin',
    '제아잔틴': 'zeaxanthin',

    'lycopene': 'lycopene',
    '라이코펜': 'lycopene',

    # === Fatty Acids ===
    'omega-3': 'omega_3',
    'omega3': 'omega_3',
    '오메가3': 'omega_3',
    '오메가-3': 'omega_3',
    'epa': 'epa',
    'dha': 'dha',

    # === Others ===
    'coenzyme q10': 'coenzyme_q10',
    'coq10': 'coenzyme_q10',
    '코엔자임q10': 'coenzyme_q10',
    '코큐텐': 'coenzyme_q10',

    'collagen': 'collagen',
    '콜라겐': 'collagen',

    'probiotics': 'probiotics',
    '프로바이오틱스': 'probiotics',
    '유산균': 'probiotics',

    'glucosamine': 'glucosamine',
    '글루코사민': 'glucosamine',

    'inositol': 'inositol',
    '이노시톨': 'inositol',

    'alpha lipoic acid': 'alpha_lipoic_acid',
    '알파리포산': 'alpha_lipoic_acid',

    'boron': 'boron',
    '보론': 'boron',

    '실리마린': 'milk_thistle',
    '밀크씨슬': 'milk_thistle',
    'milk thistle': 'milk_thistle',
    'silymarin': 'milk_thistle',
}


def normalize_ingredient_name(name: str) -> str:
    """성분명을 정규화한다.

    1. 소문자로 변환
    2. 괄호 안의 내용 제거 (as ... 형태)
    3. 매핑 테이블에서 조회
    4. 실패 시 snake_case로 변환
    """
    if not name:
        return ''

    clean = name.lower().strip()

    # 괄호 앞의 기본 이름 추출
    base_name = re.sub(r'\s*\(.*?\)', '', clean).strip()
    # 특수기호 제거
    base_name = re.sub(r'[†*®™]', '', base_name).strip()

    # 1. 정확한 매칭
    if base_name in NORMALIZE_MAP:
        return NORMALIZE_MAP[base_name]

    # 2. 공백 제거 후 매칭
    no_space = base_name.replace(' ', '')
    if no_space in NORMALIZE_MAP:
        return NORMALIZE_MAP[no_space]

    # 3. 부분 매칭 (시작 부분)
    for key, value in NORMALIZE_MAP.items():
        if base_name.startswith(key) or no_space.startswith(key.replace(' ', '')):
            return value

    # 4. 실패 → snake_case
    result = re.sub(r'[^a-z0-9가-힣\s]', '', base_name)
    result = re.sub(r'\s+', '_', result).strip('_')
    return result if result else 'unknown'


def process_iherb(products: list) -> list:
    """iHerb 제품 데이터 변환"""
    result = []
    for p in products:
        ingredients = []
        for ing in p.get('ingredients', []):
            ing_name = ing.get('name', '')
            # 영양 성분이 아닌 항목 스킵 (예: "Calories", "Total Carbohydrate")
            skip_names = {'calories', 'total carbohydrate', 'total sugars',
                          'added sugars', 'total fat', 'sodium',
                          'three capsules contain:'}
            if ing_name.lower().strip().rstrip(':') in skip_names:
                continue

            ingredients.append({
                'name': ing_name,
                'name_ko': ing.get('name_ko'),
                'amount': ing.get('amount'),
                'unit': ing.get('unit', ''),
                'dailyValue': ing.get('dailyValue'),
                'name_normalized': normalize_ingredient_name(ing_name),
            })

        result.append({
            'id': f"iherb_{p['productId']}",
            'productId': p['productId'],
            'source': 'iherb',
            'name': p.get('name', ''),
            'name_ko': p.get('name_ko', ''),
            'brand': p.get('brand', ''),
            'price': p.get('price'),
            'currency': p.get('currency', 'KRW'),
            'servingSize': p.get('servingSize', ''),
            'servingSize_ko': p.get('servingSize_ko', ''),
            'categories': p.get('categories', []),
            'categories_ko': p.get('categories_ko', []),
            'rating': p.get('rating'),
            'reviewCount': p.get('reviewCount'),
            'ingredients': ingredients,
        })
    return result


def process_oliveyoung(products: list) -> list:
    """Oliveyoung 제품 데이터 변환"""
    result = []
    for p in products:
        ingredients = []
        for ing in p.get('ingredients', []):
            ing_name = ing.get('name', '')
            # 파싱 오류 데이터 스킵
            if not ing_name or ing_name.startswith('000'):
                continue

            ingredients.append({
                'name': ing_name,
                'name_ko': ing_name,  # 올리브영은 이미 한글
                'amount': ing.get('amount'),
                'unit': ing.get('unit', ''),
                'dailyValue': ing.get('dailyValue'),
                'name_normalized': normalize_ingredient_name(ing_name),
            })

        result.append({
            'id': f"oliveyoung_{p['productId']}",
            'productId': p['productId'],
            'source': 'oliveyoung',
            'name': p.get('name', ''),
            'name_ko': p.get('name', ''),  # 한글 제품명
            'brand': p.get('brand', ''),
            'price': p.get('price'),
            'currency': p.get('currency', 'KRW'),
            'servingSize': p.get('servingSize', ''),
            'servingSize_ko': p.get('servingSize', ''),
            'categories': p.get('categories', []),
            'categories_ko': p.get('categories', []),
            'rating': p.get('rating'),
            'reviewCount': p.get('reviewCount'),
            'ingredients': ingredients,
        })
    return result


def main():
    script_dir = Path(__file__).parent
    project_root = script_dir.parent

    # 입력 파일 경로
    iherb_path = Path(r'c:\juji\iherb-scrap\data\products_bilingual.json')
    oliveyoung_path = Path(r'c:\juji\oliveyoung-scrap\data\oliveyoung_products.json')

    # 출력 파일 경로
    output_dir = project_root / 'assets' / 'db'
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / 'supplements_db.json'

    # 1. 데이터 로드
    print(f'Loading iHerb data from {iherb_path}...')
    with open(iherb_path, 'r', encoding='utf-8') as f:
        iherb_data = json.load(f)
    print(f'  → {len(iherb_data)} products loaded')

    print(f'Loading Oliveyoung data from {oliveyoung_path}...')
    with open(oliveyoung_path, 'r', encoding='utf-8') as f:
        oliveyoung_data = json.load(f)
    print(f'  → {len(oliveyoung_data)} products loaded')

    # 2. 변환
    print('Processing iHerb products...')
    iherb_processed = process_iherb(iherb_data)

    print('Processing Oliveyoung products...')
    oliveyoung_processed = process_oliveyoung(oliveyoung_data)

    # 3. 병합
    merged = iherb_processed + oliveyoung_processed
    print(f'\nTotal merged: {len(merged)} products')
    print(f'  iHerb: {len(iherb_processed)}')
    print(f'  Oliveyoung: {len(oliveyoung_processed)}')

    # 4. 정규화 통계
    all_normalized = set()
    unmapped_count = 0
    for p in merged:
        for ing in p['ingredients']:
            norm = ing['name_normalized']
            all_normalized.add(norm)
            if norm not in NORMALIZE_MAP.values():
                unmapped_count += 1

    print(f'\nUnique normalized ingredient names: {len(all_normalized)}')
    print(f'Unmapped ingredients: {unmapped_count}')

    # 5. 저장
    print(f'\nSaving to {output_path}...')
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(merged, f, ensure_ascii=False, indent=2)

    file_size_mb = output_path.stat().st_size / (1024 * 1024)
    print(f'Done! File size: {file_size_mb:.1f} MB')


if __name__ == '__main__':
    main()
