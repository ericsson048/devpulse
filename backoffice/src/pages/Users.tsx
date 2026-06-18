import { useEffect, useState } from 'react';
import { api } from '../api';
import type { User } from '../types';
import Table, { type ColumnDef } from '../components/ui/Table';
import Badge from '../components/ui/Badge';
import { Shield, User as UserIcon, Zap } from 'lucide-react';

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.getUsers(0, 100).then(setUsers).finally(() => setLoading(false));
  }, []);

  const columns: ColumnDef<User>[] = [
    {
      header: 'User', sortable: true, sortField: 'display_name', style: { minWidth: 180 },
      body: (row) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{
            width: 32, height: 32, borderRadius: '50%',
            background: 'linear-gradient(135deg, var(--accent), #a78bfa)',
            color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontWeight: 700, fontSize: 13, flexShrink: 0,
          }}>
            {(row.display_name || '?')[0]}
          </div>
          <span style={{ fontWeight: 500 }}>{row.display_name}</span>
        </div>
      ),
    },
    { header: 'Email', field: 'email', sortable: true, style: { minWidth: 180 } },
    {
      header: 'Role', style: { width: 110 },
      body: (row) => (
        <Badge
          value={row.role}
          severity={row.role === 'admin' ? 'danger' : 'info'}
          icon={row.role === 'admin' ? <Shield className="w-3 h-3" /> : <UserIcon className="w-3 h-3" />}
        />
      ),
    },
    {
      header: 'Level', sortable: true, sortField: 'level', style: { width: 80 },
      body: (row) => <span style={{ fontWeight: 700, fontSize: 16, color: 'var(--accent)' }}>{row.level}</span>,
    },
    {
      header: 'XP', sortable: true, sortField: 'xp', style: { width: 100 },
      body: (row) => <span style={{ fontWeight: 600, fontVariantNumeric: 'tabular-nums' }}>{row.xp.toLocaleString()}</span>,
    },
    {
      header: 'Streak', style: { width: 90 },
      body: (row) => row.streak > 0
        ? <span style={{ color: 'var(--amber)', fontWeight: 600 }}><Zap className="w-3.5 h-3.5 inline mr-1" />{row.streak}d</span>
        : <span style={{ color: 'var(--text-dim)' }}>—</span>,
    },
    {
      header: 'Joined', sortable: true, sortField: 'created_at', style: { width: 120 },
      body: (row) => <span style={{ color: 'var(--text-dim)', fontSize: 12 }}>{new Date(row.created_at).toLocaleDateString()}</span>,
    },
  ];

  return (
    <div className="page fade-in">
      <div className="page-header">
        <div>
          <h1>Users</h1>
          <p style={{ color: 'var(--text-dim)', fontSize: 13, marginTop: 4 }}>
            {users.length} registered user{users.length !== 1 ? 's' : ''}
          </p>
        </div>
      </div>

      <Table
        value={users}
        columns={columns}
        loading={loading}
        striped
        paginator
        rows={20}
        emptyMessage="No users yet"
        sortField="xp"
        sortOrder={-1}
      />
    </div>
  );
}
