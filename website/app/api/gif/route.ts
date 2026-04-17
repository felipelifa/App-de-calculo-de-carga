import { NextRequest, NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

const STORAGE_BASE_URL = 'https://firebasestorage.googleapis.com/v0/b/appcalculotreino-51f23.firebasestorage.app/o';
const STORAGE_CACHE_TTL_MS = 60 * 60 * 1000;

let storageNamesCache: { value: string[]; expiresAt: number } | null = null;

const safeDecode = (value: string) => {
  try {
    return decodeURIComponent(value);
  } catch {
    return value;
  }
};

const stripGifExtension = (value: string) => value.replace(/\.gif$/i, '').trim();

const normalizeMatchKey = (value: string) => {
  // Ignorar o prefixo de pasta ao comparar nomes no storage
  const parts = value.split('/');
  const filename = parts[parts.length - 1];
  return stripGifExtension(filename)
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    // NÃO substituir underscores/hífens - manter estrutura para comparação
    .replace(/\s+/g, ' ')
    .trim()
    .toLowerCase();
};

const toTitleCase = (value: string) =>
  value
    .split(' ')
    .filter(Boolean)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1).toLowerCase())
    .join(' ');

const buildNameVariants = (baseName: string) => {
  const clean = stripGifExtension(safeDecode(baseName));
  const variants = new Set<string>();

  if (!clean) {
    return [];
  }

  variants.add(clean);
  variants.add(clean.toLowerCase());
  variants.add(clean.charAt(0).toUpperCase() + clean.slice(1));
  variants.add(toTitleCase(clean));

  const compactSpacing = clean.replace(/\s+/g, ' ').trim();
  variants.add(compactSpacing.replace(/\s/g, '_'));
  variants.add(compactSpacing.replace(/\s/g, '-'));

  return [...variants].filter(Boolean);
};

const getStorageFileCandidates = (names: string[]) => {
  const candidates = new Set<string>();

  for (const name of names) {
    const withExtension = `${name}.gif`;
    candidates.add(withExtension);
    candidates.add(`exercises_gifs/${withExtension}`);
    candidates.add(`biblioteca de gif/${withExtension}`);
    candidates.add(`biblioteca de gifs/${withExtension}`);
    candidates.add(`gifs/${withExtension}`);
  }

  return [...candidates];
};

const fetchStorageNames = async () => {
  if (storageNamesCache && storageNamesCache.expiresAt > Date.now()) {
    return storageNamesCache.value;
  }

  const names: string[] = [];
  const maxAttempts = 3;
  let attempt = 0;

  while (attempt < maxAttempts) {
    attempt++;
    const listUrl = `${STORAGE_BASE_URL}?maxResults=1000`;
    
    try {
      const response = await fetch(listUrl, { 
        next: { revalidate: 3600 },
        signal: AbortSignal.timeout(8000)
      });

      if (!response.ok) {
        if (attempt >= maxAttempts) {
          throw new Error(`Storage list failed with status ${response.status}`);
        }
        await new Promise(r => setTimeout(r, 500));
        continue;
      }

      const payload = (await response.json()) as {
        items?: { name?: string }[];
        nextPageToken?: string;
      };

      for (const item of payload.items ?? []) {
        if (item.name) {
          names.push(item.name);
        }
      }

      break;
    } catch (err) {
      if (attempt >= maxAttempts) {
        throw err;
      }
      await new Promise(r => setTimeout(r, 500));
    }
  }

  storageNamesCache = {
    value: names,
    expiresAt: Date.now() + STORAGE_CACHE_TTL_MS,
  };

  return names;
};

const findBestStorageMatch = async (requestedNames: string[]) => {
  const requestedKeys = new Set(requestedNames.map(normalizeMatchKey));

  if (requestedKeys.size === 0) {
    return null;
  }

  const allNames = await fetchStorageNames();

  for (const name of allNames) {
    if (requestedKeys.has(normalizeMatchKey(name))) {
      return name;
    }
  }

  return null;
};

const fetchGifFromStorage = async (fileName: string) => {
  const fileUrl = `${STORAGE_BASE_URL}/${encodeURIComponent(fileName)}?alt=media`;
  const response = await fetch(fileUrl);

  if (!response.ok) {
    return null;
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
};

export async function GET(request: NextRequest) {
  const filename = request.nextUrl.searchParams.get('name');
  const nameEn = request.nextUrl.searchParams.get('nameEn');
  const exerciseId = request.nextUrl.searchParams.get('id');
  
  if (!filename && !exerciseId) {
    return NextResponse.json({ error: 'Nome ou ID do exercício é obrigatório' }, { status: 400 });
  }

  const nameVariants = filename ? buildNameVariants(filename) : [];
  const nameEnVariants = nameEn ? buildNameVariants(nameEn) : [];
  const idVariants = exerciseId ? buildNameVariants(exerciseId) : [];

  const lookupNames = [...new Set([...nameVariants, ...nameEnVariants, ...idVariants])];
  const fileCandidates = getStorageFileCandidates(lookupNames);

  try {
    for (const fileName of fileCandidates) {
      const result = await fetchGifFromStorage(fileName);
      if (result) {
        return result;
      }
    }

    const bestMatch = await findBestStorageMatch(lookupNames);
    if (bestMatch) {
      const result = await fetchGifFromStorage(bestMatch);
      if (result) {
        return result;
      }
    }

    const placeholderSvg = `<svg xmlns="http://www.w3.org/2000/svg" width="300" height="200" viewBox="0 0 300 200">
      <rect fill="#2a2a2a" width="300" height="200"/>
      <text fill="#666" font-family="Arial" font-size="14" x="50%" y="50%" text-anchor="middle" dominant-baseline="middle">Imagem não disponível</text>
    </svg>`;

    return new NextResponse(placeholderSvg, {
      headers: {
        'Content-Type': 'image/svg+xml',
        'Cache-Control': 'no-store',
      },
    });
  } catch {
    return NextResponse.json({ error: 'Erro ao buscar GIF' }, { status: 500 });
  }
}
