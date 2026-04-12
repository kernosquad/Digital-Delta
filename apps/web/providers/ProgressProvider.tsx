'use client';

import { usePathname } from 'next/navigation';
import NProgress from 'nprogress';
import { useEffect, useRef } from 'react';

NProgress.configure({
  minimum: 0.1,
  easing: 'ease',
  speed: 800,
  showSpinner: false,
  trickleSpeed: 200,
  trickle: true,
});

export default function ProgressProvider({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const timeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Detect link clicks and start progress bar
  useEffect(() => {
    const handleClick = (event: MouseEvent) => {
      const link = (event.target as HTMLElement).closest('a[href]') as HTMLAnchorElement | null;
      if (!link?.href) return;

      try {
        const dest = new URL(link.href, window.location.origin);
        if (dest.origin === window.location.origin && dest.pathname !== window.location.pathname) {
          NProgress.start();
          // Safety valve — always finish within 5s even if navigation stalls
          if (timeoutRef.current) clearTimeout(timeoutRef.current);
          timeoutRef.current = setTimeout(() => NProgress.done(), 5000);
        }
      } catch {
        // invalid href, ignore
      }
    };

    document.addEventListener('click', handleClick, true);
    return () => document.removeEventListener('click', handleClick, true);
  }, []);

  // Finish progress bar when pathname actually changes
  useEffect(() => {
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
      timeoutRef.current = null;
    }
    NProgress.done();
  }, [pathname]);

  return <>{children}</>;
}
