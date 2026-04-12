export default function Home() {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-app-gray-50 px-4">
      <div className="text-center max-w-lg">
        <h1 className="text-3xl font-bold text-app-gray-900 mb-3">Welcome</h1>

        <p className="text-app-gray-500 text-base mb-2">
          This is a boilerplate for building full-stack apps with
        </p>

        <div className="flex items-center justify-center gap-3 mb-8">
          <span className="px-3 py-1 rounded-full bg-primary-50 text-primary-700 text-sm font-medium border border-primary-200">
            Next.js
          </span>
          <span className="text-app-gray-300">+</span>
          <span className="px-3 py-1 rounded-full bg-app-gray-100 text-app-gray-700 text-sm font-medium border border-app-gray-200">
            AdonisJS
          </span>
        </div>

        <p className="text-app-gray-400 text-sm">
          Start by editing{' '}
          <code className="font-mono bg-app-gray-100 px-1.5 py-0.5 rounded text-app-gray-600 text-xs">
            apps/web/app/page.tsx
          </code>
        </p>
      </div>
    </div>
  );
}
