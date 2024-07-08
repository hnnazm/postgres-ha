CREATE TABLE IF NOT EXISTS items (
    id SERIAL NOT NULL,
    name VARCHAR(255) NOT NULL,
    PRIMARY KEY (id)
);

INSERT INTO items (name) VALUES ('item 1');
