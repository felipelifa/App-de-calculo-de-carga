export default async function handler(req, res) {
  const { name, id, nameEn } = req.query;
  const STORAGE_BASE_URL = 'https://firebasestorage.googleapis.com/v0/b/appcalculotreino-51f23.firebasestorage.app/o';
  
  const clean = (s) => String(s || '').trim().replace(/\s+/g, '_');
  const candidates = [clean(name), clean(id), clean(nameEn), clean(name).toLowerCase(), clean(id).toLowerCase()].filter(Boolean);
  const folders = ['exercises_gifs/', 'biblioteca de gif/', 'biblioteca de gifs/', 'gifs/', ''];

  for (const folder of folders) {
    for (const n of candidates) {
      const url = `${STORAGE_BASE_URL}/${encodeURIComponent(folder + n + '.gif')}?alt=media`;
      try {
        const check = await fetch(url);
        if (check.ok) return res.redirect(307, url);
      } catch (e) {}
    }
  }
  return res.redirect(307, `${STORAGE_BASE_URL}/${encodeURIComponent('exercises_gifs/' + clean(name || id) + '.gif')}?alt=media`);
}
