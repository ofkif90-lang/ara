'use client';

import Link from 'next/link';
import Image from 'next/image';
import { Heart, MapPin, BedDouble, Bath, Maximize, Eye, Layers, BadgeCheck } from 'lucide-react';
import { Property, PROPERTY_TYPE_LABELS } from '@/lib/types';
import { StatusBadge } from '@/components/status-badge';
import { useAuth } from '@/lib/auth-context';
import { supabase } from '@/lib/supabase/client';
import { useState } from 'react';
import { cn } from '@/lib/utils';

export function PropertyCard({ property, index = 0 }: { property: Property; index?: number }) {
  const { user } = useAuth();
  const [isFav, setIsFav] = useState(property.is_favorited ?? false);
  const [loading, setLoading] = useState(false);

  const mainImage = property.property_images?.find((img) => img.is_main) ?? property.property_images?.[0];
  const displayFields = property.display_fields ?? {};
  const isFieldVisible = (field: string) => displayFields[field] !== false;

  const toggleFavorite = async (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (!user) return;

    setLoading(true);
    try {
      if (isFav) {
        await supabase.from('favorites').delete().eq('user_id', user.id).eq('property_id', property.id);
        setIsFav(false);
      } else {
        await supabase.from('favorites').insert({ user_id: user.id, property_id: property.id });
        setIsFav(true);
      }
    } finally {
      setLoading(false);
    }
  };

  const formatPrice = (price: number) => {
    return new Intl.NumberFormat('ar-EG').format(price);
  };

  return (
    <Link
      href={`/property/${property.slug}`}
      className="group flex flex-col overflow-hidden rounded-lg border border-border bg-card transition-all duration-300 hover:border-primary/20"
    >
      <div className="relative img-zoom aspect-[4/3] sm:aspect-[4/3] overflow-hidden">
        {mainImage ? (
          <Image
            src={mainImage.image_url}
            alt={property.title}
            fill
            sizes="(max-width: 640px) 50vw, (max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
            className="object-cover"
          />
        ) : (
          <div className="flex h-full items-center justify-center bg-muted">
            <MapPin className="h-12 w-12 text-muted-foreground/30" />
          </div>
        )}

        <div className="absolute right-2 top-2 sm:right-3 sm:top-3 flex gap-1.5 sm:gap-2">
          <span className="rounded bg-white/95 px-1.5 py-0.5 sm:px-2.5 sm:py-1 text-[10px] sm:text-xs font-medium text-foreground">
            {PROPERTY_TYPE_LABELS[property.property_type]}
          </span>
          {property.approval_status === 'approved' && (
            <span className="hidden sm:flex items-center gap-1 rounded bg-accent px-2.5 py-1 text-xs font-medium text-white">
              <BadgeCheck className="h-3 w-3" />
              تمت المراجعة
            </span>
          )}
        </div>

        <div className="absolute left-2 top-2 sm:left-3 sm:top-3">
          <StatusBadge status={property.status} />
        </div>

        {user && (
          <button
            onClick={toggleFavorite}
            disabled={loading}
            className="absolute bottom-2 left-2 sm:bottom-3 sm:left-3 flex h-8 w-8 sm:h-9 sm:w-9 items-center justify-center rounded-full bg-black/30 transition-all hover:bg-black/50"
            aria-label="إضافة للمفضلة"
          >
            <Heart
              className={cn('h-3.5 w-3.5 sm:h-4 sm:w-4 transition-all', isFav ? 'fill-red-500 text-red-500' : 'text-white')}
            />
          </button>
        )}

        {property.discount_percentage && property.discount_percentage > 0 && (
          <div className="absolute bottom-2 right-2 sm:bottom-3 sm:right-3 rounded bg-destructive px-1.5 py-0.5 sm:px-2.5 sm:py-1 text-[10px] sm:text-xs font-bold text-white">
            خصم {property.discount_percentage}%
          </div>
        )}
      </div>

      <div className="flex flex-1 flex-col p-2.5 sm:p-4">
        <h3 className="line-clamp-1 text-sm sm:text-base font-bold text-foreground transition-colors group-hover:text-accent">
          {property.title}
        </h3>

        {isFieldVisible('location') && (property.city || property.location) && (
          <p className="mt-1 flex items-center gap-1 text-xs sm:text-sm text-muted-foreground">
            <MapPin className="h-3 w-3 sm:h-3.5 sm:w-3.5 shrink-0" />
            <span className="line-clamp-1">{property.city}{property.location ? ` - ${property.location}` : ''}</span>
          </p>
        )}

        <div className="mt-2 sm:mt-3 flex flex-wrap gap-2 sm:gap-3 text-[10px] sm:text-xs text-muted-foreground">
          {isFieldVisible('bedrooms') && property.bedrooms != null && (
            <span className="flex items-center gap-0.5">
              <BedDouble className="h-3 w-3 sm:h-3.5 sm:w-3.5" />
              {property.bedrooms}
            </span>
          )}
          {isFieldVisible('bathrooms') && property.bathrooms != null && (
            <span className="flex items-center gap-0.5">
              <Bath className="h-3 w-3 sm:h-3.5 sm:w-3.5" />
              {property.bathrooms}
            </span>
          )}
          {isFieldVisible('area') && property.area != null && (
            <span className="flex items-center gap-0.5">
              <Maximize className="h-3 w-3 sm:h-3.5 sm:w-3.5" />
              {property.area} م²
            </span>
          )}
          {isFieldVisible('floors') && property.floors != null && (
            <span className="flex items-center gap-0.5">
              <Layers className="h-3 w-3 sm:h-3.5 sm:w-3.5" />
              {property.floors}
            </span>
          )}
        </div>

        <div className="mt-auto pt-2 sm:pt-4 flex items-end justify-between border-t border-border/60">
          <div>
            {isFieldVisible('price') && <div className="flex items-baseline gap-1">
              <span className="text-sm sm:text-lg font-bold text-foreground">{formatPrice(property.price)}</span>
              <span className="text-[10px] sm:text-xs text-muted-foreground">ج.م</span>
            </div>}
            {isFieldVisible('price') && property.original_price && property.original_price > property.price && (
              <span className="text-[10px] sm:text-xs text-muted-foreground line-through">
                {formatPrice(property.original_price)}
              </span>
            )}
          </div>
          <span className="hidden sm:flex items-center gap-1 text-xs font-medium text-muted-foreground transition-colors group-hover:text-accent">
            <Eye className="h-3.5 w-3.5" />
            عرض
          </span>
        </div>
      </div>
    </Link>
  );
}
