\set ON_ERROR_STOP on

-- 1) Create relational staging tables
CREATE TABLE IF NOT EXISTS public.bacon_people (
    id BIGINT PRIMARY KEY,
    name TEXT NOT NULL,
    birth INTEGER
);

CREATE TABLE IF NOT EXISTS public.bacon_movies (
    id BIGINT PRIMARY KEY,
    title TEXT NOT NULL,
    year INTEGER
);

CREATE TABLE IF NOT EXISTS public.bacon_stars (
    person_id BIGINT NOT NULL,
    movie_id BIGINT NOT NULL
);

TRUNCATE TABLE public.bacon_people, public.bacon_movies, public.bacon_stars;

-- 2) Load CSV data via client-side copy
\copy public.bacon_people (id, name, birth) FROM '/home/raditha/csi/Antikythera/bacon/people.csv' WITH (FORMAT csv, HEADER true)
\copy public.bacon_movies (id, title, year) FROM '/home/raditha/csi/Antikythera/bacon/movies.csv' WITH (FORMAT csv, HEADER true)
\copy public.bacon_stars (person_id, movie_id) FROM '/home/raditha/csi/Antikythera/bacon/stars.csv' WITH (FORMAT csv, HEADER true)

CREATE INDEX IF NOT EXISTS bacon_stars_person_id_idx ON public.bacon_stars(person_id);
CREATE INDEX IF NOT EXISTS bacon_stars_movie_id_idx ON public.bacon_stars(movie_id);

-- 3) Ensure AGE graph and labels exist
LOAD 'age';
SET search_path = ag_catalog, "$user", public;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM ag_catalog.ag_graph WHERE name = 'bacon') THEN
        PERFORM ag_catalog.create_graph('bacon');
    END IF;
END $$;

DO $$
DECLARE
    g_oid oid;
BEGIN
    SELECT graphid INTO g_oid
    FROM ag_catalog.ag_graph
    WHERE name = 'bacon';

    IF NOT EXISTS (
        SELECT 1 FROM ag_catalog.ag_label
        WHERE graph = g_oid AND name = 'Person' AND kind = 'v'
    ) THEN
        PERFORM ag_catalog.create_vlabel('bacon', 'Person');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM ag_catalog.ag_label
        WHERE graph = g_oid AND name = 'Movie' AND kind = 'v'
    ) THEN
        PERFORM ag_catalog.create_vlabel('bacon', 'Movie');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM ag_catalog.ag_label
        WHERE graph = g_oid AND name = 'ACTED_IN' AND kind = 'e'
    ) THEN
        PERFORM ag_catalog.create_elabel('bacon', 'ACTED_IN');
    END IF;
END $$;

-- 4) Rebuild graph contents from relational tables
TRUNCATE TABLE bacon."ACTED_IN", bacon."Person", bacon."Movie";

INSERT INTO bacon."Person" (id, properties)
SELECT ag_catalog._graphid(person_label.id, p.id),
       ag_catalog.agtype_build_map('id', p.id, 'name', p.name, 'birth', p.birth)
FROM public.bacon_people p
CROSS JOIN (
    SELECT id
    FROM ag_catalog.ag_label
    WHERE graph = (SELECT graphid FROM ag_catalog.ag_graph WHERE name = 'bacon')
      AND name = 'Person'
      AND kind = 'v'
) AS person_label;

INSERT INTO bacon."Movie" (id, properties)
SELECT ag_catalog._graphid(movie_label.id, m.id),
       ag_catalog.agtype_build_map('id', m.id, 'title', m.title, 'year', m.year)
FROM public.bacon_movies m
CROSS JOIN (
    SELECT id
    FROM ag_catalog.ag_label
    WHERE graph = (SELECT graphid FROM ag_catalog.ag_graph WHERE name = 'bacon')
      AND name = 'Movie'
      AND kind = 'v'
) AS movie_label;

INSERT INTO bacon."ACTED_IN" (id, start_id, end_id, properties)
SELECT ag_catalog._graphid(edge_label.id, ROW_NUMBER() OVER (ORDER BY s.person_id, s.movie_id)),
       ag_catalog._graphid(person_label.id, s.person_id),
       ag_catalog._graphid(movie_label.id, s.movie_id),
       ag_catalog.agtype_build_map()
FROM public.bacon_stars s
JOIN public.bacon_people p ON p.id = s.person_id
JOIN public.bacon_movies m ON m.id = s.movie_id
CROSS JOIN (
    SELECT id
    FROM ag_catalog.ag_label
    WHERE graph = (SELECT graphid FROM ag_catalog.ag_graph WHERE name = 'bacon')
      AND name = 'Person'
      AND kind = 'v'
) AS person_label
CROSS JOIN (
    SELECT id
    FROM ag_catalog.ag_label
    WHERE graph = (SELECT graphid FROM ag_catalog.ag_graph WHERE name = 'bacon')
      AND name = 'Movie'
      AND kind = 'v'
) AS movie_label
CROSS JOIN (
    SELECT id
    FROM ag_catalog.ag_label
    WHERE graph = (SELECT graphid FROM ag_catalog.ag_graph WHERE name = 'bacon')
      AND name = 'ACTED_IN'
      AND kind = 'e'
) AS edge_label;

-- 5) Keep AGE label sequences aligned for future inserts
SELECT setval('bacon."Person_id_seq"', (SELECT COALESCE(MAX(id), 0) + 1 FROM public.bacon_people), false);
SELECT setval('bacon."Movie_id_seq"', (SELECT COALESCE(MAX(id), 0) + 1 FROM public.bacon_movies), false);
SELECT setval('bacon."ACTED_IN_id_seq"', (SELECT COALESCE(COUNT(*), 0) + 1 FROM bacon."ACTED_IN"), false);
