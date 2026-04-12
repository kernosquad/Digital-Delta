import axios from 'axios';

const HOST_HEADER = 'X-App-Host';

const NEXT_PUBLIC_API_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3333';
const API_URL = process.env.API_URL ?? 'http://localhost:3333';

const clientApi = axios.create({
  baseURL: NEXT_PUBLIC_API_URL,
  withCredentials: true,
});

function getCookie(name: string): string | null {
  const value = `; ${document.cookie}`;
  const parts = value.split(`; ${name}=`);
  if (parts.length === 2) {
    return decodeURIComponent(parts.pop()?.split(';').shift() ?? '');
  }
  return null;
}

const passThroughHeaders = ['host', 'user-agent', 'referer', 'x-forwarded-for', 'cf-connecting-ip'];

clientApi.interceptors.request.use(
  async function onFulfilled(config) {
    if (typeof window !== 'undefined') {
      // Client-side: send hostname so API can resolve the correct tenant/site
      config.headers[HOST_HEADER] = window.location.hostname;

      const xsrfToken = getCookie('XSRF-TOKEN');
      if (xsrfToken) {
        config.headers['X-XSRF-TOKEN'] = xsrfToken;
      }
    } else {
      // Server-side: use internal URL and forward relevant headers
      config.baseURL = API_URL;

      const { headers, cookies } = await import('next/headers');
      const headersList = await headers();

      const host = headersList.get('x-forwarded-host') ?? headersList.get('host');
      if (host) config.headers[HOST_HEADER] = host;

      for (const key of passThroughHeaders) {
        const value = headersList.get(key);
        if (value) config.headers[key] = value;
      }

      const cookieStore = await cookies();
      config.headers['cookie'] = cookieStore
        .getAll()
        .map((c) => `${c.name}=${c.value}`)
        .join('; ');

      const xsrfToken = cookieStore.get('XSRF-TOKEN')?.value;
      if (xsrfToken) {
        config.headers['X-XSRF-TOKEN'] = xsrfToken;
      }
    }

    return config;
  },
  (error) => Promise.reject(error)
);

export { clientApi };
