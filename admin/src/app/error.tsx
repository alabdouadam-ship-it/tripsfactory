'use client';

import { useT } from '@/lib/i18n';

export default function Error({
    error,
    reset,
}: {
    error: Error & { digest?: string };
    reset: () => void;
}) {
    // Log once per render; error boundaries typically render once so this avoids useEffect and duplicate-React issues in tests
    console.error(error);

    const t = useT();

    return (
        <div className="flex flex-col items-center justify-center min-h-screen bg-gray-50 p-4 text-center">
            <div className="bg-white p-8 rounded-2xl shadow-xl max-w-md w-full border border-gray-100">
                <div className="h-16 w-16 bg-red-50 rounded-full flex items-center justify-center mx-auto mb-6">
                    <svg className="h-8 w-8 text-red-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                    </svg>
                </div>
                <h2 className="text-2xl font-black text-gray-900 mb-2">
                    {t('error.title', 'Something went wrong')}
                </h2>
                <p className="text-sm text-gray-500 mb-6">
                    {t(
                        'error.description',
                        'An unexpected error occurred. Our team has been notified.',
                    )}
                </p>
                <div className="flex gap-3 justify-center">
                    <button
                        onClick={() => window.location.href = '/'}
                        className="px-4 py-2 rounded-xl text-sm font-bold border border-gray-200 text-gray-700 hover:bg-gray-50 transition"
                    >
                        {t('error.goHome', 'Go Home')}
                    </button>
                    <button
                        onClick={reset}
                        className="px-4 py-2 rounded-xl text-sm font-bold bg-blue-600 text-white hover:bg-blue-700 transition shadow-lg shadow-blue-600/20"
                    >
                        {t('error.tryAgain', 'Try Again')}
                    </button>
                </div>
                {process.env.NODE_ENV === 'development' && (
                    <div className="mt-8 p-4 bg-gray-900 rounded-lg text-left overflow-auto max-h-40">
                        <p className="text-xs font-mono text-red-400 mb-1">{error.name}: {error.message}</p>
                        <pre className="text-[0.625rem] font-mono text-gray-500">{error.stack}</pre>
                    </div>
                )}
            </div>
        </div>
    );
}
