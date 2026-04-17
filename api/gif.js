// api/gif.js — Vercel Serverless Function (detectada automaticamente pela Vercel)
// Proxy de GIFs do Firebase Storage para evitar bloqueio de CORS no browser.
// A Vercel registra qualquer arquivo em /api/ como função serverless.

module.exports = async (req, res) => {
  const { name, id, nameEn } = req.query;

  if (!name) {
    res.status(400).json({ error: 'Missing name parameter' });
    return;
  }

  try {
    const toSingleValue = (value) => (Array.isArray(value) ? value[0] : value);
    const safeDecode = (value) => {
      try {
        return decodeURIComponent(value);
      } catch (_) {
        return value;
      }
    };
    const removeGifExt = (value) => value.replace(/\.gif$/i, '').trim();
    const normalizeToStorageName = (value) =>
      value
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '')
        .replace(/[^a-zA-Z0-9]+/g, '_')
        .replace(/^_+|_+$/g, '')
        .toLowerCase();

    const cleanName = removeGifExt(safeDecode(String(toSingleValue(name) || '')));
    const cleanEn = nameEn ? removeGifExt(safeDecode(String(toSingleValue(nameEn)))) : null;
    const cleanIdRaw = toSingleValue(id);
    const cleanId = cleanIdRaw
      ? removeGifExt(safeDecode(String(cleanIdRaw)))
      : null;
    
    const normalizedName = normalizeToStorageName(cleanName);
    const normalizedEn = cleanEn ? normalizeToStorageName(cleanEn) : null;
    const normalizedId = cleanId ? normalizeToStorageName(cleanId) : null;

    const folders = ['', 'exercises_gifs/', 'biblioteca de gif/', 'biblioteca de gifs/', 'gifs/'];

    // Lista de nomes para tentar - SEM deduplicação agressiva
    // O Firebase pode ter o arquivo com espaços OU com underscores
    const variants = [
      cleanName,              // "Crucifixo inverso unilateral com cabo"
      normalizedName,        // "crucifixo_inverso_unilateral_com_cabo"
      ...(cleanEn ? [cleanEn, normalizedEn] : []),
      ...(cleanId ? [cleanId, normalizedId] : []),
    ].filter(Boolean);

    const fileCandidates = [];
    for (const folder of folders) {
      for (const base of variants) {
        fileCandidates.push(`${folder}${base}.gif`);
      }
    }

    // Remove duplicados e vazios
    const uniqueCandidates = [...new Set(fileCandidates)].filter(c => c !== '.gif' && !c.endsWith('/.gif'));

    for (const fileName of uniqueCandidates) {
      const firebaseUrl = `https://firebasestorage.googleapis.com/v0/b/appcalculotreino-51f23.firebasestorage.app/o/${encodeURIComponent(fileName)}?alt=media`;
      const response = await fetch(firebaseUrl);

      if (!response.ok) {
        continue;
      }

      const buffer = await response.arrayBuffer();

      res.setHeader('Content-Type', response.headers.get('content-type') || 'image/gif');
      res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
      res.setHeader('Access-Control-Allow-Origin', '*');
      res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
      res.status(200).send(Buffer.from(buffer));
      return;
    }

    res.status(404).json({ error: 'GIF not found in Firebase Storage' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch GIF', details: String(error) });
  }
};
