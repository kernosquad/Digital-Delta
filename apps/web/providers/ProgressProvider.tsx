'use client';

import { usePathname, useSearchParams } from 'next/navigation';
import NProgress from 'nprogress';
import { useEffect, useRef } from 'react';

NProgress.configure({
  minimum: 0.1,
  easing: 'ease',
  speed: 800,
  showSpinner: false,
  trickleSpeed: 100,
  trickle: true,
});

export default function ProgressProvider({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const navigationTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => {
    const handleClick = (event: MouseEvent) => {
      const target = event.target as HTMLElement;
      const link = target.closest('a[href]') as HTMLAnchorElement;

      if (link && link.href) {
        const url = new URL(link.href, window.location.origin);
        const currentUrl = new URL(window.location.href);

        if (url.origin === currentUrl.origin && url.pathname !== currentUrl.pathname) {
          if (navigationTimeoutRef.current) {
            clearTimeout(navigationTimeoutRef.current);
          }

          setTimeout(() => {
            NProgress.start();
            setTimeout(() => NProgress.set(0.4), 200);
            setTimeout(() => NProgress.set(0.7), 400);
          }, 50);

          navigationTimeoutRef.current = setTimeout(() => {
            NProgress.done();
          }, 5000);
        }
      }
    };

    document.addEventListener('click', handleClick, true);
    return () => document.removeEventListener('click', handleClick, true);
  }, []);

  useEffect(() => {
    if (navigationTimeoutRef.current) {
      clearTimeout(navigationTimeoutRef.current);
      navigationTimeoutRef.current = null;
    }

    const timer = setTimeout(() => NProgress.done(), 100);
    return () => clearTimeout(timer);
  }, [pathname, searchParams]);

  return (
    <>
      <style jsx global>{`
        #nprogress {
          pointer-events: none;
        }

        #nprogress .bar {
          background: linear-gradient(
            90deg,
            var(--color-primary-500) 0%,
            var(--color-primary-400) 30%,
            var(--color-primary-600) 70%,
            var(--color-primary-500) 100%
          );
          position: fixed;
          z-index: 99999;
          top: 0;
          left: 0;
          width: 100%;
          height: 4px;
          border-radius: 0 0 3px 3px;
          box-shadow: 0 2px 6px rgba(var(--color-primary-500-rgb), 0.4);
          animation: nprogress-pulse 1.2s ease-in-out infinite;
        }

        #nprogress .peg {
          display: block;
          position: absolute;
          right: 0;
          width: 150px;
          height: 100%;
          box-shadow:
            0 0 25px var(--color-primary-500),
            0 0 15px var(--color-primary-400),
            0 0 8px var(--color-primary-600);
          opacity: 1;
          transform: rotate(3deg) translate(0px, -4px);
          border-radius: 100px;
        }

        #nprogress .spinner {
          display: none;
        }

        #nprogress .bar::before {
          content: '';
          position: absolute;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          background: linear-gradient(
            90deg,
            transparent,
            rgba(255, 255, 255, 0.7),
            rgba(255, 255, 255, 0.9),
            rgba(255, 255, 255, 0.7),
            transparent
          );
          animation: nprogress-shimmer 1.8s infinite;
          border-radius: inherit;
        }

        @keyframes nprogress-pulse {
          0%,
          100% {
            opacity: 0.8;
            transform: scaleY(1);
          }
          50% {
            opacity: 1;
            transform: scaleY(1.5);
          }
        }

        @keyframes nprogress-shimmer {
          0% {
            background-position: -400px 0;
            opacity: 0.6;
          }
          50% {
            opacity: 1;
          }
          100% {
            background-position: calc(400px + 100%) 0;
            opacity: 0.6;
          }
        }

        @media (max-width: 768px) {
          #nprogress .bar {
            height: 3px;
          }
        }

        @media (prefers-reduced-motion: reduce) {
          #nprogress .bar,
          #nprogress .bar::before {
            animation: none;
          }
        }
      `}</style>
      {children}
    </>
  );
}
