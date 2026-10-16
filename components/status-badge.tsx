import { cn } from '@/lib/utils';
import { PropertyStatus, ApprovalStatus, PROPERTY_STATUS_LABELS, APPROVAL_STATUS_LABELS } from '@/lib/types';

const statusStyles: Record<PropertyStatus, string> = {
  available: 'bg-white/90 text-foreground border border-border',
  reserved: 'bg-amber-500/90 text-white',
  sold: 'bg-foreground/80 text-white',
  unpublished: 'bg-muted text-muted-foreground',
};

const approvalStyles: Record<ApprovalStatus, string> = {
  pending: 'bg-amber-500/10 text-amber-600',
  approved: 'bg-emerald-500/10 text-emerald-600',
  rejected: 'bg-destructive/10 text-destructive',
};

export function StatusBadge({ status, className }: { status: PropertyStatus; className?: string }) {
  return (
    <span className={cn('rounded px-2.5 py-1 text-xs font-medium', statusStyles[status], className)}>
      {PROPERTY_STATUS_LABELS[status]}
    </span>
  );
}

export function ApprovalBadge({ status, className }: { status: ApprovalStatus; className?: string }) {
  return (
    <span className={cn('rounded px-2.5 py-1 text-xs font-medium', approvalStyles[status], className)}>
      {APPROVAL_STATUS_LABELS[status]}
    </span>
  );
}
