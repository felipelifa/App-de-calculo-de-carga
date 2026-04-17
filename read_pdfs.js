const fs = require('fs');
const { PDFParse } = require('./node_modules/pdf-parse');

async function main() {
  try {
    const parser = new PDFParse();
    const buf1 = fs.readFileSync('ideia 1.pdf');
    const data1 = await parser.parse(buf1);
    const pages1 = data1.pages || [];
    let text1 = pages1.map(p => p.Texts ? p.Texts.map(t => decodeURIComponent(t.R.map(r => r.T).join(''))).join(' ') : '').join('\n');
    console.log('=== IDEIA 1 ===\n' + text1.substring(0, 10000));
  } catch(e) {
    console.log('Erro ideia 1:', e.message, e.stack);
  }

  try {
    const parser = new PDFParse();
    const buf2 = fs.readFileSync('ideia 2.pdf');
    const data2 = await parser.parse(buf2);
    const pages2 = data2.pages || [];
    let text2 = pages2.map(p => p.Texts ? p.Texts.map(t => decodeURIComponent(t.R.map(r => r.T).join(''))).join(' ') : '').join('\n');
    console.log('\n=== IDEIA 2 ===\n' + text2.substring(0, 10000));
  } catch(e) {
    console.log('Erro ideia 2:', e.message);
  }
}

main();
