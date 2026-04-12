import { Geist, Geist_Mono } from 'next/font/google';

import type { Metadata } from 'next';
import './globals.css';

import AntdesignProvider from '@/providers/AntdesignProvider';
import ProgressProvider from '@/providers/ProgressProvider';
import TanstackProvider from '@/providers/TanstackProvider';

const geistSans = Geist({
  variable: '--font-geist-sans',
  subsets: ['latin'],
});

const geistMono = Geist_Mono({
  variable: '--font-geist-mono',
  subsets: ['latin'],
});

export const metadata: Metadata = {
  title: 'My App',
  description: 'Built with Next.js',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${geistSans.variable} ${geistMono.variable} h-full`}>
      <body className="min-h-full flex flex-col overflow-x-hidden bg-white antialiased">
        <ProgressProvider>
          <AntdesignProvider>
            <TanstackProvider>
              <main className="flex-1">{children}</main>
            </TanstackProvider>
          </AntdesignProvider>
        </ProgressProvider>
      </body>
    </html>
  );
}
