'use client';

import Link from 'next/link';
import { Phone, Mail, MessageCircle, MapPin, Clock } from 'lucide-react';
import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase/client';

export function Footer() {
  const [settings, setSettings] = useState<Record<string, string>>({});

  useEffect(() => {
    (async () => {
      const { data } = await supabase
        .from('site_settings')
        .select('setting_key, setting_value');
      if (data) {
        const map: Record<string, string> = {};
        data.forEach((s: any) => { if (s.setting_value) map[s.setting_key] = s.setting_value; });
        setSettings(map);
      }
    })();
  }, []);

  const phone = settings.phone_number ?? '+20 155 975 1754';
  const email = settings.contact_email ?? 'ofkif90@gmail.com';
  const whatsapp = settings.whatsapp_number ?? '+201559751754';
  const whatsappClean = whatsapp.replace(/[^0-9]/g, '');
  const workHours = settings.work_hours ?? 'السبت - الخميس: 9 ص - 6 م';
  const facebookUrl = settings.facebook_url ?? '';
  const instagramUrl = settings.instagram_url ?? '';
  const twitterUrl = settings.twitter_url ?? '';

  return (
    <footer className="bg-[#071A33] text-white">
      <div className="container mx-auto px-4 py-14">
        <div className="grid grid-cols-1 gap-10 md:grid-cols-2 lg:grid-cols-4">
          <div>
            <div className="mb-4">
              <span className="text-xl font-bold">ARA<span className="text-accent"> World</span></span>
            </div>
            <p className="text-sm text-white/60 leading-relaxed">
              منصة عقارية متكاملة لبيع وشراء الفلل والمنازل والشقق والأراضي في مصر. نربط البائعين بالمشترين بأمان وشفافية.
            </p>
          </div>

          <div>
            <h3 className="text-sm font-bold mb-4 text-white">روابط سريعة</h3>
            <ul className="space-y-2.5 text-sm text-white/60">
              <li><Link href="/" className="hover:text-accent transition-colors">الرئيسية</Link></li>
              <li><Link href="/buy" className="hover:text-accent transition-colors">شراء عقار</Link></li>
              <li><Link href="/sell" className="hover:text-accent transition-colors">بيع عقار</Link></li>
              <li><Link href="/favorites" className="hover:text-accent transition-colors">المفضلة</Link></li>
              <li><Link href="/contact" className="hover:text-accent transition-colors">تواصل معنا</Link></li>
            </ul>
          </div>

          <div>
            <h3 className="text-sm font-bold mb-4 text-white">معلومات قانونية</h3>
            <ul className="space-y-2.5 text-sm text-white/60">
              <li><Link href="/privacy" className="hover:text-accent transition-colors">سياسة الخصوصية</Link></li>
              <li><Link href="/terms" className="hover:text-accent transition-colors">الشروط والأحكام</Link></li>
              <li><Link href="/about" className="hover:text-accent transition-colors">من نحن</Link></li>
            </ul>
          </div>

          <div>
            <h3 className="text-sm font-bold mb-4 text-white">تواصل معنا</h3>
            <ul className="space-y-3 text-sm text-white/60">
              <li className="flex items-center gap-2">
                <Phone className="h-4 w-4 text-accent shrink-0" />
                <span>{phone}</span>
              </li>
              <li className="flex items-center gap-2">
                <Mail className="h-4 w-4 text-accent shrink-0" />
                <span>{email}</span>
              </li>
              <li className="flex items-center gap-2">
                <MapPin className="h-4 w-4 text-accent shrink-0" />
                <span>القاهرة، مصر</span>
              </li>
              <li className="flex items-center gap-2">
                <Clock className="h-4 w-4 text-accent shrink-0" />
                <span>{workHours}</span>
              </li>
              <li>
                <a
                  href={`https://wa.me/${whatsappClean}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-2 rounded-md border border-white/15 px-3 py-2 text-white transition-colors hover:border-accent hover:text-accent"
                >
                  <MessageCircle className="h-4 w-4" />
                  واتساب
                </a>
              </li>
            </ul>
          </div>
        </div>

        <div className="mt-10 border-t border-white/10 pt-6 text-center text-sm text-white/40">
          <p>
            ARA World هي منصة لعرض العقارات والتواصل بشأنها. ملكية العقار وحالته القانونية والعقود والمعاملات يجب التحقق منها بشكل مستقل.
          </p>
          <p className="mt-2">© 2005 ARA World. جميع الحقوق محفوظة.</p>
        </div>
      </div>
    </footer>
  );
}
