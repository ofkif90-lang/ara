'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { Search, MapPin, ArrowLeft, Shield, BadgeCheck, FileSearch, ClipboardCheck, HelpCircle } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from '@/components/ui/accordion';
import { PropertyCard } from '@/components/property-card';
import { Property, PROPERTY_TYPE_LABELS } from '@/lib/types';
import { EGYPT_GOVERNORATES } from '@/lib/governorates';
import { supabase } from '@/lib/supabase/client';
import { LoadingSkeleton } from '@/components/states';
import { useRouter } from 'next/navigation';
import { Header } from '@/components/header';
import { Footer } from '@/components/footer';

const regions = [
  { name: 'القاهرة الجديدة', img: 'https://images.pexels.com/photos/16696093/pexels-photo-16696093.jpeg?auto=compress&cs=tinysrgb&w=600' },
  { name: 'الشيخ زايد', img: 'https://images.pexels.com/photos/34281362/pexels-photo-34281362.jpeg?auto=compress&cs=tinysrgb&w=600' },
  { name: '6 أكتوبر', img: 'https://images.pexels.com/photos/37703321/pexels-photo-37703321.jpeg?auto=compress&cs=tinysrgb&w=600' },
  { name: 'التجمع الخامس', img: 'https://images.pexels.com/photos/36592407/pexels-photo-36592407.jpeg?auto=compress&cs=tinysrgb&w=600' },
  { name: 'الإسكندرية', img: 'https://images.pexels.com/photos/27986581/pexels-photo-27986581.jpeg?auto=compress&cs=tinysrgb&w=600' },
  { name: 'الجيزة', img: 'https://images.pexels.com/photos/34852221/pexels-photo-34852221.jpeg?auto=compress&cs=tinysrgb&w=600' },
  { name: 'المنصورة', img: 'https://images.pexels.com/photos/35387571/pexels-photo-35387571.jpeg?auto=compress&cs=tinysrgb&w=600' },
  { name: 'طنطا', img: 'https://images.pexels.com/photos/35606050/pexels-photo-35606050.jpeg?auto=compress&cs=tinysrgb&w=600' },
  { name: 'المنيا', img: 'https://images.pexels.com/photos/17511632/pexels-photo-17511632.jpeg?auto=compress&cs=tinysrgb&w=600' },
  { name: 'أسيوط', img: 'https://images.pexels.com/photos/33161874/pexels-photo-33161874.jpeg?auto=compress&cs=tinysrgb&w=600' },
  { name: 'الأقصر', img: 'https://images.pexels.com/photos/36118881/pexels-photo-36118881.jpeg?auto=compress&cs=tinysrgb&w=600' },
  { name: 'أسوان', img: 'https://images.pexels.com/photos/20319058/pexels-photo-20319058.jpeg?auto=compress&cs=tinysrgb&w=600' },
  { name: 'الساحل الشمالي', img: 'https://images.pexels.com/photos/36221974/pexels-photo-36221974.jpeg?auto=compress&cs=tinysrgb&w=600' },
  { name: 'العين السخنة', img: 'https://images.pexels.com/photos/35372560/pexels-photo-35372560.jpeg?auto=compress&cs=tinysrgb&w=600' },
  { name: 'السويس', img: 'https://images.pexels.com/photos/34043392/pexels-photo-34043392.jpeg?auto=compress&cs=tinysrgb&w=600' },
];

const propertyTypes: { label: string; value: string; icon: string }[] = [
  { label: 'فلل', value: 'villa', icon: '🏠' },
  { label: 'شقق', value: 'apartment', icon: '🏢' },
  { label: 'أراضي', value: 'land', icon: '🌍' },
  { label: 'تجاري', value: 'commercial', icon: '🏬' },
];

const steps = [
  { num: 1, title: 'ابحث أو اعرض عقارك', desc: 'تصفح مئات العقارات أو اعرض عقارك للبيع مجاناً في دقائق.' },
  { num: 2, title: 'مراجعة واعتماد', desc: 'فريقنا يراجع كل إعلان للتأكد من صحة المعلومات قبل النشر.' },
  { num: 3, title: 'تواصل واتفق', desc: 'تواصل مباشرة مع البائع أو المشتري وأتمم صفقتك بأمان.' },
];

