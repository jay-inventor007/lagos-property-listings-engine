-- Full-text search over listings: q matches title, description, address, city, and state.
-- The vector is a generated column, so the database computes it on every write and it can never
-- drift from the row. The GIN index is what makes @@ lookups fast; a b-tree cannot index a tsvector.

alter table listings
  add column search_vector tsvector
  generated always as (
    to_tsvector('english', coalesce(title, '') || ' ' || coalesce(description, '') || ' ' || coalesce(address, '') || ' ' || coalesce(city, '') || ' ' || coalesce(state, ''))
  ) stored;

-- For local dev and migration scripts running inside a transaction, plain CREATE INDEX is used.
-- For production migrations on populated tables, CREATE INDEX CONCURRENTLY should be used outside
-- a transaction block to avoid write lockouts.
create index listings_search_vector on listings using gin (search_vector);
