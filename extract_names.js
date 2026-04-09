const fs = require('fs');
const content = fs.readFileSync('app/lib/core/data/exercise_library.dart', 'utf8');
const regex = /name:\s*'([^']+)'/g;
let match;
const names = [];
while ((match = regex.exec(content)) !== null) {
    names.push(match[1]);
}
fs.writeFileSync('exercise_names.txt', names.join('\n'));
console.log(`Extracted ${names.length} names.`);
