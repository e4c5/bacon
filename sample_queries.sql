-- Compatibility wrapper.
-- Preferred files:
-- 1) cypher_visualization_queries.cypher (pure Cypher, visualization)
-- 2) cypher_tabular_queries.cypher (pure Cypher, tabular)
-- 3) sql_visualization_queries.sql (SQL wrappers for visualization Cypher)
-- 4) sql_tabular_queries.sql (SQL wrappers for tabular Cypher)

\set ON_ERROR_STOP on
\i /home/raditha/csi/Antikythera/bacon/sql_visualization_queries.sql
\i /home/raditha/csi/Antikythera/bacon/sql_tabular_queries.sql
