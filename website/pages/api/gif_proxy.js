export default async function handler(req, res) {
  try {
    const { name, id, nameEn } = req.query;
    if (!name && !id) return res.status(400).send('Missing params');

    const STORAGE_BASE_URL = 'https://firebasestorage.googleapis.com/v0/b/appcalculotreino-51f23.firebasestorage.app/o';
    const clean = (s) => String(s || '').trim().replace(/\s+/g, '_');
    
    // Lista de tentativas (Direto ao ponto)
    const candidates = [
      clean(name),
      clean(id),
      clean(nameEn),
      clean(name).toLowerCase(),
      clean(id).toLowerCase()
    ].filter(Boolean);

    const folders = ['exercises_gifs/', 'biblioteca de gif/', 'biblioteca de gifs/', 'gifs/', ''];

    for (const folder of folders) {
      for (const n of candidates) {
        const path = `${folder}${n}.gif`;
        const url = `${STORAGE_BASE_URL}/${encodeURIComponent(path)}?alt=media`;
        
        try {
          const check = await fetch(url, { method: 'GET' });
          if (check.ok) {
            return res.redirect(307, url);
          }
        } catch (e) {}
      }
    }

    // Se falhar tudo, tenta o chute final
    const finalUrl = `${STORAGE_BASE_URL}/${encodeURIComponent('exercises_gifs/' + clean(name || id) + '.gif')}?alt=media`;
    return res.redirect(307, finalUrl);

  } catch (err) {
    return res.status(500).send(err.message);
  }
}
