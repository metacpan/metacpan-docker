CREATE ROLE metacpan WITH LOGIN PASSWORD 't00lchain';
CREATE ROLE "metacpan-api" WITH LOGIN;

-- make things easier for when we're poking around from inside the container
CREATE USER root;
