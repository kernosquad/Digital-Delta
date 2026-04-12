import { Geist, Geist_Mono } from 'next/font/google';

import type { Metadata } from 'next';
import AntDesignProvider from '../providers/AntDesignProvider';
import TanstackProvider from '../providers/TanstackProvider';
import './globals.css';

const geistSans = Geist({
  variable: '--font-geist-sans',
  subsets: ['latin'],
});

const geistMono = Geist_Mono({
  variable: '--font-geist-mono',
  subsets: ['latin'],
});

export const metadata: Metadata = {
  title: 'Digital Delta — Command Center',
  description: 'Resilient Logistics & Mesh Triage Engine for Disaster Response',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}>
      <body className="min-h-full flex flex-col">
        <AntDesignProvider>
          <TanstackProvider>{children}</TanstackProvider>
        </AntDesignProvider>
      </body>
    </html>
  );
}
