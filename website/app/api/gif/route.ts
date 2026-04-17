import { NextRequest, NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

export async function GET(request: NextRequest) {
  const filename = request.nextUrl.searchParams.get('name');
  const exerciseId = request.nextUrl.searchParams.get('id');
  
  if (!filename) {
    return NextResponse.json({ error: 'Nome do exercício é obrigatório' }, { status: 400 });
  }

  const encodedName = decodeURIComponent(filename);
  const cleanName = encodedName.replace(/\.gif$/i, '').trim();
  const cleanId = exerciseId?.replace(/\.gif$/i, '').trim();

  const fileCandidates = [
    `${cleanName}.gif`,
    `exercises_gifs/${cleanName}.gif`,
    ...(cleanId ? [`${cleanId}.gif`, `exercises_gifs/${cleanId}.gif`] : []),
  ];

  try {
    for (const fileName of fileCandidates) {
      const firebaseUrl = `https://firebasestorage.googleapis.com/v0/b/appcalculotreino-51f23.firebasestorage.app/o/${encodeURIComponent(fileName)}?alt=media`;
      const response = await fetch(firebaseUrl);

      if (!response.ok) {
        continue;
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
    }

    return NextResponse.json({ error: 'GIF não encontrado' }, { status: 404 });
  } catch (error) {
    return NextResponse.json({ error: 'Erro ao buscar GIF' }, { status: 500 });
  }
}
