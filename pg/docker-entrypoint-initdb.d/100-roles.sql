CREATE ROLE metacpan;
CREATE ROLE "metacpan-api";

-- make things easier for when we're poking around from inside the container
CREATE USER root;
