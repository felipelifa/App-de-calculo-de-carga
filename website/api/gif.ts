const STORAGE_BASE_URL = 'https://firebasestorage.googleapis.com/v0/b/appcalculotreino-51f23.firebasestorage.app/o';

export default async function handler(req: any, res: any) {
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
    lookupNames.add(s.replace(/[\/\\]/g, ' ').trim()); 
  };

  addNames(name);
  addNames(id);
  addNames(nameEn);

  const folders = ['', 'exercises_gifs/', 'biblioteca de gif/', 'biblioteca de gifs/', 'gifs/'];
  
  for (const folder of folders) {
    for (const n of lookupNames) {
      const fileName = `${folder}${n}.gif`;
      const url = `${STORAGE_BASE_URL}/${encodeURIComponent(fileName)}?alt=media`;
      
      try {
        const response = await fetch(url);
        if (response.ok) {
          const buffer = await response.arrayBuffer();
          res.setHeader('Content-Type', 'image/gif');
          res.setHeader('Cache-Control', 'public, max-age=3600');
          res.setHeader('Access-Control-Allow-Origin', '*');
          return res.status(200).send(Buffer.from(buffer));
        }
      } catch (e) {
        continue;
      }
    }
  }

  return res.status(404).send('GIF not found');
}
