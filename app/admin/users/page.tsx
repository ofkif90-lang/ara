'use client';

import { useEffect, useState, useCallback } from 'react';
import { Users, Search, UserCheck, UserX, Loader2, Shield, KeyRound } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Profile } from '@/lib/types';
import { supabase } from '@/lib/supabase/client';
import { useAuth } from '@/lib/auth-context';
import { useToast } from '@/hooks/use-toast';
import { EmptyState } from '@/components/states';

export default function AdminUsersPage() {
  const { profile } = useAuth();
  const { toast } = useToast();
  const [users, setUsers] = useState<Profile[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [resetUser, setResetUser] = useState<Profile | null>(null);
  const [newPassword, setNewPassword] = useState('');
  const [resetting, setResetting] = useState(false);

  const fetchUsers = useCallback(async () => {
    setLoading(true);
    let query = supabase.from('profiles').select('*').order('created_at', { ascending: false });
    if (search) {
      query = query.or(`full_name.ilike.%${search}%,username.ilike.%${search}%,email.ilike.%${search}%`);
    }
    const { data } = await query.limit(50);
    setUsers((data as Profile[]) ?? []);
    setLoading(false);
  }, [search]);

  useEffect(() => { fetchUsers(); }, [fetchUsers]);

  const logActivity = async (action: string, target: string) => {
    if (!profile) return;
    await supabase.from('activity_log').insert({ admin_id: profile.id, action, target });
  };

  const toggleActive = async (user: Profile) => {
    const newActive = !user.is_active;
    const { error } = await supabase.from('profiles').update({ is_active: newActive }).eq('id', user.id);
    if (!error) {
      toast({ title: newActive ? 'تم تفعيل الحساب' : 'تم تعطيل الحساب' });
      logActivity(newActive ? 'تفعيل مستخدم' : 'تعطيل مستخدم', user.username);
      fetchUsers();
    }
  };

  const handleResetPassword = async () => {
    if (!resetUser || !newPassword) return;
    if (newPassword.length < 6) {
      toast({ title: 'كلمة المرور قصيرة جداً', description: 'يجب أن تكون 6 أحرف على الأقل', variant: 'destructive' });
      return;
    }

    setResetting(true);
    try {
      const { data: { session } } = await supabase.auth.getSession();
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/admin-reset-password`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${session?.access_token}`,
          },
          body: JSON.stringify({ userId: resetUser.id, newPassword }),
        }
      );

      const result = await response.json();

      if (!response.ok) {
        throw new Error(result.error || 'فشل إعادة تعيين كلمة المرور');
      }

      toast({
        title: 'تم تغيير كلمة المرور',
        description: `كلمة المرور الجديدة لـ ${resetUser.full_name} تم تعيينها بنجاح`,
      });
      logActivity('إعادة تعيين كلمة مرور', resetUser.username);
      setResetUser(null);
      setNewPassword('');
    } catch (err) {
      toast({
        title: 'فشل تغيير كلمة المرور',
        description: err instanceof Error ? err.message : 'حدث خطأ',
        variant: 'destructive',
      });
    } finally {
      setResetting(false);
    }
  };

  return (
    <div className="space-y-4">
      <h2 className="text-2xl font-bold">المستخدمون</h2>

      <div className="relative max-w-md">
        <Search className="absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
        <Input placeholder="ابحث بالاسم، اسم المستخدم، البريد..." value={search} onChange={(e) => setSearch(e.target.value)} className="pr-10" />
      </div>

      {loading ? (
        <div className="flex justify-center py-12"><Loader2 className="h-8 w-8 animate-spin text-primary" /></div>
      ) : users.length === 0 ? (
        <EmptyState icon={Users} title="لا يوجد مستخدمون" />
      ) : (
        <div className="rounded-lg border border-border overflow-hidden overflow-x-auto">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>المستخدم</TableHead>
                <TableHead>البريد</TableHead>
                <TableHead>الهاتف</TableHead>
                <TableHead>الدور</TableHead>
                <TableHead>الحالة</TableHead>
                <TableHead>التسجيل</TableHead>
                <TableHead>إجراءات</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {users.map((u) => (
                <TableRow key={u.id}>
                  <TableCell>
                    <div className="flex items-center gap-2">
                      <div className="flex h-9 w-9 items-center justify-center rounded-full bg-primary/10 text-primary font-semibold text-sm">
                        {u.full_name.charAt(0)}
                      </div>
                      <div>
                        <p className="font-medium text-sm">{u.full_name}</p>
                        <p className="text-xs text-muted-foreground">@{u.username}</p>
                      </div>
                    </div>
                  </TableCell>
                  <TableCell className="text-sm">{u.email}</TableCell>
                  <TableCell className="text-sm">{u.phone ?? '-'}</TableCell>
                  <TableCell>
                    {u.role === 'admin' ? (
                      <span className="flex items-center gap-1 text-xs font-semibold text-primary"><Shield className="h-3 w-3" /> مدير</span>
                    ) : (
                      <span className="text-xs text-muted-foreground">مستخدم</span>
                    )}
                  </TableCell>
                  <TableCell>
                    <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${u.is_active ? 'bg-emerald-500/10 text-emerald-500' : 'bg-red-500/10 text-red-500'}`}>
                      {u.is_active ? 'نشط' : 'معطل'}
                    </span>
                  </TableCell>
                  <TableCell className="text-sm text-muted-foreground">{new Date(u.created_at).toLocaleDateString('ar-EG')}</TableCell>
                  <TableCell>
                    <div className="flex items-center gap-1">
                      {u.role !== 'admin' && (
                        <>
                          <Button
                            size="sm"
                            variant="ghost"
                            onClick={() => { setResetUser(u); setNewPassword(''); }}
                            title="إعادة تعيين كلمة المرور"
                          >
                            <KeyRound className="h-4 w-4" />
                          </Button>
                          <Button
                            size="sm"
                            variant="ghost"
                            onClick={() => toggleActive(u)}
                            className={u.is_active ? 'text-destructive' : 'text-emerald-500'}
                          >
                            {u.is_active ? <><UserX className="h-4 w-4 ml-1" />تعطيل</> : <><UserCheck className="h-4 w-4 ml-1" />تفعيل</>}
                          </Button>
                        </>
                      )}
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      )}

      {/* Password Reset Dialog */}
      <Dialog open={!!resetUser} onOpenChange={(open) => { if (!open) { setResetUser(null); setNewPassword(''); } }}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <KeyRound className="h-5 w-5 text-primary" />
              إعادة تعيين كلمة المرور
            </DialogTitle>
            <DialogDescription>
              سيتم تعيين كلمة مرور جديدة للمستخدم{' '}
              <span className="font-semibold text-foreground">{resetUser?.full_name}</span>{' '}
              ({resetUser?.email}). سيُطلب منه تغييرها عند تسجيل الدخول التالي.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-2 py-4">
            <Label htmlFor="new-password">كلمة المرور الجديدة</Label>
            <Input
              id="new-password"
              type="password"
              placeholder="••••••••"
              value={newPassword}
              onChange={(e) => setNewPassword(e.target.value)}
              minLength={6}
            />
            <p className="text-xs text-muted-foreground">6 أحرف على الأقل</p>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => { setResetUser(null); setNewPassword(''); }}>
              إلغاء
            </Button>
            <Button onClick={handleResetPassword} disabled={resetting || !newPassword}>
              {resetting ? 'جاري التغيير...' : 'تأكيد كلمة المرور الجديدة'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
