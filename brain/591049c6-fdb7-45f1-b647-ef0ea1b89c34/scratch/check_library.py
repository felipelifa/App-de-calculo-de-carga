import re

path = r'd:\App de calculo de carga\app_flutter\lib\core\data\exercise_library.dart'

with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Split into ExerciseModel blocks
blocks = re.split(r'ExerciseModel\(', content)

anomalies = []

for block in blocks:
    if 'id:' not in block:
        continue
    
    id_match = re.search(r"id:\s*['\"]([^'\"]+)['\"]", block)
    if not id_match:
        continue
    ex_id = id_match.group(1)
    
    env_match = re.search(r"environment:\s*\[(.*?)\]", block, re.DOTALL)
    equip_match = re.search(r"equipment:\s*\[(.*?)\]", block, re.DOTALL)
    
    if env_match and equip_match:
        env = env_match.group(1)
        equip = equip_match.group(1)
        
        # Logic: If it contains 'home' but has gym equipment or names indicating machines
        is_home = 'home' in env
        has_gym_equip = any(x in equip for x in ['machine', 'barbell', 'cable', 'smith'])
        has_gym_id = any(x in ex_id for x in ['leg_press', 'puxada', 'maquina', 'smith'])
        
        if is_home and (has_gym_equip or (has_gym_id and 'bodyweight' in equip)):
            anomalies.append(f"ID: {ex_id} | Equip: {equip} | Env: {env}")

print(f"Found {len(anomalies)} anomalies")
for a in anomalies[:20]:
    print(a)
