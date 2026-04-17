export default async function handler(req: any, res: any) {
  try {
    const { name, id, nameEn } = req.query;

    if (!name && !id) {
      return res.status(400).json({ error: 'Name or ID is required' });
    }

    const lookupNames = new Set<string>();
    const addNames = (val: any) => {
      if (!val) return;
      const s = String(val).trim();
      if (!s) return;
      lookupNames.add(s);
      lookupNames.add(s.toLowerCase());
      lookupNames.add(s.replace(/\s+/g, '_').toLowerCase());
      lookupNames.add(s.replace(/\s+/g, '-').toLowerCase());
      lookupNames.add(s.replace(/[\/\\]/g, ' ').replace(/\s+/g, ' ').trim()); 
    };

    addNames(name);
    addNames(id);
    addNames(nameEn);

    const folders = ['', 'exercises_gifs/', 'biblioteca de gif/', 'biblioteca de gifs/', 'gifs/'];
    const STORAGE_BASE_URL = 'https://firebasestorage.googleapis.com/v0/b/appcalculotreino-51f23.firebasestorage.app/o';

    for (const folder of folders) {
      for (const n of lookupNames) {
        const fileName = `${folder}${n}.gif`;
        const url = `${STORAGE_BASE_URL}/${encodeURIComponent(fileName)}?alt=media`;
        
        try {
          const response = await fetch(url, { method: 'HEAD' });
          if (response.ok) {
            // Redirecionamento é muito mais leve que processar o buffer
            res.setHeader('Cache-Control', 'public, max-age=3600');
            return res.redirect(307, url);
          }
        } catch (e) {
          continue;
        }
      }
    }

    return res.status(404).json({ 
      error: 'GIF not found', 
      tried: Array.from(lookupNames).slice(0, 5) 
    });

  } catch (error: any) {
    console.error('Proxy Error:', error);
    return res.status(500).json({ 
      error: 'Internal Server Error', 
      message: error.message,
      stack: error.stack?.split('\n')[0]
    });
  }
}
