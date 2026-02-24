-- Run with:
-- psql "postgresql://postgresUser:postgresPW@127.0.0.1:5455/postgresDB" -f sample_cypher_graph_queries.sql

\set ON_ERROR_STOP on

LOAD 'age';
SET search_path = ag_catalog, "$user", public;

-- 1) Kevin Bacon ego network: actor -> movies
-- Returns full paths (vertices + edges) suitable for graph visualizers.
SELECT *
FROM cypher('bacon', $$
    MATCH path=(kb:Person {id: 102})-[:ACTED_IN]->(m:Movie)
    RETURN path
    LIMIT 50
$$) AS (path agtype);

-- 2) Clint Eastwood and co-stars through shared movies
-- Each row is: Clint -> Movie <- Co-star.
SELECT *
FROM cypher('bacon', $$
    MATCH p=(c:Person {name: 'Clint Eastwood'})-[:ACTED_IN]->(:Movie)<-[:ACTED_IN]-(co:Person)
    WHERE co.name <> 'Clint Eastwood'
    RETURN p
    LIMIT 100
$$) AS (path agtype);

-- 3) Robert Redford -> Kevin Bacon (degree-2 pattern) as graph paths
-- shortestPath is unavailable in this AGE environment,
-- so this returns concrete 2-hop person-person bridge paths.
SELECT *
FROM cypher('bacon', $$
    MATCH p=(r:Person {id: 602})-[:ACTED_IN]->(:Movie)<-[:ACTED_IN]-(bridge:Person)-[:ACTED_IN]->(:Movie)<-[:ACTED_IN]-(k:Person {id: 102})
    WHERE bridge.id <> 602 AND bridge.id <> 102
    RETURN p
    LIMIT 10
$$) AS (path agtype);
