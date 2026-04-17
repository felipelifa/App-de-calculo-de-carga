import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  const filename = request.nextUrl.searchParams.get('name');
  
  if (!filename) {
    return NextResponse.json({ error: 'Missing name parameter' }, { status: 400 });
  }

  try {
    const encodedFilename = encodeURIComponent(`${filename}.gif`);
    const firebaseUrl = `https://firebasestorage.googleapis.com/v0/b/appcalculotreino-51f23.firebasestorage.app/o/${encodedFilename}?alt=media`;

    const response = await fetch(firebaseUrl);
    
    if (!response.ok) {
      return NextResponse.json({ error: 'GIF not found' }, { status: response.status });
    }

    const buffer = await response.arrayBuffer();
    
    return new NextResponse(buffer, {
      status: 200,
      headers: {
        'Content-Type': 'image/gif',
        'Cache-Control': 'public, max-age=31536000',
        'Access-Control-Allow-Origin': '*',
      },
    });
  } catch (error) {
    return NextResponse.json({ error: 'Failed to fetch GIF' }, { status: 500 });
  }
}
