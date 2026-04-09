const fs = require('fs');

// Read the current exercise library (949 exercises)
let content = fs.readFileSync('app/lib/core/data/exercise_library.dart', 'utf8');

// Replace all gifUrls
content = content.replace(/gifUrl:\s*'assets\/gifs\/([^']+)'/g, (match, filename) => {
    // URL encode the filename to handle spaces and accents properly in the URL
    // We use encodeURIComponent but we should keep slashes if there are any.
    // However, filenames shouldn't have slashes.
    const encodedFilename = encodeURIComponent(filename);
    return `gifUrl: 'https://raw.githubusercontent.com/felipelifa/App-de-calculo-de-carga/main/biblioteca%20de%20gif/${encodedFilename}'`;
});

fs.writeFileSync('app/lib/core/data/exercise_library.dart', content);
console.log('URLs atualizadas com sucesso para o GitHub!');
