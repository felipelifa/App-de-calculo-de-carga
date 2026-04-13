import json
import os

input_file = r"C:\Users\Felipe\.gemini\antigravity\brain\b56745b0-df6b-4dd3-9d34-573c125ee432\.system_generated\steps\1044\content.md"
output_file = r"d:\App de calculo de carga\app\assets\data\tbca_minified.json"

os.makedirs(os.path.dirname(output_file), exist_ok=True)

parsed_data = []

with open(input_file, 'r', encoding='utf-8') as f:
    for line in f:
        line = line.strip()
        if not line.startswith('{"codigo"'): continue
        try:
            item = json.loads(line)
            
            # extract basic macros safely
            kcal = 0
            prot = 0
            carb = 0
            fat = 0
            
            for n in item.get('nutrientes', []):
                val_str = str(n.get('Valor por 100g', '0')).replace(',', '.').replace('tr', '0').replace('NA', '0')
                try:
                    val = float(val_str)
                except ValueError:
                    val = 0
                    
                comp = n.get('Componente', '')
                if comp == 'Energia' and n.get('Unidades') == 'kcal':
                    kcal = val
                elif comp == 'Proteína':
                    prot = val
                elif comp == 'Carboidrato total':
                    carb = val
                elif comp == 'Lipídios':
                    fat = val

            # Keep it lightweight!
            parsed_data.append({
                "id": f"tbca_{item['codigo']}",
                "name": item.get('descricao', '').strip(', '),
                "cat": item.get('classe', 'Geral'),
                "kcal": kcal,
                "p": prot,
                "c": carb,
                "f": fat
            })
        except json.JSONDecodeError:
            pass

with open(output_file, 'w', encoding='utf-8') as f:
    json.dump(parsed_data, f, ensure_ascii=False)

print(f"Gerado tbca_minified.json com {len(parsed_data)} itens.")
