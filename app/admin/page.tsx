'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import {
  Building2, Users, FileText, MessageSquare, TrendingUp,
  CheckCircle2, XCircle, Clock, Home, ArrowLeft, Activity, Eye, DollarSign,
  Calendar, ChevronRight, X
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { supabase } from '@/lib/supabase/client';
import { useAuth } from '@/lib/auth-context';
import { Profile, Property, ContactMessage, ActivityLog } from '@/lib/types';
import { ApprovalBadge, StatusBadge } from '@/components/status-badge';
import { PROPERTY_TYPE_LABELS } from '@/lib/types';

interface MonthlySnapshot {
  id: string;
  month: string;
  year: number;
  total_users: number;
  total_properties: number;
  published_properties: number;
  sold_properties: number;
  reserved_properties: number;
  pending_requests: number;
  total_inquiries: number;
  total_leads: number;
  closed_deals: number;
  active_deals: number;
  total_commission: number;
  new_users_this_month: number;
  new_properties_this_month: number;
  new_deals_this_month: number;
  commission_this_month: number;
  created_at: string;
}

export default function AdminDashboard() {
  const { profile } = useAuth();
  const [stats, setStats] = useState({
    totalUsers: 0,
    totalProperties: 0,
    publishedProperties: 0,
    pendingRequests: 0,
    rejectedRequests: 0,
    soldProperties: 0,
    reservedProperties: 0,
    totalInquiries: 0,
    totalLeads: 0,
    newLeads: 0,
    totalDeals: 0,
    closedDeals: 0,
    activeDeals: 0,
    totalCommission: 0,
  });
  const [recentProperties, setRecentProperties] = useState<Property[]>([]);
  const [recentUsers, setRecentUsers] = useState<Profile[]>([]);
  const [recentMessages, setRecentMessages] = useState<ContactMessage[]>([]);
  const [activityLog, setActivityLog] = useState<ActivityLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [snapshots, setSnapshots] = useState<MonthlySnapshot[]>([]);
  const [selectedStat, setSelectedStat] = useState<string | null>(null);
  const [showHistory, setShowHistory] = useState(false);

  useEffect(() => {
    (async () => {
      const [users, props, pending, rejected, sold, reserved, inquiries, recentProps, recentUsrs, recentMsgs, activity, leadsCount, newLeadsCount, dealsCount, closedDealsCount, activeDealsCount, commissionSum, snapshotsData] = await Promise.all([
        supabase.from('profiles').select('id', { count: 'exact', head: true }),
        supabase.from('properties').select('id', { count: 'exact', head: true }),
        supabase.from('sell_requests').select('id', { count: 'exact', head: true }).eq('status', 'pending'),
        supabase.from('properties').select('id', { count: 'exact', head: true }).eq('approval_status', 'rejected'),
        supabase.from('properties').select('id', { count: 'exact', head: true }).eq('status', 'sold'),
        supabase.from('properties').select('id', { count: 'exact', head: true }).eq('status', 'reserved'),
        supabase.from('inquiries').select('id', { count: 'exact', head: true }),
        supabase.from('properties').select('*, property_images(*)').order('created_at', { ascending: false }).limit(5),
        supabase.from('profiles').select('*').order('created_at', { ascending: false }).limit(5),
        supabase.from('contact_messages').select('*').order('created_at', { ascending: false }).limit(5),
        supabase.from('activity_log').select('*, admin:profiles!activity_log_admin_id_fkey(full_name, username)').order('created_at', { ascending: false }).limit(10),
        supabase.from('property_leads').select('id', { count: 'exact', head: true }),
        supabase.from('property_leads').select('id', { count: 'exact', head: true }).eq('status', 'new'),
        supabase.from('deals').select('id', { count: 'exact', head: true }),
        supabase.from('deals').select('id', { count: 'exact', head: true }).eq('status', 'deal_closed'),
        supabase.from('deals').select('id', { count: 'exact', head: true }).in('status', ['new_lead', 'viewing_scheduled', 'negotiating']),
        supabase.from('deals').select('commission_amount').eq('status', 'deal_closed'),
        supabase.from('monthly_stats_snapshots').select('*').order('created_at', { ascending: false }).limit(12),
      ]);

      const published = await supabase.from('properties').select('id', { count: 'exact', head: true }).eq('approval_status', 'approved').not('published_at', 'is', null);

      const totalCommission = (commissionSum.data as { commission_amount: number | null }[] ?? []).reduce((sum, d) => sum + (d.commission_amount ?? 0), 0);

      setStats({
        totalUsers: users.count ?? 0,
        totalProperties: props.count ?? 0,
        publishedProperties: published.count ?? 0,
        pendingRequests: pending.count ?? 0,
        rejectedRequests: rejected.count ?? 0,
        soldProperties: sold.count ?? 0,
        reservedProperties: reserved.count ?? 0,
        totalInquiries: inquiries.count ?? 0,
        totalLeads: leadsCount.count ?? 0,
        newLeads: newLeadsCount.count ?? 0,
        totalDeals: dealsCount.count ?? 0,
        closedDeals: closedDealsCount.count ?? 0,
        activeDeals: activeDealsCount.count ?? 0,
        totalCommission,
      });
      setRecentProperties((recentProps.data as Property[]) ?? []);
      setRecentUsers((recentUsrs.data as Profile[]) ?? []);
      setRecentMessages((recentMsgs.data as ContactMessage[]) ?? []);
      setActivityLog((activity.data as ActivityLog[]) ?? []);
      setSnapshots((snapshotsData.data as MonthlySnapshot[]) ?? []);
      setLoading(false);
    })();
  }, []);

  const statCards = [
    { key: 'totalUsers', label: 'إجمالي المستخدمين', value: stats.totalUsers, icon: Users, color: 'text-blue-500', bg: 'bg-blue-500/10', historyField: 'total_users' as const, newField: 'new_users_this_month' as const, newLabel: 'مستخدمين جدد' },
    { key: 'totalProperties', label: 'إجمالي العقارات', value: stats.totalProperties, icon: Building2, color: 'text-primary', bg: 'bg-primary/10', historyField: 'total_properties' as const, newField: 'new_properties_this_month' as const, newLabel: 'عقارات جديدة' },
    { key: 'publishedProperties', label: 'عقارات منشورة', value: stats.publishedProperties, icon: CheckCircle2, color: 'text-emerald-500', bg: 'bg-emerald-500/10', historyField: 'published_properties' as const, newField: null, newLabel: '' },
    { key: 'newLeads', label: 'طلبات معاينة جديدة', value: stats.newLeads, icon: Eye, color: 'text-cyan-500', bg: 'bg-cyan-500/10', historyField: 'total_leads' as const, newField: null, newLabel: '' },
    { key: 'totalLeads', label: 'إجمالي طلبات المعاينة', value: stats.totalLeads, icon: FileText, color: 'text-indigo-500', bg: 'bg-indigo-500/10', historyField: 'total_leads' as const, newField: null, newLabel: '' },
    { key: 'activeDeals', label: 'صفقات نشطة', value: stats.activeDeals, icon: TrendingUp, color: 'text-amber-500', bg: 'bg-amber-500/10', historyField: 'active_deals' as const, newField: 'new_deals_this_month' as const, newLabel: 'صفقات جديدة' },
    { key: 'closedDeals', label: 'صفقات مغلقة', value: stats.closedDeals, icon: CheckCircle2, color: 'text-green-500', bg: 'bg-green-500/10', historyField: 'closed_deals' as const, newField: null, newLabel: '' },
    { key: 'totalCommission', label: 'إجمالي العمولات', value: `${new Intl.NumberFormat('ar-EG').format(stats.totalCommission)} ج.م`, icon: DollarSign, color: 'text-primary', bg: 'bg-primary/10', historyField: 'total_commission' as const, newField: 'commission_this_month' as const, newLabel: 'عمولات هذا الشهر' },
    { key: 'pendingRequests', label: 'طلبات قيد المراجعة', value: stats.pendingRequests, icon: Clock, color: 'text-amber-500', bg: 'bg-amber-500/10', historyField: 'pending_requests' as const, newField: null, newLabel: '' },
    { key: 'soldProperties', label: 'عقارات مباعة', value: stats.soldProperties, icon: Home, color: 'text-blue-500', bg: 'bg-blue-500/10', historyField: 'sold_properties' as const, newField: null, newLabel: '' },
    { key: 'reservedProperties', label: 'عقارات محجوزة', value: stats.reservedProperties, icon: FileText, color: 'text-orange-500', bg: 'bg-orange-500/10', historyField: 'reserved_properties' as const, newField: null, newLabel: '' },
    { key: 'totalInquiries', label: 'إجمالي الاستفسارات', value: stats.totalInquiries, icon: MessageSquare, color: 'text-cyan-500', bg: 'bg-cyan-500/10', historyField: 'total_inquiries' as const, newField: null, newLabel: '' },
  ];

  const selectedStatData = statCards.find((s) => s.key === selectedStat);

  const getHistoryForStat = (statKey: string) => {
    const stat = statCards.find((s) => s.key === statKey);
    if (!stat || !stat.historyField) return [];
    return snapshots.map((snap) => ({
      month: snap.month,
      year: snap.year,
      value: snap[stat.historyField] as number,
      newValue: stat.newField ? (snap[stat.newField] as number) : null,
      newLabel: stat.newLabel,
    }));
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-20">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h2 className="text-2xl font-bold mb-1">مرحباً، {profile?.full_name}</h2>
          <p className="text-muted-foreground">إليك نظرة عامة على منصة ARA World</p>
        </div>
        <Button
          variant="outline"
          onClick={() => setShowHistory(true)}
          className="flex items-center gap-2"
        >
          <Calendar className="h-4 w-4" />
          سجل الإحصائيات الشهري
        </Button>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {statCards.map((stat, i) => (
          <Card
            key={i}
            className="cursor-pointer hover:shadow-md hover:border-primary/30 transition-all"
            style={{ transitionDelay: `${i * 50}ms` }}
            onClick={() => { setSelectedStat(stat.key); setShowHistory(true); }}
          >
            <CardContent className="pt-5">
              <div className="flex items-center justify-between mb-3">
                <div className={`flex h-10 w-10 items-center justify-center rounded-xl ${stat.bg}`}>
                  <stat.icon className={`h-5 w-5 ${stat.color}`} />
                </div>
                <ChevronRight className="h-4 w-4 text-muted-foreground/40" />
              </div>
              <div className="text-2xl font-bold">{stat.value}</div>
              <div className="text-xs text-muted-foreground mt-1">{stat.label}</div>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Recent Properties */}
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <CardTitle className="text-lg">أحدث العقارات</CardTitle>
              <Link href="/admin/properties" className="text-sm text-primary hover:underline flex items-center gap-1">
                عرض الكل <ArrowLeft className="h-3 w-3" />
              </Link>
            </div>
          </CardHeader>
          <CardContent className="space-y-3">
            {recentProperties.length === 0 ? (
              <p className="text-sm text-muted-foreground text-center py-4">لا توجد عقارات</p>
            ) : (
              recentProperties.map((prop) => (
                <div key={prop.id} className="flex items-center gap-3 rounded-lg border border-border p-3">
                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-sm truncate">{prop.title}</p>
                    <p className="text-xs text-muted-foreground">{prop.property_code} · {prop.city}</p>
                  </div>
                  <ApprovalBadge status={prop.approval_status} />
                </div>
              ))
            )}
          </CardContent>
        </Card>

        {/* Recent Users */}
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <CardTitle className="text-lg">أحدث المستخدمين</CardTitle>
              <Link href="/admin/users" className="text-sm text-primary hover:underline flex items-center gap-1">
                عرض الكل <ArrowLeft className="h-3 w-3" />
              </Link>
            </div>
          </CardHeader>
          <CardContent className="space-y-3">
            {recentUsers.length === 0 ? (
              <p className="text-sm text-muted-foreground text-center py-4">لا يوجد مستخدمون</p>
            ) : (
              recentUsers.map((u) => (
                <div key={u.id} className="flex items-center gap-3 rounded-lg border border-border p-3">
                  <div className="flex h-9 w-9 items-center justify-center rounded-full bg-primary/10 text-primary font-semibold text-sm">
                    {u.full_name.charAt(0)}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-sm truncate">{u.full_name}</p>
                    <p className="text-xs text-muted-foreground">@{u.username}</p>
                  </div>
                  {u.role === 'admin' && (
                    <span className="rounded-full bg-primary/10 text-primary px-2 py-0.5 text-xs font-semibold">مدير</span>
                  )}
                </div>
              ))
            )}
          </CardContent>
        </Card>

        {/* Recent Messages */}
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <CardTitle className="text-lg">أحدث الرسائل</CardTitle>
              <Link href="/admin/messages" className="text-sm text-primary hover:underline flex items-center gap-1">
                عرض الكل <ArrowLeft className="h-3 w-3" />
              </Link>
            </div>
          </CardHeader>
          <CardContent className="space-y-3">
            {recentMessages.length === 0 ? (
              <p className="text-sm text-muted-foreground text-center py-4">لا توجد رسائل</p>
            ) : (
              recentMessages.map((msg) => (
                <div key={msg.id} className="rounded-lg border border-border p-3">
                  <div className="flex items-center justify-between mb-1">
                    <p className="font-medium text-sm">{msg.name}</p>
                    {msg.status === 'new' && <span className="rounded-full bg-primary/10 text-primary px-2 py-0.5 text-xs">جديد</span>}
                  </div>
                  <p className="text-xs text-muted-foreground truncate">{msg.subject}</p>
                </div>
              ))
            )}
          </CardContent>
        </Card>

        {/* Activity Log */}
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <CardTitle className="text-lg flex items-center gap-2">
                <Activity className="h-5 w-5 text-primary" />
                سجل النشاط
              </CardTitle>
              <Link href="/admin/activity" className="text-sm text-primary hover:underline flex items-center gap-1">
                عرض الكل <ArrowLeft className="h-3 w-3" />
              </Link>
            </div>
          </CardHeader>
          <CardContent className="space-y-2">
            {activityLog.length === 0 ? (
              <p className="text-sm text-muted-foreground text-center py-4">لا يوجد نشاط</p>
            ) : (
              activityLog.map((log) => (
                <div key={log.id} className="flex items-start gap-3 text-sm border-b border-border last:border-0 pb-2 last:pb-0">
                  <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-primary/10 text-primary text-xs font-semibold">
                    {log.admin?.full_name?.charAt(0) ?? 'A'}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm">
                      <span className="font-medium">{log.admin?.full_name}</span>{' '}
                      <span className="text-muted-foreground">{log.action}</span>
                    </p>
                    {log.target && <p className="text-xs text-muted-foreground">{log.target}</p>}
                    <p className="text-xs text-muted-foreground/70 mt-0.5">{new Date(log.created_at).toLocaleString('ar-EG')}</p>
                  </div>
                </div>
              ))
            )}
          </CardContent>
        </Card>
      </div>

      {/* History Modal */}
      {showHistory && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4" onClick={() => setShowHistory(false)}>
          <div className="bg-background rounded-xl shadow-xl max-w-2xl w-full max-h-[80vh] overflow-y-auto" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between p-5 border-b border-border sticky top-0 bg-background">
              <h3 className="text-lg font-bold flex items-center gap-2">
                <Calendar className="h-5 w-5 text-primary" />
                {selectedStatData ? `سجل: ${selectedStatData.label}` : 'سجل الإحصائيات الشهري'}
              </h3>
              <Button variant="ghost" size="icon" onClick={() => setShowHistory(false)}>
                <X className="h-5 w-5" />
              </Button>
            </div>
            <div className="p-5 space-y-3">
              {selectedStatData && (
                <div className="bg-muted/50 rounded-lg p-4 mb-4">
                  <p className="text-sm text-muted-foreground">القيمة الحالية</p>
                  <p className="text-2xl font-bold text-primary">{selectedStatData.value}</p>
                </div>
              )}

              {snapshots.length === 0 ? (
                <div className="text-center py-12">
                  <Calendar className="h-12 w-12 text-muted-foreground/30 mx-auto mb-3" />
                  <p className="text-muted-foreground">لا يوجد سجل شهري بعد. سيتم تخزين الإحصائيات تلقائياً كل شهر.</p>
                </div>
              ) : (
                <div className="space-y-2">
                  {(selectedStat ? getHistoryForStat(selectedStat) : snapshots.map((s) => ({
                    month: s.month,
                    year: s.year,
                    value: s.total_users,
                    newValue: s.new_users_this_month,
                    newLabel: 'مستخدمين جدد',
                  }))).map((item, i) => (
                    <div key={i} className="flex items-center justify-between rounded-lg border border-border p-3">
                      <div className="flex items-center gap-3">
                        <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10 text-primary">
                          <Calendar className="h-5 w-5" />
                        </div>
                        <div>
                          <p className="font-medium text-sm">{item.month} {item.year}</p>
                          {item.newValue !== null && item.newValue > 0 && (
                            <p className="text-xs text-emerald-500">{item.newLabel}: +{item.newValue}</p>
                          )}
                        </div>
                      </div>
                      <div className="text-left">
                        <p className="text-lg font-bold">{typeof item.value === 'number' ? new Intl.NumberFormat('ar-EG').format(item.value) : item.value}</p>
                        <p className="text-xs text-muted-foreground">{selectedStatData?.label ?? 'إجمالي المستخدمين'}</p>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
