-- SQL wrappers for cypher_tabular_queries.cypher
-- Run with:
-- psql "postgresql://postgresUser:postgresPW@127.0.0.1:5455/postgresDB" -f sql_tabular_queries.sql

\set ON_ERROR_STOP on

LOAD 'age';
SET search_path = ag_catalog, "$user", public;

-- 1) Movies Kevin Bacon acted in
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

-- 3) Robert Redford -> Kevin Bacon 2-hop examples (tabular projection)
SELECT *
FROM cypher('bacon', $$
    MATCH (r:Person {id: 602})-[:ACTED_IN]->(m1:Movie)<-[:ACTED_IN]-(bridge:Person)-[:ACTED_IN]->(m2:Movie)<-[:ACTED_IN]-(k:Person {id: 102})
    WHERE bridge.id <> 602 AND bridge.id <> 102
    RETURN bridge.name AS bridge_actor, m1.title AS robert_to_bridge_movie, m2.title AS bridge_to_kevin_movie
    LIMIT 10
$$) AS (bridge_actor agtype, robert_to_bridge_movie agtype, bridge_to_kevin_movie agtype);

-- Question 6) Which movie has the largest cast?
SELECT *
FROM cypher('bacon', $$
    MATCH (m:Movie)<-[:ACTED_IN]-(p:Person)
    WITH m, count(p) AS cast_size
    ORDER BY cast_size DESC, m.title
    LIMIT 1
    RETURN m.title, m.year, cast_size
$$) AS (title agtype, year agtype, cast_size agtype);

-- Question 7) All co-stars of a given actor (exactly 2 hops: Person-Movie-Person)
-- Example actor id: 142 (Clint Eastwood). Replace with any Person.id.
SELECT *
FROM cypher('bacon', $$
    MATCH (a:Person {id: 142})-[:ACTED_IN]->(:Movie)<-[:ACTED_IN]-(co:Person)
    WHERE co.id <> a.id
    RETURN DISTINCT co.name
    ORDER BY co.name
$$) AS (co_star agtype);
