# Kevin Bacon Graph Load (PostgreSQL + Apache AGE)

This project loads the CSV data for the Six Degrees of Kevin Bacon dataset into PostgreSQL, then builds an Apache AGE graph to run relationship queries.

## Files

- `people.csv` (`id,name,birth`)
- `movies.csv` (`id,title,year`)
- `stars.csv` (`person_id,movie_id`)
- `graph.yml` (DB connection + graph name)
- `load_bacon.sql` (full import + graph build)
- `sample_queries.sql` (example relationship queries)

## 1) Inspect CSV structure

```bash
sed -n '1,8p' people.csv
sed -n '1,8p' movies.csv
sed -n '1,8p' stars.csv
```

## 2) Connection values

From `graph.yml`:

- host: `localhost`
- port: `5455`
- database: `postgresDB`
- user: `postgresUser`
- password: `postgresPW`
- graph: `bacon`

Quick connectivity check:

```bash
psql "postgresql://postgresUser:postgresPW@127.0.0.1:5455/postgresDB" -c "select current_database(), current_user;"
```

## 3) Load relational tables and build AGE graph

Run:

```bash
psql "postgresql://postgresUser:postgresPW@127.0.0.1:5455/postgresDB" -f load_bacon.sql
```

What `load_bacon.sql` does:

1. Creates/truncates staging tables:
   - `public.bacon_people`
   - `public.bacon_movies`
   - `public.bacon_stars`
2. Loads CSV files using `\copy`.
3. Creates indexes on `bacon_stars(person_id)` and `bacon_stars(movie_id)`.
4. Creates AGE graph `bacon` if missing.
5. Creates labels if missing:
   - Vertex labels: `Person`, `Movie`
   - Edge label: `ACTED_IN`
6. Bulk inserts vertices and edges into AGE label tables.
7. Aligns AGE label sequences for future inserts.

## 4) Validation queries

```sql
LOAD 'age';
SET search_path = ag_catalog, "$user", public;

SELECT
  (SELECT COUNT(*) FROM public.bacon_people) AS people_rows,
  (SELECT COUNT(*) FROM public.bacon_movies) AS movie_rows,
  (SELECT COUNT(*) FROM public.bacon_stars) AS star_rows,
  (SELECT COUNT(*) FROM bacon."Person") AS person_vertices,
  (SELECT COUNT(*) FROM bacon."Movie") AS movie_vertices,
  (SELECT COUNT(*) FROM bacon."ACTED_IN") AS acted_in_edges;
```

Current loaded counts:

- `people_rows`: `1,044,499`
- `movie_rows`: `344,276`
- `star_rows`: `1,189,594`
- `person_vertices`: `1,044,499`
- `movie_vertices`: `344,276`
- `acted_in_edges`: `1,188,695`

## 5) Run sample relationship queries

```bash
psql "postgresql://postgresUser:postgresPW@127.0.0.1:5455/postgresDB" -f sample_queries.sql
```

Included examples:

- Movies Kevin Bacon acted in (`id=102`, born 1958)
- Co-stars of Clint Eastwood
- Degree of separation checks between Robert Redford and Kevin Bacon
- One concrete bridge path example

Observed result for separation:

- Degree 1: `false`
- Degree 2 or less: `true`
- Example bridge actor: `Morgan Freeman`