const faqs = [
  { q: 'هل التسجيل في المنصة مجاني؟', a: 'نعم، إنشاء حساب وعرض عقارك للبيع مجاني تماماً.' },
  { q: 'كم تستغرق مراجعة الإعلان؟', a: 'عادة يتمت مراجعة الإعلان ونشره خلال 24 ساعة من تقديمه.' },
  { q: 'هل أتحقق من ملكية العقار؟', a: 'ARA World منصة لعرض العقارات. يجب التحقق من ملكية العقار وحالته القانونية بشكل مستقل قبل أي معاملة.' },
  { q: 'كيف أتواصل مع البائع؟', a: 'يمكنك التواصل عبر نموذج طلب المعاينة أو واتساب مباشرة من صفحة العقار.' },
];

export default function HomePage() {
  const router = useRouter();
  const [properties, setProperties] = useState<Property[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchType, setSearchType] = useState<string>('all');
  const [searchCity, setSearchCity] = useState<string>('');
  const [searchPriceRange, setSearchPriceRange] = useState<string>('');
  const [stats, setStats] = useState<{ properties: string; clients: string; experience: string; secure: string }>({
    properties: '500+', clients: '1200+', experience: '15+', secure: '100%',
  });

  useEffect(() => {
    (async () => {
      const { data: propData } = await supabase
        .from('properties')
        .select(`*, property_images(*)`)
        .eq('approval_status', 'approved')
        .in('status', ['available', 'reserved', 'sold'])
        .not('published_at', 'is', null)
        .order('published_at', { ascending: false })
        .limit(8);
      setProperties((propData as Property[]) ?? []);
      setLoading(false);

      const { data: settingsData } = await supabase
        .from('site_settings')
        .select('setting_key, setting_value');
      if (settingsData) {
        const map: Record<string, string> = {};
        settingsData.forEach((s: any) => { if (s.setting_value) map[s.setting_key] = s.setting_value; });
        setStats({
          properties: map.stat_properties ?? '500+',
          clients: map.stat_clients ?? '1200+',
          experience: map.stat_experience ?? '15+',
          secure: map.stat_secure ?? '100%',
        });
      }
    })();
  }, []);

  const handleSearch = () => {
    const params = new URLSearchParams();
    if (searchType !== 'all') params.set('type', searchType);
    if (searchCity && searchCity !== 'all') params.set('city', searchCity);
    if (searchPriceRange) {
      const [min, max] = searchPriceRange.split('-');
      if (min) params.set('minPrice', min);
      if (max) params.set('maxPrice', max);
    }
    router.push(`/buy?${params.toString()}`);
  };

  const statsArray = [
    { value: stats.properties, label: 'عقار متاح' },
    { value: stats.clients, label: 'عميل' },
    { value: stats.experience, label: 'سنة خبرة' },
    { value: stats.secure, label: 'معاملات آمنة' },
  ];

  return (
    <div className="min-h-screen flex flex-col">
      <Header />

      {/* Hero */}
      <section className="relative flex min-h-[90vh] items-center overflow-hidden">
        <div className="absolute inset-0 z-0">
          <Image
            src="/properties/hero-bg.jpg"
            alt="عقارات في مصر"
            fill
            priority
            sizes="100vw"
            className="object-cover"
          />
          <div className="absolute inset-0 bg-primary/50" />
        </div>

        <div className="relative z-10 container mx-auto px-4 pt-28 pb-20">
          <div className="max-w-2xl animate-fade-in-up">
            <h1 className="text-3xl md:text-5xl font-bold text-white leading-tight mb-4">
              ابحث عن عقارك في مصر
            </h1>
            <p className="text-base md:text-lg text-white font-medium mb-8 leading-relaxed">
              فلل، شقق، أراضي، وعقارات تجارية في أرقى المناطق. اعرض عقارك للبيع أو تصفح مئات العقارات المعتمدة.
            </p>
          </div>

          {/* Search Box */}
          <div className="bg-white rounded-lg p-4 md:p-5 max-w-3xl mx-auto shadow-lg">
            <div className="grid grid-cols-1 md:grid-cols-12 gap-3">
              <div className="md:col-span-3">
                <Select value={searchType} onValueChange={setSearchType}>
                  <SelectTrigger className="h-11"><SelectValue placeholder="نوع العقار" /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">كل الأنواع</SelectItem>
                    {Object.entries(PROPERTY_TYPE_LABELS).map(([value, label]) => (
                      <SelectItem key={value} value={value}>{label}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="md:col-span-3">
                <Select value={searchCity} onValueChange={setSearchCity}>
                  <SelectTrigger className="h-11"><SelectValue placeholder="المحافظة" /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">كل المحافظات</SelectItem>
                    {EGYPT_GOVERNORATES.map((gov) => (
                      <SelectItem key={gov} value={gov}>{gov}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="md:col-span-4">
                <Select value={searchPriceRange} onValueChange={setSearchPriceRange}>
                  <SelectTrigger className="h-11"><SelectValue placeholder="السعر أو المبلغ" /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">كل الأسعار</SelectItem>
                    <SelectItem value="0-200000">0 - 200,000 ج.م</SelectItem>
                    <SelectItem value="200000-500000">200,000 - 500,000 ج.م</SelectItem>
                    <SelectItem value="500000-1000000">500,000 - 1,000,000 ج.م</SelectItem>
                    <SelectItem value="1000000-1500000">1,000,000 - 1,500,000 ج.م</SelectItem>
                    <SelectItem value="1500000-">+1,500,000 ج.م</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="md:col-span-2">
                <Button onClick={handleSearch} className="h-11 w-full bg-accent text-white hover:bg-accent/90">
                  <Search className="h-4 w-4 ml-2" />
                  بحث
                </Button>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Featured Properties */}
      <section className="py-16 bg-secondary/40">
        <div className="container mx-auto px-4">
          <div className="flex items-end justify-between mb-8 reveal">
            <div>
              <h2 className="text-2xl md:text-3xl font-bold text-foreground">عقارات مختارة</h2>
              <p className="text-muted-foreground mt-1">أحدث العقارات المعتمدة على المنصة</p>
            </div>
            <Button asChild variant="ghost" className="hidden md:flex">
              <Link href="/buy">
                عرض الكل
                <ArrowLeft className="h-4 w-4 mr-2" />
              </Link>
            </Button>
          </div>

          {loading ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
              {[...Array(4)].map((_, i) => (
                <div key={i} className="rounded-lg border border-border overflow-hidden">
                  <LoadingSkeleton className="aspect-[4/3] rounded-none" />
                  <div className="p-4 space-y-3">
                    <LoadingSkeleton className="h-5 w-3/4" />
                    <LoadingSkeleton className="h-4 w-1/2" />
                    <LoadingSkeleton className="h-8 w-1/3" />
                  </div>
                </div>
              ))}
            </div>
          ) : properties.length > 0 ? (
            <>
              <div className="grid grid-cols-2 md:grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4 md:gap-6">
                {properties.map((prop, i) => (
                  <PropertyCard key={prop.id} property={prop} index={i} />
                ))}
              </div>
              <div className="mt-10 text-center reveal">
                <Button asChild size="lg" className="bg-primary hover:bg-primary/90">
                  <Link href="/buy">
                    تصفح كل العقارات
                    <ArrowLeft className="h-4 w-4 mr-2" />
                  </Link>
                </Button>
              </div>
            </>
          ) : (
            <p className="text-center text-muted-foreground py-12">لا توجد عقارات متاحة حالياً</p>
          )}
        </div>
      </section>

      {/* Browse by Region */}
      <section className="py-16 bg-white">
        <div className="container mx-auto px-4">
          <h2 className="text-2xl md:text-3xl font-bold text-foreground mb-8 reveal">تصفح حسب المنطقة</h2>
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-4 mb-4">
            {regions.map((region, i) => (
              <Link
                key={region.name}
                href={`/buy?city=${encodeURIComponent(region.name)}`}
                className="reveal group relative aspect-[4/5] rounded-lg overflow-hidden border border-border"
                style={{ transitionDelay: `${i * 60}ms` }}
              >
                <Image
                  src={region.img}
                  alt={region.name}
                  fill
                  sizes="(max-width: 768px) 50vw, 20vw"
                  className="object-cover transition-transform duration-500 group-hover:scale-105"
                />
                <div className="absolute inset-0 bg-primary/40 transition-colors group-hover:bg-primary/30" />
                <div className="absolute bottom-0 right-0 left-0 p-3">
                  <p className="text-sm font-semibold text-white">{region.name}</p>
                </div>
              </Link>
            ))}
          </div>
        </div>
      </section>

      {/* Browse by Type */}
      <section className="py-16 bg-secondary/40">
        <div className="container mx-auto px-4">
          <h2 className="text-2xl md:text-3xl font-bold text-foreground mb-8 reveal">تصفح حسب النوع</h2>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {propertyTypes.map((type, i) => (
              <Link
                key={type.value}
                href={`/buy?type=${type.value}`}
                className="reveal group rounded-lg border border-border bg-card p-6 text-center transition-all hover:border-accent/40"
                style={{ transitionDelay: `${i * 60}ms` }}
              >
                <p className="text-2xl font-bold text-foreground group-hover:text-accent transition-colors">{type.label}</p>
                <p className="text-sm text-muted-foreground mt-1">عقارات {type.label}</p>
              </Link>
            ))}
          </div>
        </div>
      </section>

      {/* How It Works */}
      <section className="py-16 bg-white border-y border-border">
        <div className="container mx-auto px-4">
          <h2 className="text-2xl md:text-3xl font-bold text-foreground mb-10 reveal text-center">إزاي تشتغل المنصة</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 max-w-4xl mx-auto">
            {steps.map((step, i) => (
              <div key={step.num} className="reveal text-center" style={{ transitionDelay: `${i * 80}ms` }}>
                <div className="text-5xl font-bold text-accent/20 mb-3">{step.num}</div>
                <h3 className="text-lg font-bold mb-2">{step.title}</h3>
                <p className="text-sm text-muted-foreground leading-relaxed">{step.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* FAQ */}
      <section className="py-16 bg-secondary/40">
        <div className="container mx-auto px-4 max-w-3xl">
          <h2 className="text-2xl md:text-3xl font-bold text-foreground mb-8 reveal text-center">أسئلة شائعة</h2>
          <Accordion type="single" collapsible className="space-y-3">
            {faqs.map((faq, i) => (
              <AccordionItem key={i} value={`item-${i}`} className="rounded-lg border border-border bg-card px-4">
                <AccordionTrigger className="text-right font-medium hover:no-underline">
                  {faq.q}
                </AccordionTrigger>
                <AccordionContent className="text-muted-foreground text-sm leading-relaxed">
                  {faq.a}
                </AccordionContent>
              </AccordionItem>
            ))}
          </Accordion>
        </div>
      </section>

      {/* CTA */}
      <section className="py-16 bg-white">
        <div className="container mx-auto px-4">
          <div className="rounded-lg border border-border bg-primary p-10 md:p-14 text-center reveal-scale">
            <h2 className="text-2xl md:text-4xl font-bold text-white mb-3">جاهز تبيع عقارك؟</h2>
            <p className="text-white/70 mb-6 max-w-xl mx-auto">
              اعرض عقارك على آلاف المشترين المحتملين. عملية بسيطة وآمنة مع مراجعة احترافية.
            </p>
            <Button asChild size="lg" className="bg-accent text-white hover:bg-accent/90 h-12 px-10">
              <Link href="/sell">
                ابدأ البيع الآن
              </Link>
            </Button>
          </div>
        </div>
      </section>

      {/* Stats */}
      <section className="py-14 bg-white border-t border-border">
        <div className="container mx-auto px-4">
          <div className="grid grid-cols-2 md:grid-cols-4 divide-x divide-x-reverse divide-border">
            {statsArray.map((stat, i) => (
              <div key={i} className="reveal text-center px-4">
                <div className="text-3xl md:text-4xl font-bold text-foreground">{stat.value}</div>
                <div className="text-sm text-muted-foreground mt-1">{stat.label}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      <Footer />
    </div>
  );
}
