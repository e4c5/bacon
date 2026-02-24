-- Run with:
-- psql "postgresql://postgresUser:postgresPW@127.0.0.1:5455/postgresDB" -f sample_queries.sql

LOAD 'age';
SET search_path = ag_catalog, "$user", public;

-- 1) Movies Kevin Bacon (id=102, birth=1958) acted in
SELECT *
FROM cypher('bacon', $$
    MATCH (p:Person {id: 102})-[:ACTED_IN]->(m:Movie)
    RETURN m.title, m.year
    ORDER BY m.year, m.title
    LIMIT 50
$$) AS (title agtype, year agtype);

-- 2) Co-stars of Clint Eastwood
SELECT *
FROM cypher('bacon', $$
    MATCH (c:Person {name: 'Clint Eastwood'})-[:ACTED_IN]->(:Movie)<-[:ACTED_IN]-(co:Person)
    WHERE co.name <> 'Clint Eastwood'
    RETURN DISTINCT co.name
    ORDER BY co.name
    LIMIT 100
$$) AS (co_star agtype);

-- 3) Degree of separation between Robert Redford and Kevin Bacon
-- The AGE shortestPath function is unavailable in this environment,
-- so we use indexed SQL checks over bacon_stars.
-- Degree 1 check:
SELECT EXISTS (
    SELECT 1
    FROM public.bacon_stars a
    JOIN public.bacon_stars b ON a.movie_id = b.movie_id
    WHERE a.person_id = 602   -- Robert Redford
      AND b.person_id = 102   -- Kevin Bacon (1958)
) AS degree_1;

-- Degree 2 check:
SELECT EXISTS (
    SELECT 1
    FROM public.bacon_stars s0
    JOIN public.bacon_stars s1 ON s1.movie_id = s0.movie_id
    JOIN public.bacon_stars s2 ON s2.person_id = s1.person_id
    JOIN public.bacon_stars s3 ON s3.movie_id = s2.movie_id
    WHERE s0.person_id = 602
      AND s3.person_id = 102
) AS degree_2_or_less;

-- One concrete 2-hop bridge (example path evidence)
SELECT bridge.name AS bridge_actor,
       m1.title AS robert_to_bridge_movie,
       m2.title AS bridge_to_kevin_movie
FROM public.bacon_stars s0
JOIN public.bacon_stars s1 ON s1.movie_id = s0.movie_id
JOIN public.bacon_stars s2 ON s2.person_id = s1.person_id
JOIN public.bacon_stars s3 ON s3.movie_id = s2.movie_id
JOIN public.bacon_people bridge ON bridge.id = s1.person_id
JOIN public.bacon_movies m1 ON m1.id = s0.movie_id
JOIN public.bacon_movies m2 ON m2.id = s3.movie_id
WHERE s0.person_id = 602
  AND s3.person_id = 102
  AND s1.person_id <> 602
  AND s1.person_id <> 102
LIMIT 1;
