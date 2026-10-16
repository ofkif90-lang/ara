import './globals.css';
import type { Metadata } from 'next';
import { IBM_Plex_Sans_Arabic } from 'next/font/google';
import { AuthProvider } from '@/lib/auth-context';
import { Toaster } from '@/components/ui/toaster';
import { WhatsAppButton } from '@/components/whatsapp-button';
import { ScrollReveal } from '@/components/scroll-reveal';

const ibmPlex = IBM_Plex_Sans_Arabic({
  subsets: ['arabic', 'latin'],
  weight: ['300', '400', '500', '600', '700'],
  display: 'swap',
});

export const metadata: Metadata = {
  metadataBase: new URL('https://ara-world.com'),
  title: {
    default: 'ARA World | بيع وشراء العقارات في مصر - فلل، شقق، أراضي',
    template: '%s | ARA World',
  },
  description: 'ARA World منصة عقارية متكاملة لبيع وشراء الفلل والمنازل والشقق والأراضي في مصر. تصفح عقارات للبيع بأفضل الأسعار، اعرض عقارك للبيع مجاناً، تواصل مباشر مع البائعين.',
  keywords: [
    'بيع عقارات مصر',
    'شراء عقارات',
    'فلل للبيع',
    'شقق للبيع',
    'أراضي للبيع',
    'عقارات التجمع الخامس',
    'عقارات القاهرة الجديدة',
    'عقارات الإسكندرية',
    'عقارات 6 أكتوبر',
    'عقارات الشيخ زايد',
    'منازل للبيع',
    'عقارات للبيع في مصر',
    'بيع فيلا',
    'بيع شقة',
    'بيع أرض',
    'سوق العقارات المصري',
    'عقارات بأسعار مناسبة',
    'استثمار عقاري',
    'ARA World',
    'منصة عقارية',
    'إعلان عقار للبيع',
    'بيع عقارك',
  ],
  authors: [{ name: 'ARA World' }],
  creator: 'ARA World',
  publisher: 'ARA World',
  alternates: {
    canonical: '/',
  },
  openGraph: {
    title: 'ARA World | بيع وشراء العقارات في مصر - فلل، شقق، أراضي',
    description: 'منصة عقارية متكاملة لبيع وشراء الفلل والمنازل والشقق والأراضي في مصر بأفضل الأسعار. اعرض عقارك للبيع مجاناً.',
    type: 'website',
    locale: 'ar_EG',
    siteName: 'ARA World',
    url: 'https://ara-world.com',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'ARA World | بيع وشراء العقارات في مصر',
    description: 'منصة عقارية متكاملة لبيع وشراء العقارات في مصر - فلل، شقق، أراضي',
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-image-preview': 'large',
      'max-snippet': -1,
      'max-video-preview': -1,
    },
  },
  category: 'real estate',
};

const structuredData = {
  '@context': 'https://schema.org',
  '@type': 'RealEstateAgent',
  name: 'ARA World',
  description: 'منصة عقارية متكاملة لبيع وشراء العقارات في مصر',
  url: 'https://ara-world.com',
  areaServed: 'مصر',
  knowsLanguage: 'ar',
  knowsAbout: [
    'بيع العقارات',
    'شراء العقارات',
    'فلل للبيع',
    'شقق للبيع',
    'أراضي للبيع',
    'عقارات التجمع الخامس',
    'عقارات القاهرة الجديدة',
    'عقارات الإسكندرية',
    'عقارات 6 أكتوبر',
  ],
  sameAs: [],
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="ar" dir="rtl" suppressHydrationWarning>
      <head>
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(structuredData) }}
        />
      </head>
      <body className={ibmPlex.className}>
        <AuthProvider>
          <ScrollReveal />
          {children}
          <WhatsAppButton />
          <Toaster />
        </AuthProvider>
      </body>
    </html>
  );
}
