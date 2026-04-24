import re

path = r'd:\App de calculo de carga\app_flutter\lib\core\data\exercise_library.dart'

with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Pattern to split into ExerciseModel blocks
blocks = re.split(r'(ExerciseModel\()', content)

new_content = []
seen_names = set()
removed_count = 0

for i in range(len(blocks)):
    block = blocks[i]
    if block == 'ExerciseModel(':
        # We look ahead to the next block to see if we should keep it
        next_block = blocks[i+1]
        
        # Extract name and ID
        name_match = re.search(r"name:\s*['\"]([^'\"]+)['\"]", next_block)
        id_match = re.search(r"id:\s*['\"]([^'\"]+)['\"]", next_block)
        
        if name_match and id_match:
            name = name_match.group(1).strip()
            ex_id = id_match.group(1).strip()
            
            # Check for (1) at the end or identical name seen before
            is_duplicate_name = name.endswith('(1)') or name.endswith('(2)')
            
            # Clean name for "already seen" check (ignoring the (1))
            clean_name = re.sub(r'\s*\(\d+\)$', '', name).lower()
            
            if is_duplicate_name or clean_name in seen_names:
                removed_count += 1
                # Skip this block and the next_block (handled in the next iteration of 'if id:' below)
                continue
            
            seen_names.add(clean_name)
        
        new_content.append(block)
    else:
        # This is the content inside the ExerciseModel(...)
        # But wait, the way I split it, if I skip the 'ExerciseModel(' part, I must also skip this part.
        
        # Let's try a different approach to avoid state issues
        pass

# Second attempt at the script logic to be more robust
blocks = re.split(r'(ExerciseModel\()', content)
header = blocks[0]
actual_blocks = []
for i in range(1, len(blocks), 2):
    actual_blocks.append(blocks[i] + blocks[i+1])

final_blocks = []
seen_names = set()
removed = 0

for b in actual_blocks:
    name_match = re.search(r"name:\s*['\"]([^'\"]+)['\"]", b)
    if name_match:
        name = name_match.group(1).strip()
        
        # Logic: remove if ends with (1), (2), etc. OR if clean name already seen
        is_suffix_dup = re.search(r'\(\d+\)$', name)
        clean_name = re.sub(r'\s*\(\d+\)$', '', name).lower()
        
        if is_suffix_dup or clean_name in seen_names:
            removed += 1
            continue
        
        seen_names.add(clean_name)
    
    final_blocks.append(b)

# Join back
# The blocks were separated by commas usually, but re.split removed the 'ExerciseModel('
# I put it back in actual_blocks.
# The separator between blocks in the list is usually `  ),\n\n  `

output = header + "".join(final_blocks)

with open(path, 'w', encoding='utf-8') as f:
    f.write(output)

print(f"Removed {removed} duplicate exercises.")
