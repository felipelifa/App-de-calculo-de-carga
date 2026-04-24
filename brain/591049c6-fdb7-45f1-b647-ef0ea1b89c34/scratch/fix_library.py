import re

path = r'd:\App de calculo de carga\app_flutter\lib\core\data\exercise_library.dart'

with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Pattern for ExerciseModel blocks
pattern = r'(ExerciseModel\(\s*id:\s*[\'\"](.*?)[\'\"].*?tags:\s*\[(.*?)\]\s*,\s*lengthBias:)'

# Instead of re.sub, let's split into chunks to handle multiline easily
blocks = re.split(r'(ExerciseModel\()', content)

new_content = []
count = 0

for i in range(len(blocks)):
    block = blocks[i]
    if block == 'ExerciseModel(':
        new_content.append(block)
        continue
    
    # Check if this is a block with exercise data
    if 'id:' in block:
        id_match = re.search(r"id:\s*['\"]([^'\"]+)['\"]", block)
        if id_match:
            ex_id = id_match.group(1).lower()
            
            # Criteria for gym-only exercises
            gym_indicators = [
                'machine', 'cable', 'barbell', 'smith', 'maquina', 'cabo', 'barra', 
                'leg_press', 'puxada', 'extensora', 'flexora', 'hack', 'adutora', 
                'abdutora', 'peck_deck', 'crossover', 'supino_reto_barra', 'terra_barra'
            ]
            
            # Check for bodyweight/home exercises that should be gym only
            is_gym_name = any(x in ex_id for x in gym_indicators)
            
            # We also check the equipment field
            equip_match = re.search(r"equipment:\s*\[(.*?)\]", block, re.DOTALL)
            if equip_match:
                equip_str = equip_match.group(1).lower()
                has_gym_equip = any(x in equip_str for x in ['machine', 'barbell', 'cable', 'smith', 'barbell'])
                
                if is_gym_name or has_gym_equip:
                    # Fix environment: remove "home"
                    block = re.sub(r'environment:\s*\[(.*?)\]', 'environment: ["gym"]', block)
                    
                    # Fix tags: remove home_friendly and no_equipment
                    block = re.sub(r'["\']home_friendly["\'],?', '', block)
                    block = re.sub(r'["\']no_equipment["\'],?', '', block)
                    
                    # Fix equipment: if it was bodyweight but name says machine/cable/barbell
                    if 'bodyweight' in equip_str:
                        if 'cable' in ex_id or 'cabo' in ex_id:
                            block = re.sub(r'equipment:\s*\[(.*?)\]', 'equipment: ["cable"]', block)
                        elif 'machine' in ex_id or 'maquina' in ex_id or 'press' in ex_id:
                            block = re.sub(r'equipment:\s*\[(.*?)\]', 'equipment: ["machine"]', block)
                        elif 'barbell' in ex_id or 'barra' in ex_id:
                            block = re.sub(r'equipment:\s*\[(.*?)\]', 'equipment: ["barbell"]', block)
                    
                    count += 1
                    
    new_content.append(block)

final_content = "".join(new_content)

with open(path, 'w', encoding='utf-8') as f:
    f.write(final_content)

print(f"Fixed {count} exercises in the library")
