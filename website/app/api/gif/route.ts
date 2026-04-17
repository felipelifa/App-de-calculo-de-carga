import { NextRequest, NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

export async function GET(request: NextRequest) {
  const filename = request.nextUrl.searchParams.get('name');
  
  if (!filename) {
    return NextResponse.json({ error: 'Nome do exercício é obrigatório' }, { status: 400 });
  }

  const encodedName = decodeURIComponent(filename);
  const cleanName = encodedName.replace(/\.gif$/i, '');
  
  const firebaseUrl = `https://firebasestorage.googleapis.com/v0/b/appcalculotreino-51f23.firebasestorage.app/o/${encodeURIComponent(cleanName + '.gif')}?alt=media`;

  try {
    const response = await fetch(firebaseUrl);
    
    if (!response.ok) {
      return NextResponse.json({ error: 'GIF não encontrado' }, { status: 404 });
    }

    const imageBuffer = await response.arrayBuffer();
    const contentType = response.headers.get('content-type') || 'image/gif';

    return new NextResponse(Buffer.from(imageBuffer), {
      headers: {
        'Content-Type': contentType,
        'Access-Control-Allow-Origin': '*',
        'Cache-Control': 'public, max-age=3600',
      },
    });
  } catch (error) {
    return NextResponse.json({ error: 'Erro ao buscar GIF' }, { status: 500 });
  }
}