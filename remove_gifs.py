import re

filepath = 'app/lib/core/data/exercise_library.dart'

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Remove linhas com gifUrl que apontam para GitHub
content = re.sub(
    r"    gifUrl:\n        'https://raw\.githubusercontent\.com/[^']*',\n", 
    '', 
    content
)

# Remove linhas com gifUrl que apontam para Firebase
content = re.sub(
    r"    gifUrl:\n        'https://firebasestorage\.googleapis\.com/[^']*[?&]alt=media[^']*',\n",
    '',
    content
)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

print('✓ Limpeza concluída - todas as URLs de GIF removidas!')
