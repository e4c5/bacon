-- SQL wrappers for cypher_visualization_queries.cypher
-- Run with:
-- psql "postgresql://postgresUser:postgresPW@127.0.0.1:5455/postgresDB" -f sql_visualization_queries.sql

\set ON_ERROR_STOP on

LOAD 'age';
SET search_path = ag_catalog, "$user", public;

-- 1) Kevin Bacon ego network
SELECT *
FROM cypher('bacon', $$
    MATCH path=(kb:Person {id: 102})-[:ACTED_IN]->(m:Movie)
    RETURN path
    LIMIT 50
$$) AS (path agtype);

-- 1b) First 50 stars (actors) with one ACTED_IN relationship for visualization
SELECT *
FROM cypher('bacon', $$
    MATCH p=(s:Person)-[:ACTED_IN]->(:Movie)
    RETURN p
    ORDER BY s.id
    LIMIT 50
$$) AS (path agtype);

-- 2) Clint Eastwood co-star network
SELECT *
FROM cypher('bacon', $$
    MATCH p=(c:Person {name: 'Clint Eastwood'})-[:ACTED_IN]->(:Movie)<-[:ACTED_IN]-(co:Person)
    WHERE co.name <> 'Clint Eastwood'
    RETURN p
    LIMIT 100
$$) AS (path agtype);

-- 3) Robert Redford -> Kevin Bacon 2-hop visualization paths
SELECT *
FROM cypher('bacon', $$
    MATCH p=(r:Person {id: 602})-[:ACTED_IN]->(:Movie)<-[:ACTED_IN]-(bridge:Person)-[:ACTED_IN]->(:Movie)<-[:ACTED_IN]-(k:Person {id: 102})
    WHERE bridge.id <> 602 AND bridge.id <> 102
    RETURN p
    LIMIT 10
$$) AS (path agtype);

-- Question 6) Visualize the movie with the largest cast and its actor links
SELECT *
FROM cypher('bacon', $$
    MATCH (m:Movie)<-[:ACTED_IN]-(p:Person)
    WITH m, count(p) AS cast_size
    ORDER BY cast_size DESC, m.title
    LIMIT 1
    MATCH path=(actor:Person)-[:ACTED_IN]->(m)
    RETURN path
    LIMIT 200
$$) AS (path agtype);

-- Question 7) Visualize co-stars of a given actor (exactly 2 hops)
-- Example actor id: 142 (Clint Eastwood). Replace with any Person.id.
SELECT *
FROM cypher('bacon', $$
    MATCH path=(a:Person {id: 142})-[:ACTED_IN]->(:Movie)<-[:ACTED_IN]-(co:Person)
    WHERE co.id <> a.id
    RETURN path
    LIMIT 100
$$) AS (path agtype);
