import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'اعرض عقارك للبيع مجاناً',
  description: 'اعرض عقارك للبيع على ARA World مجاناً - فلل، شقق، أراضي، شاليهات. ارفع صور عقارك وحدد السعر وسيتم مراجعته ونشره على المنصة.',
  keywords: [
    'بيع عقار',
    'اعرض عقاري للبيع',
    'إعلان عقار للبيع',
    'بيع فيلا',
    'بيع شقة',
    'بيع أرض',
    'بيع قمر',
    'عرض عقار للبيع مجاناً',
    'نشر إعلان عقاري',
    'بيع العقارات في مصر',
  ],
  alternates: { canonical: '/sell' },
  openGraph: {
    title: 'اعرض عقارك للبيع مجاناً | ARA World',
    description: 'انشر إعلان عقارك للبيع مجاناً وصل لآلاف المشترين',
  },
};

export default function SellLayout({ children }: { children: React.ReactNode }) {
  return children;
}
