'use client';

import { Suspense, useEffect, useState, useCallback } from 'react';
import { useSearchParams, useRouter } from 'next/navigation';
import { Search, SlidersHorizontal, MapPin, Loader2, Grid, List, X } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Sheet, SheetContent, SheetTrigger, SheetHeader, SheetTitle } from '@/components/ui/sheet';
import { PropertyCard } from '@/components/property-card';
import { Property, PROPERTY_TYPE_LABELS, FINISHING_TYPE_LABELS, FinishingType } from '@/lib/types';
import { EGYPT_GOVERNORATES } from '@/lib/governorates';
import { supabase } from '@/lib/supabase/client';
import { Header } from '@/components/header';
import { Footer } from '@/components/footer';
import { EmptyState, ErrorState, LoadingSkeleton } from '@/components/states';
import { SearchX } from 'lucide-react';
import Link from 'next/link';
import { cn } from '@/lib/utils';

const PAGE_SIZE = 12;

function BuyPageContent() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const [properties, setProperties] = useState<Property[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);
  const [page, setPage] = useState(0);
  const [hasMore, setHasMore] = useState(true);
  const [totalCount, setTotalCount] = useState(0);
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');

  const [filters, setFilters] = useState({
    q: searchParams.get('q') ?? '',
    type: searchParams.get('type') ?? 'all',
    city: searchParams.get('city') ?? '',
    location: searchParams.get('location') ?? '',
    minPrice: searchParams.get('minPrice') ?? '',
    maxPrice: searchParams.get('maxPrice') ?? '',
    minArea: searchParams.get('minArea') ?? '',
    maxArea: searchParams.get('maxArea') ?? '',
    bedrooms: searchParams.get('bedrooms') ?? '',
    bathrooms: searchParams.get('bathrooms') ?? '',
    finishingType: searchParams.get('finishingType') ?? 'all',
    hasDiscount: searchParams.get('hasDiscount') ?? 'any',
    status: searchParams.get('status') ?? 'all',
    sort: searchParams.get('sort') ?? 'newest',
  });

  const fetchProperties = useCallback(async (pageNum: number, reset = false) => {
    setLoading(true);
    setError(false);

    try {
      let query = supabase
        .from('properties')
        .select(`*, property_images(*)`, { count: 'exact' })
        .eq('approval_status', 'approved')
        .not('published_at', 'is', null);

      if (filters.status !== 'all') {
        query = query.eq('status', filters.status);
      } else {
        query = query.in('status', ['available', 'reserved', 'sold']);
      }

      if (filters.q) {
        query = query.or(`title.ilike.%${filters.q}%,property_code.ilike.%${filters.q}%,city.ilike.%${filters.q}%,location.ilike.%${filters.q}%`);
      }
      if (filters.type !== 'all') query = query.eq('property_type', filters.type);
      if (filters.city) query = query.ilike('city', `%${filters.city}%`);
      if (filters.location) query = query.ilike('location', `%${filters.location}%`);
      if (filters.minPrice) query = query.gte('price', parseFloat(filters.minPrice));
      if (filters.maxPrice) query = query.lte('price', parseFloat(filters.maxPrice));
      if (filters.minArea) query = query.gte('area', parseFloat(filters.minArea));
      if (filters.maxArea) query = query.lte('area', parseFloat(filters.maxArea));
      if (filters.bedrooms) query = query.gte('bedrooms', parseInt(filters.bedrooms));
      if (filters.bathrooms) query = query.gte('bathrooms', parseInt(filters.bathrooms));
      if (filters.finishingType !== 'all') query = query.eq('finishing_type', filters.finishingType);
      if (filters.hasDiscount === 'yes') {
        query = query.not('discount_percentage', 'is', null).gt('discount_percentage', 0);
      }

      switch (filters.sort) {
        case 'price-low': query = query.order('price', { ascending: true }); break;
        case 'price-high': query = query.order('price', { ascending: false }); break;
        case 'area-large': query = query.order('area', { ascending: false, nullsFirst: false }); break;
        case 'oldest': query = query.order('published_at', { ascending: true }); break;
        default: query = query.order('published_at', { ascending: false });
      }

      query = query.range(pageNum * PAGE_SIZE, (pageNum + 1) * PAGE_SIZE - 1);
      const { data, count, error: queryError } = await query;

      if (queryError) { setError(true); setLoading(false); return; }

      setTotalCount(count ?? 0);
      if (reset) {
        setProperties((data as Property[]) ?? []);
      } else {
        setProperties((prev) => [...prev, ...((data as Property[]) ?? [])]);
      }
      setHasMore(((data as Property[]) ?? []).length === PAGE_SIZE);
    } catch {
      setError(true);
    } finally {
      setLoading(false);
    }
  }, [filters]);

  useEffect(() => {
    setPage(0);
    fetchProperties(0, true);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [fetchProperties]);

  const loadMore = () => {
    const next = page + 1;
    setPage(next);
    fetchProperties(next);
  };

  const applyFilters = () => {
    setPage(0);
    fetchProperties(0, true);
    const params = new URLSearchParams();
    Object.entries(filters).forEach(([k, v]) => {
      if (v && v !== 'all' && v !== 'newest' && v !== 'any') params.set(k, v);
    });
    router.replace(`/buy?${params.toString()}`);
  };

  const resetFilters = () => {
    setFilters({ q: '', type: 'all', city: '', location: '', minPrice: '', maxPrice: '', minArea: '', maxArea: '', bedrooms: '', bathrooms: '', finishingType: 'all', hasDiscount: 'any', status: 'all', sort: 'newest' });
    router.replace('/buy');
  };

  const FilterContent = () => (
    <div className="space-y-4">
      <div className="space-y-2">
        <Label>نوع العقار</Label>
        <Select value={filters.type} onValueChange={(v) => setFilters({ ...filters, type: v })}>
          <SelectTrigger><SelectValue /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">كل الأنواع</SelectItem>
            {Object.entries(PROPERTY_TYPE_LABELS).map(([value, label]) => (
              <SelectItem key={value} value={value}>{label}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div className="space-y-2">
        <Label>المحافظة</Label>
        <Select value={filters.city || 'all'} onValueChange={(v) => setFilters({ ...filters, city: v === 'all' ? '' : v })}>
          <SelectTrigger><SelectValue placeholder="كل المحافظات" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">كل المحافظات</SelectItem>
            {EGYPT_GOVERNORATES.map((gov) => (
              <SelectItem key={gov} value={gov}>{gov}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div className="space-y-2">
        <Label>المنطقة</Label>
        <Input placeholder="التجمع الخامس..." value={filters.location} onChange={(e) => setFilters({ ...filters, location: e.target.value })} />
      </div>

      <div className="grid grid-cols-2 gap-3">
        <div className="space-y-2">
          <Label>السعر من</Label>
          <Input type="number" placeholder="0" value={filters.minPrice} onChange={(e) => setFilters({ ...filters, minPrice: e.target.value })} />
        </div>
        <div className="space-y-2">
          <Label>السعر إلى</Label>
          <Input type="number" placeholder="∞" value={filters.maxPrice} onChange={(e) => setFilters({ ...filters, maxPrice: e.target.value })} />
        </div>
      </div>

      <div className="grid grid-cols-2 gap-3">
        <div className="space-y-2">
          <Label>المساحة من (م²)</Label>
          <Input type="number" placeholder="0" value={filters.minArea} onChange={(e) => setFilters({ ...filters, minArea: e.target.value })} />
        </div>
        <div className="space-y-2">
          <Label>المساحة إلى (م²)</Label>
          <Input type="number" placeholder="∞" value={filters.maxArea} onChange={(e) => setFilters({ ...filters, maxArea: e.target.value })} />
        </div>
      </div>

      <div className="grid grid-cols-2 gap-3">
        <div className="space-y-2">
          <Label>غرف نوم</Label>
          <Select value={filters.bedrooms || 'any'} onValueChange={(v) => setFilters({ ...filters, bedrooms: v === 'any' ? '' : v })}>
            <SelectTrigger><SelectValue /></SelectTrigger>
            <SelectContent>
              <SelectItem value="any">الكل</SelectItem>
              <SelectItem value="1">1+</SelectItem>
              <SelectItem value="2">2+</SelectItem>
              <SelectItem value="3">3+</SelectItem>
              <SelectItem value="4">4+</SelectItem>
              <SelectItem value="5">5+</SelectItem>
            </SelectContent>
          </Select>
        </div>
        <div className="space-y-2">
          <Label>حمامات</Label>
          <Select value={filters.bathrooms || 'any'} onValueChange={(v) => setFilters({ ...filters, bathrooms: v === 'any' ? '' : v })}>
            <SelectTrigger><SelectValue /></SelectTrigger>
            <SelectContent>
              <SelectItem value="any">الكل</SelectItem>
              <SelectItem value="1">1+</SelectItem>
              <SelectItem value="2">2+</SelectItem>
              <SelectItem value="3">3+</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>

      <div className="space-y-2">
        <Label>حالة التشطيب</Label>
        <Select value={filters.finishingType} onValueChange={(v) => setFilters({ ...filters, finishingType: v })}>
          <SelectTrigger><SelectValue /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">الكل</SelectItem>
            {Object.entries(FINISHING_TYPE_LABELS).map(([value, label]) => (
              <SelectItem key={value} value={value}>{label}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div className="space-y-2">
        <Label>حالة العقار</Label>
        <Select value={filters.status} onValueChange={(v) => setFilters({ ...filters, status: v })}>
          <SelectTrigger><SelectValue /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">الكل</SelectItem>
            <SelectItem value="available">متاح</SelectItem>
            <SelectItem value="reserved">محجوز</SelectItem>
            <SelectItem value="sold">تم البيع</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <div className="flex gap-2 pt-2">
        <Button onClick={applyFilters} className="flex-1 bg-primary hover:bg-primary/90">تطبيق</Button>
        <Button onClick={resetFilters} variant="outline">مسح</Button>
      </div>
    </div>
  );

  return (
    <div className="min-h-screen flex flex-col">
      <Header />
      <main className="flex-1 pt-20 lg:pt-24 pb-12">
        <div className="container mx-auto px-4">
          {/* Title + Count */}
          <div className="mb-5 reveal">
            <h1 className="text-2xl md:text-3xl font-bold mb-1">تصفح العقارات</h1>
            <p className="text-sm text-muted-foreground">
              {loading && totalCount === 0 ? 'جاري التحميل...' : `تم العثور على ${totalCount} عقار`}
            </p>
          </div>

          {/* Search + Sort bar */}
          <div className="flex gap-3 mb-6 reveal">
            <div className="relative flex-1">
              <Search className="absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="ابحث بالعنوان، رقم العقار، أو المحافظة..."
                value={filters.q}
                onChange={(e) => setFilters({ ...filters, q: e.target.value })}
                onKeyDown={(e) => e.key === 'Enter' && applyFilters()}
                className="pr-10 h-11"
              />
            </div>

            <Select value={filters.sort} onValueChange={(v) => { setFilters({ ...filters, sort: v }); }}>
              <SelectTrigger className="w-40 hidden md:flex h-11">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="newest">الأحدث</SelectItem>
                <SelectItem value="oldest">الأقدم</SelectItem>
                <SelectItem value="price-low">الأقل سعراً</SelectItem>
                <SelectItem value="price-high">الأعلى سعراً</SelectItem>
                <SelectItem value="area-large">الأكبر مساحة</SelectItem>
              </SelectContent>
            </Select>

            <div className="hidden md:flex items-center rounded-md border border-border">
              <button
                onClick={() => setViewMode('grid')}
                className={cn('p-2.5 transition-colors', viewMode === 'grid' ? 'bg-primary text-white' : 'text-muted-foreground hover:text-foreground')}
                aria-label="عرض شبكة"
              >
                <Grid className="h-4 w-4" />
              </button>
              <button
                onClick={() => setViewMode('list')}
                className={cn('p-2.5 transition-colors', viewMode === 'list' ? 'bg-primary text-white' : 'text-muted-foreground hover:text-foreground')}
                aria-label="عرض قائمة"
              >
                <List className="h-4 w-4" />
              </button>
            </div>

            <Sheet>
              <SheetTrigger asChild>
                <Button variant="outline" className="flex items-center gap-2 h-11">
                  <SlidersHorizontal className="h-4 w-4" />
                  <span className="hidden md:inline">فلاتر</span>
                </Button>
              </SheetTrigger>
              <SheetContent side="right" className="w-80 sm:w-96 overflow-y-auto">
                <SheetHeader className="mb-4">
                  <SheetTitle>تصفية العقارات</SheetTitle>
                </SheetHeader>
                <FilterContent />
              </SheetContent>
            </Sheet>
          </div>

          {/* Desktop sidebar + Results */}
          <div className="flex gap-6">
            <aside className="hidden lg:block w-64 shrink-0">
              <div className="sticky top-24 bg-card border border-border rounded-lg p-5">
                <h3 className="font-semibold mb-4">تصفية</h3>
                <FilterContent />
              </div>
            </aside>

            <div className="flex-1">
              {loading && properties.length === 0 ? (
                <div className="grid grid-cols-2 md:grid-cols-2 xl:grid-cols-3 gap-3 sm:gap-4 md:gap-6">
                  {[...Array(6)].map((_, i) => (
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
              ) : error ? (
                <ErrorState
                  title="حدث خطأ"
                  description="تعذر تحميل العقارات. يرجى المحاولة مرة أخرى."
                  action={<Button onClick={() => fetchProperties(0, true)}>إعادة المحاولة</Button>}
                />
              ) : properties.length === 0 ? (
                <EmptyState
                  icon={SearchX}
                  title="لا توجد نتائج"
                  description="لا توجد عقارات مطابقة لمعايير البحث. جرّب تعديل الفلاتر أو مسحها."
                  action={<Button onClick={resetFilters} variant="outline">مسح الفلاتر</Button>}
                />
              ) : (
                <>
                  <div className={cn(
                    'grid gap-3 sm:gap-4 md:gap-6',
                    viewMode === 'grid' ? 'grid-cols-2 md:grid-cols-2 xl:grid-cols-3' : 'grid-cols-1'
                  )}>
                    {properties.map((prop, i) => (
                      <PropertyCard key={prop.id} property={prop} index={i % 6} />
                    ))}
                  </div>

                  {hasMore && (
                    <div className="mt-8 text-center">
                      <Button onClick={loadMore} disabled={loading} variant="outline" size="lg">
                        {loading ? (
                          <><Loader2 className="h-4 w-4 ml-2 animate-spin" /> جاري التحميل...</>
                        ) : (
                          'تحميل المزيد'
                        )}
                      </Button>
                    </div>
                  )}
                </>
              )}
            </div>
          </div>
        </div>
      </main>
      <Footer />
    </div>
  );
}

export default function BuyPage() {
  return (
    <Suspense fallback={<div className="min-h-screen flex items-center justify-center"><Loader2 className="h-8 w-8 animate-spin text-primary" /></div>}>
      <BuyPageContent />
    </Suspense>
  );
}
