# Kevin Bacon Graph Load (PostgreSQL + Apache AGE)

This project loads the CSV data for the Six Degrees of Kevin Bacon dataset into PostgreSQL, then builds an Apache AGE graph to run relationship queries. The CSV data can be downloaded from:
https://www.kaggle.com/datasets/parthparmar06/imdb-co-star-network?resource=download&select=stars.csv

## Files

- `people.csv` (`id,name,birth`)
- `movies.csv` (`id,title,year`)
- `stars.csv` (`person_id,movie_id`)
- `load_bacon.sql` (full import + graph build)

### Query Sets (explicit split)

Pure Cypher:
- `cypher_tabular_queries.cypher`
- `cypher_visualization_queries.cypher`

Equivalent SQL wrappers (same Cyphers wrapped with AGE `cypher(...)`):
- `sql_tabular_queries.sql`
- `sql_visualization_queries.sql`

Compatibility wrappers:
- `sample_cypher_graph_queries.sql`
- `sample_tabular_queries.sql`
- `sample_queries.sql`

## 1) Inspect CSV structure

```bash
sed -n '1,8p' people.csv
sed -n '1,8p' movies.csv
sed -n '1,8p' stars.csv
```

## 2) Quick connectivity check

Replace credentials with your own values.

```bash
psql "postgresql://postgresUser:postgresPW@127.0.0.1:5455/postgresDB" -c "select current_database(), current_user;"
```

## 3) Load relational tables and build AGE graph

```bash
psql "postgresql://postgresUser:postgresPW@127.0.0.1:5455/postgresDB" -f load_bacon.sql
```

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

## 5) Run query files

Visualization set (SQL wrappers):

```bash
psql "postgresql://postgresUser:postgresPW@127.0.0.1:5455/postgresDB" -f sql_visualization_queries.sql
```

Tabular set (SQL wrappers):

```bash
psql "postgresql://postgresUser:postgresPW@127.0.0.1:5455/postgresDB" -f sql_tabular_queries.sql
```

Pure Cypher files are intended for AGE visualizers/tools that execute Cypher directly:

- `cypher_visualization_queries.cypher`
- `cypher_tabular_queries.cypher`

Run both SQL sets via wrapper:

```bash
psql "postgresql://postgresUser:postgresPW@127.0.0.1:5455/postgresDB" -f sample_queries.sql
```
