import { NextRequest, NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const name = searchParams.get('name');
    const id = searchParams.get('id');
    const nameEn = searchParams.get('nameEn');

    if (!name && !id) {
      return NextResponse.json({ error: 'Missing name or id' }, { status: 400 });
    }

    const STORAGE_BASE_URL = 'https://firebasestorage.googleapis.com/v0/b/appcalculotreino-51f23.firebasestorage.app/o';
    
    const clean = (s: string | null) => {
      if (!s) return '';
      return s.trim().replace(/\s+/g, '_');
    };

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
          // Usamos um fetch simples para ver se o arquivo existe
          const check = await fetch(url, { method: 'GET', next: { revalidate: 0 } });
          if (check.ok) {
            return NextResponse.redirect(url, 307);
          }
        } catch (e) {}
      }
    }

    // Última tentativa: URL padrão chutada
    const fallbackUrl = `${STORAGE_BASE_URL}/${encodeURIComponent('exercises_gifs/' + clean(name || id) + '.gif')}?alt=media`;
    return NextResponse.redirect(fallbackUrl, 307);

  } catch (error: any) {
    return NextResponse.json({ error: 'Internal Error', message: error.message }, { status: 500 });
  }
}
