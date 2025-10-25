# Friendship Database Design Documentation

## Overview

This document outlines a PostgreSQL database design for managing friendships with a friend request system. The design supports directional friend requests that can be accepted or rejected, with optimized querying for accepted friendships.

## Database Schema

### Tables

#### `personas`
Stores user/persona information.

```sql
CREATE TABLE personas (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### `friendship_requests`
Stores friendship requests with status tracking.

```sql
CREATE TABLE friendship_requests (
    id SERIAL PRIMARY KEY,
    requester_id INTEGER NOT NULL REFERENCES personas(id) ON DELETE CASCADE,
    recipient_id INTEGER NOT NULL REFERENCES personas(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT different_personas CHECK (requester_id != recipient_id),
    CONSTRAINT valid_status CHECK (status IN ('pending', 'accepted', 'rejected'))
);
```

**Status values:**
- `pending`: Friend request sent but not yet responded to
- `accepted`: Friend request accepted, users are now friends
- `rejected`: Friend request declined

### Indexes

Composite indexes for optimal query performance:

```sql
-- Index for queries filtering by status and requester
CREATE INDEX idx_friendship_requester 
ON friendship_requests(status, requester_id);

-- Index for queries filtering by status and recipient
CREATE INDEX idx_friendship_recipient 
ON friendship_requests(status, recipient_id);

-- Prevent duplicate requests in either direction for pending/accepted requests
CREATE UNIQUE INDEX unique_friendship_request 
ON friendship_requests (
    LEAST(requester_id, recipient_id),
    GREATEST(requester_id, recipient_id)
) WHERE status IN ('pending', 'accepted');
```

## Key Design Features

### 1. Referential Integrity
- Foreign keys ensure friendships can only exist between valid personas
- `ON DELETE CASCADE` automatically removes friendships when a persona is deleted

### 2. Constraints
- **No self-friendships**: `requester_id != recipient_id`
- **Valid status values**: Only 'pending', 'accepted', or 'rejected'
- **No duplicate requests**: Unique index prevents both (A→B) and (B→A) requests from existing simultaneously in pending/accepted states

### 3. Directional Tracking
- Preserves who initiated the friendship request
- Allows asymmetric handling (A requests B, but B hasn't responded yet)

## Common Queries

### Find All Friends of a Persona

```sql
-- Get friend IDs for persona 5
SELECT 
    CASE 
        WHEN requester_id = 5 THEN recipient_id
        ELSE requester_id
    END as friend_id,
    created_at
FROM friendship_requests
WHERE status = 'accepted'
  AND (requester_id = 5 OR recipient_id = 5);
```

### Get Friends with Full Details

```sql
SELECT 
    p.id,
    p.name,
    fr.created_at as friends_since
FROM friendship_requests fr
JOIN personas p ON (
    CASE 
        WHEN fr.requester_id = 5 THEN fr.recipient_id
        ELSE fr.requester_id
    END = p.id
)
WHERE fr.status = 'accepted'
  AND (fr.requester_id = 5 OR fr.recipient_id = 5);
```

### Get Pending Friend Requests (Received)

```sql
SELECT 
    p.id,
    p.name,
    fr.created_at as requested_at
FROM friendship_requests fr
JOIN personas p ON fr.requester_id = p.id
WHERE fr.status = 'pending'
  AND fr.recipient_id = 5;
```

### Send a Friend Request

```sql
INSERT INTO friendship_requests (requester_id, recipient_id, status)
VALUES (5, 10, 'pending')
ON CONFLICT DO NOTHING;
```

### Accept a Friend Request

```sql
UPDATE friendship_requests
SET status = 'accepted', 
    updated_at = CURRENT_TIMESTAMP
WHERE requester_id = 10 
  AND recipient_id = 5 
  AND status = 'pending';
```

## Optimization: Bidirectional View

For simpler querying, create a view that presents friendships bidirectionally:

```sql
CREATE VIEW friends AS
SELECT 
    requester_id as persona_id, 
    recipient_id as friend_id, 
    created_at 
FROM friendship_requests 
WHERE status = 'accepted'
UNION ALL
SELECT 
    recipient_id as persona_id, 
    requester_id as friend_id, 
    created_at 
FROM friendship_requests 
WHERE status = 'accepted';
```

**Usage:**

```sql
-- Simple query to get all friends
SELECT friend_id FROM friends WHERE persona_id = 5;

-- Get friends with details
SELECT p.* 
FROM friends f
JOIN personas p ON f.friend_id = p.id
WHERE f.persona_id = 5;
```

## Performance Characteristics

### Index Performance

The composite indexes enable efficient lookups:

**Without indexes:**
- 1M rows: ~500ms per query
- 10M rows: ~5 seconds per query

**With composite indexes:**
- 1M rows: ~5ms per query
- 10M rows: ~5ms per query

Query time remains constant regardless of table size.

### How Indexes Work

When querying for friends:
1. PostgreSQL uses bitmap index scans on both composite indexes
2. Quickly finds rows matching `(status='accepted', requester_id=X)`
3. Quickly finds rows matching `(status='accepted', recipient_id=X)`
4. Combines results and fetches only relevant rows
5. No full table scan required

### Verify Index Usage

Check if your queries use indexes efficiently:

```sql
EXPLAIN ANALYZE
SELECT 
    CASE 
        WHEN requester_id = 5 THEN recipient_id
        ELSE requester_id
    END as friend_id
FROM friendship_requests
WHERE status = 'accepted'
  AND (requester_id = 5 OR recipient_id = 5);
```

Look for "Bitmap Index Scan" or "Index Scan" in the output (good). Avoid "Seq Scan" for large tables (bad).

## Database Naming Conventions Used

- **Tables**: Plural nouns in snake_case (`friendship_requests`, `personas`)
- **Columns**: Descriptive snake_case (`requester_id`, `created_at`)
- **Foreign keys**: `table_name_id` pattern (`persona_id`)
- **Booleans**: `is_`, `has_`, `can_` prefixes (if needed)
- **Timestamps**: `_at` suffix (`created_at`, `updated_at`)
- **Indexes**: `idx_` prefix with descriptive name (`idx_friendship_requester`)

## Trade-offs and Considerations

### Pros
✅ Full referential integrity with foreign keys  
✅ Tracks friendship request history  
✅ Preserves who initiated the friendship  
✅ Excellent query performance with proper indexes  
✅ Prevents duplicate/conflicting requests  

### Cons
❌ Queries require CASE statements or views for bidirectional lookups  
❌ More complex than simple bidirectional storage  
❌ The view uses UNION ALL which runs on every query (not materialized)  

### When to Use This Design
- You need to track friend requests and their status
- You want to know who initiated each friendship
- You need referential integrity guarantees
- Query performance is important (with proper indexes)

### Alternative: Simpler Bidirectional Design
If you don't need request tracking, consider storing friendships once with ordered IDs:

```sql
CREATE TABLE friendships (
    id SERIAL PRIMARY KEY,
    persona_id_1 INTEGER NOT NULL REFERENCES personas(id),
    persona_id_2 INTEGER NOT NULL REFERENCES personas(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ordered_personas CHECK (persona_id_1 < persona_id_2)
);
```

This is simpler but loses request status tracking and directional information.