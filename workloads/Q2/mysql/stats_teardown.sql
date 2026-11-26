-- Q2 | MySQL 8.4 | statistics teardown
-- Drops the histograms created by stats_setup.sql.
-- If a histogram does not exist, the result shows a message row; the script continues.

ANALYZE TABLE encounters DROP HISTOGRAM ON encounterclass, reasoncode;
ANALYZE TABLE conditions DROP HISTOGRAM ON `stop`;
