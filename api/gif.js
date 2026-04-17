// api/gif.js — Vercel Serverless Function (detectada automaticamente pela Vercel)
// Proxy de GIFs do Firebase Storage para evitar bloqueio de CORS no browser.
// A Vercel registra qualquer arquivo em /api/ como função serverless.

module.exports = async (req, res) => {
  const { name } = req.query;

  if (!name) {
    res.status(400).json({ error: 'Missing name parameter' });
    return;
  }

  try {
    const encodedFilename = encodeURIComponent(`${name}.gif`);
    const firebaseUrl = `https://firebasestorage.googleapis.com/v0/b/appcalculotreino-51f23.firebasestorage.app/o/${encodedFilename}?alt=media`;

    const response = await fetch(firebaseUrl);

    if (!response.ok) {
      res.status(response.status).json({ error: 'GIF not found in Firebase Storage' });
      return;
    }

    const buffer = await response.arrayBuffer();

    res.setHeader('Content-Type', 'image/gif');
    res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
    res.status(200).send(Buffer.from(buffer));
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch GIF', details: String(error) });
  }
};
