DROP TABLE IF EXISTS events;

CREATE TABLE events (
    object json,
    seen BOOLEAN DEFAULT FALSE,
    created TIMESTAMP WITH time zone DEFAULT current_timestamp
);

