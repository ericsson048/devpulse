import { useEffect, useState } from 'react';
import { api } from '../api';
import type { User } from '../types';
import { DataTable } from 'primereact/datatable';
import { Column } from 'primereact/column';
import { Tag } from 'primereact/tag';

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.getUsers(0, 100).then(setUsers).finally(() => setLoading(false));
  }, []);

  const userBody = (row: User) => (
    <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
      <div style={{
        width: 32, height: 32, borderRadius: '50%',
        background: 'linear-gradient(135deg, var(--accent), #a78bfa)',
        color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontWeight: 700, fontSize: 13, flexShrink: 0,
      }}>
        {row.display_name[0]}
      </div>
      <span style={{ fontWeight: 500 }}>{row.display_name}</span>
    </div>
  );

  const roleBody = (row: User) => (
    <Tag
      value={row.role}
      icon={row.role === 'admin' ? 'pi pi-shield' : 'pi pi-user'}
      severity={row.role === 'admin' ? 'danger' : 'info'}
      rounded
    />
  );

  const xpBody = (row: User) => (
    <span style={{ fontWeight: 600, fontVariantNumeric: 'tabular-nums' }}>
      {row.xp.toLocaleString()}
    </span>
  );

  const levelBody = (row: User) => (
    <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
      <span style={{ fontWeight: 700, fontSize: 16, color: 'var(--accent)' }}>{row.level}</span>
    </div>
  );

  const streakBody = (row: User) => (
    row.streak > 0
      ? <span style={{ color: 'var(--amber)', fontWeight: 600 }}><i className="pi pi-bolt" style={{ marginRight: 4 }} />{row.streak}d</span>
      : <span style={{ color: 'var(--text-dim)' }}>—</span>
  );

  const joinedBody = (row: User) => (
    <span style={{ color: 'var(--text-dim)', fontSize: 12 }}>
      {new Date(row.created_at).toLocaleDateString()}
    </span>
  );

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

      <DataTable
        value={users}
        loading={loading}
        stripedRows
        paginator
        rows={20}
        emptyMessage="No users yet"
        className="p-datatable-sm"
        sortMode="single"
        sortField="xp"
        sortOrder={-1}
      >
        <Column header="User" body={userBody} sortable sortField="display_name" style={{ minWidth: 180 }} />
        <Column field="email" header="Email" sortable style={{ minWidth: 180 }} />
        <Column header="Role" body={roleBody} style={{ width: 110 }} />
        <Column header="Level" body={levelBody} sortable sortField="level" style={{ width: 80 }} />
        <Column header="XP" body={xpBody} sortable sortField="xp" style={{ width: 100 }} />
        <Column header="Streak" body={streakBody} style={{ width: 90 }} />
        <Column header="Joined" body={joinedBody} sortable sortField="created_at" style={{ width: 120 }} />
      </DataTable>
    </div>
  );
}
