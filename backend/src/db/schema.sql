create table if not exists users (
  id uuid primary key,
  firebase_uid text unique not null,
  email text,
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists assistant_conversations (
  id uuid primary key,
  user_id uuid not null references users(id),
  title text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists assistant_messages (
  id uuid primary key,
  conversation_id uuid not null references assistant_conversations(id),
  role text not null,
  content text not null,
  metadata jsonb,
  created_at timestamptz not null default now()
);

create table if not exists bookings (
  id           uuid        primary key,
  firebase_uid text        not null,
  court_name   text        not null,
  court_id     text,
  price        int         not null,
  start_at     timestamptz not null,
  end_at       timestamptz not null,
  status       text        not null default 'confirmed'
                           check (status in ('confirmed', 'cancelled')),
  created_at   timestamptz not null default now()
);

-- fast lookup for "my upcoming bookings"
create index if not exists bookings_uid_start_at
  on bookings (firebase_uid, start_at);

-- fast lookup for court availability queries
create index if not exists bookings_court_start_at
  on bookings (court_name, start_at);

-- prevents double-booking: only one confirmed booking per (court, slot)
create unique index if not exists bookings_unique_confirmed_slot
  on bookings (court_name, start_at)
  where status = 'confirmed';
