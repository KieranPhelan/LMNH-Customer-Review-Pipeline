DROP TABLE IF EXISTS review;
DROP TABLE IF EXISTS incident;
DROP TABLE IF EXISTS rating;
DROP TABLE IF EXISTS incident_type;
DROP TABLE IF EXISTS floor_assignment;
DROP TABLE IF EXISTS floor;
DROP TABLE IF EXISTS exhibition;
DROP TABLE IF EXISTS department;

CREATE TABLE department (
    department_id SMALLINT GENERATED ALWAYS AS IDENTITY,
    department_name VARCHAR(30) NOT NULL UNIQUE,
    PRIMARY KEY (department_id)
);

CREATE TABLE exhibition (
    exhibition_id SMALLINT GENERATED ALWAYS AS IDENTITY,
    exhibition_name VARCHAR(30) NOT NULL UNIQUE,
    exhibition_description TEXT NOT NULL,
    department_id SMALLINT NOT NULL,
    exhibition_start_date DATE NOT NULL CHECK (exhibition_start_date <= CURRENT_DATE),
    public_id VARCHAR(10) NOT NULL UNIQUE,
    PRIMARY KEY (exhibition_id),
    FOREIGN KEY (department_id) REFERENCES department(department_id)
);

CREATE TABLE floor (
    floor_id SMALLINT GENERATED ALWAYS AS IDENTITY,
    floor_name VARCHAR(30) NOT NULL UNIQUE,
    PRIMARY KEY (floor_id)
);

CREATE TABLE floor_assignment (
    floor_assignment_id SMALLINT GENERATED ALWAYS AS IDENTITY,
    exhibition_id SMALLINT NOT NULL,
    floor_id SMALLINT NOT NULL,
    PRIMARY KEY (floor_assignment_id),
    FOREIGN KEY (exhibition_id) REFERENCES exhibition(exhibition_id),
    FOREIGN KEY (floor_id) REFERENCES floor(floor_id)
);

CREATE TABLE incident_type (
    incident_type_id SMALLINT GENERATED ALWAYS AS IDENTITY,
    incident_value SMALLINT NOT NULL UNIQUE,
    incident_description VARCHAR(30) NOT NULL UNIQUE,
    PRIMARY KEY (incident_type_id)
);

CREATE TABLE rating (
    rating_id SMALLINT GENERATED ALWAYS AS IDENTITY,
    rating_description VARCHAR(30) NOT NULL UNIQUE,
    PRIMARY KEY (rating_id)
);

CREATE TABLE incident (
    incident_id BIGINT GENERATED ALWAYS AS IDENTITY,
    exhibition_id SMALLINT NOT NULL,
    incident_type_id SMALLINT NOT NULL,
    incident_at TIMESTAMPTZ NOT NULL CHECK (incident_at <= CURRENT_TIMESTAMP + INTERVAL '1 second'),
    PRIMARY KEY (incident_id),
    FOREIGN KEY (exhibition_id) REFERENCES exhibition(exhibition_id),
    FOREIGN KEY (incident_type_id) REFERENCES incident_type(incident_type_id)
);

CREATE TABLE review (
    review_id BIGINT GENERATED ALWAYS AS IDENTITY,
    exhibition_id SMALLINT NOT NULL,
    rating_id SMALLINT NOT NULL,
    review_at TIMESTAMPTZ NOT NULL CHECK (review_at <= CURRENT_TIMESTAMP + INTERVAL '1 second'),
    PRIMARY KEY (review_id),
    FOREIGN KEY (exhibition_id) REFERENCES exhibition(exhibition_id),
    FOREIGN KEY (rating_id) REFERENCES rating(rating_id)
);

INSERT INTO department
    (department_name)
VALUES
    ('Geology'),
    ('Entomology'),
    ('Zoology'),
    ('Ecology'),
    ('Paleontology');

INSERT INTO exhibition
    (exhibition_name, exhibition_description, department_id, exhibition_start_date, public_id)
VALUES
    ('Measureless to Man', 'An immersive 3D experience: delve deep into a previously-inaccessible cave system.', 1, '2021-08-23', 'EXH_00'),
    ('Adaptation', 'How insect evolution has kept pace with an industrialised world.', 2, '2019-07-01', 'EXH_01'),
    ('The Crenshaw Collection', 'An exhibition of 18th Century watercolours, mostly focused on South American wildlife.', 3, '2021-03-03', 'EXH_02'),
    ('Cetacean Sensations', 'Whales: from ancient myth to critically endangered.', 3, '2019-07-01', 'EXH_03'),
    ('Our Polluted World', 'A hard-hitting exploration of humanity''s impact on the environment.', 4, '2021-05-12', 'EXH_04'),
    ('Thunder Lizards', 'How new research is making scientists rethink what dinosaurs really looked like.', 5, '2023-02-01', 'EXH_05');

INSERT INTO floor
    (floor_name)
VALUES
    ('Vault'),
    ('1'),
    ('2'),
    ('3');

INSERT INTO floor_assignment
    (exhibition_id, floor_id)
VALUES
    (1, 2),
    (2, 1),
    (3, 3),
    (4, 2),
    (5, 4),
    (6, 2);

INSERT INTO incident_type
    (incident_value, incident_description)
VALUES
    (0, 'Assistance'),
    (1, 'Emergency');

INSERT INTO rating
    (rating_description)
VALUES
    ('Terrible'),
    ('Bad'),
    ('Neutral'),
    ('Good'),
    ('Amazing');
