/* Task 0 – Database */

/* Task 1 – Constraints */
  /* a. Display constraints */
SELECT TABLE_NAME, CONSTRAINT_NAME, CONSTRAINT_TYPE
FROM USER_CONSTRAINTS 
WHERE TABLE_NAME in ('ACTOR', 'CATEGORY', 'FILM', 'FILM_ACTOR', 'FILM_CATEGORY', 'language');

  /* b. Create constraints */
    /* 1 PK_ACTORID */
ALTER TABLE actor ADD CONSTRAINT PK_ACTORID PRIMARY KEY (actor_id);
    /* 2 PK_CATEGORYID */
ALTER TABLE category ADD CONSTRAINT PK_CATEGORYID PRIMARY KEY (category_id);
    /* 3 PK_FILMID (already created) */
    /* 4 PK_LANGUAGEID (already created) */
    /* 5 UN_DESCRIPTION (already created) */
    /* 6 CK_FNAME */
ALTER TABLE actor MODIFY first_name CONSTRAINT CK_FNAME NOT NULL;
    /* 7 CK_LNAME */
ALTER TABLE actor MODIFY last_name CONSTRAINT CK_LNAME NOT NULL;
    /* 8 CK_TITLE */
ALTER TABLE film MODIFY title CONSTRAINT CK_TITLE NOT NULL;
    /* 9 CK_CATNAME */
ALTER TABLE category MODIFY name CONSTRAINT CK_CATNAME NOT NULL;
    /* 10 CK_RENTALRATE */
ALTER TABLE film MODIFY rental_rate CONSTRAINT CK_RENTALRATE NOT NULL;
    /* 11 CK_RATING */
ALTER TABLE film ADD CONSTRAINT CK_RATING CHECK (rating IN ('G','PG','PG-13','R','NC-17'));
    /* 12 CK_SPLFEATURES */
ALTER TABLE film ADD CONSTRAINT CK_SPLFEATURES CHECK (special_features IN ('Trailers', 'Commentaries', 'Deleted Scenes', 'Behind the Scenes'));
    /* 13 FK_LANGUAGEID */
ALTER TABLE film ADD CONSTRAINT FK_LANGUAGEID FOREIGN KEY (language_id) REFERENCES "language" (language_id);
    /* 14 FK_ORLANGUAGEID */
ALTER TABLE film ADD CONSTRAINT FK_ORLANGUAGEID FOREIGN KEY (original_language_id) REFERENCES "language" (language_id);
    /* 15 FK_ACTORID */
ALTER TABLE film_actor ADD CONSTRAINT FK_ACTORID FOREIGN KEY (actor_id) REFERENCES actor (actor_id);
    /* 16 CK_RELEASEYR */
ALTER TABLE film ADD CONSTRAINT CK_RELEASEYR CHECK (release_year <= 2015);

/* Task 2 – Triggers */
  /* a. populates the film_id when a new film is added */
CREATE SEQUENCE SEQ_FILMID MINVALUE 21000 MAXVALUE 999999999999 INCREMENT BY 1 START WITH 21000;
CREATE OR REPLACE TRIGGER TR_FILMID
  BEFORE INSERT ON film
  FOR EACH ROW
BEGIN
  SELECT SEQ_FILMID.NEXTVAL INTO :NEW.film_id FROM DUAL;
END;
/

  /* b. change the replacement_cost and append text to the description */
CREATE OR REPLACE TRIGGER TR_RATING
  BEFORE INSERT ON film
  FOR EACH ROW
  BEGIN
    IF (:NEW.rating = 'G') THEN
      :NEW.replacement_cost := :NEW.replacement_cost-0.1;
      :NEW.description := (:NEW.description || ' Recommended for all audiences');
    END IF;
    IF (:NEW.rating = 'PG') THEN
      :NEW.replacement_cost := :NEW.replacement_cost+0.2;
      :NEW.description := (:NEW.description || ' Parental guidance for young viewers');
    END IF;
    IF (:NEW.rating = 'PG-13') THEN
      :NEW.replacement_cost := :NEW.replacement_cost+0.2;
      :NEW.description := (:NEW.description || ' Parental guidance for young viewers');
    END IF;
    IF (:NEW.rating = 'R') THEN
      :NEW.replacement_cost := :NEW.replacement_cost+0.6;
      :NEW.description := (:NEW.description || ' Recommended for mature audiences');
    END IF;
    IF (:NEW.rating = 'NC-17') THEN
      :NEW.replacement_cost := :NEW.replacement_cost+1;
      :NEW.description := (:NEW.description || ' Mature audiences only');
    END IF;
  END;
/

/* Task 3 – Views */
  /* a. find the ‘Drama’ film with the highest replacement cost */
SELECT film.title, film.replacement_cost
FROM film, film_category, category
WHERE film.film_id = film_category.film_id AND film_category.category_id = category.category_id AND category.name = 'Drama' AND replacement_cost = (
  SELECT MAX(replacement_cost)
  FROM film, film_category, category
  WHERE film.film_id = film_category.film_id AND film_category.category_id = category.category_id AND category.name = 'Drama'
);

  /* b. create a (virtual) view that contains all the actors that have acted in the film that you obtained from 3a */
CREATE VIEW V_ACTOR_3B AS
SELECT actor.actor_id, actor.first_name, actor.last_name
FROM actor, film_actor, film
WHERE film.film_id = film_actor.film_id AND film_actor.actor_id = actor.actor_id AND film.film_id = (
  SELECT film.film_id
  FROM film, film_category, category
  WHERE film.film_id = film_category.film_id AND film_category.category_id = category.category_id AND category.name = 'Drama' AND replacement_cost=(
    SELECT MAX(replacement_cost)
    FROM film, film_category, category
    WHERE film.film_id = film_category.film_id AND film_category.category_id = category.category_id AND category.name = 'Drama'
  )
);

  /* c. V_DRAMA_ACTORS_2000 */
CREATE VIEW V_DRAMA_ACTORS_2000 AS
SELECT DISTINCT actor.actor_id, actor.first_name, actor.last_name
FROM actor, film_actor, film, film_category, category
WHERE film.film_id = film_actor.film_id AND film_actor.actor_id = actor.actor_id AND film.film_id= film_category.film_id AND film_category.category_id = category.category_id AND category.name = 'Drama' AND film.release_year = 2000;

  /* d. MV_DRAMA_ACTORS_2000 */
CREATE MATERIALIZED VIEW MV_DRAMA_ACTORS_2000
BUILD IMMEDIATE
AS
SELECT DISTINCT actor.actor_id, actor.first_name, actor.last_name
FROM actor, film_actor, film, film_category, category
WHERE film.film_id = film_actor.film_id AND film_actor.actor_id = actor.actor_id AND film.film_id= film_category.film_id AND film_category.category_id = category.category_id AND category.name = 'Drama' AND film.release_year = 2000;

  /* e. Execute SQL statements and report their query execution time. */ 
SET TIMING ON;
SELECT * FROM V_DRAMA_ACTORS_2000;
SELECT * FROM MV_DRAMA_ACTORS_2000;

/* Task 4 – Indexes */
  /* a. Compute how many actors share the same first and last name as each other */
SELECT CONCAT(CONCAT(first_name, ' '), last_name), COUNT(*)
FROM actor
GROUP BY CONCAT(CONCAT(first_name, ' '), last_name)
HAVING COUNT(*)>1;

  /* b. Function-based index */
CREATE INDEX IDX_NAME ON actor(CONCAT(CONCAT(first_name, ' '), last_name));

  /* c. Report the execution time and explain */
SELECT CONCAT(CONCAT(first_name, ' '), last_name), COUNT(*)
FROM actor
GROUP BY CONCAT(CONCAT(first_name, ' '), last_name)
HAVING COUNT(*)>1;

/* Task 5 – Execution Plan */
  /* a. list all information for the film with a film_id value of 18001. Report the plan chosen by the Oracle optimizer */
EXPLAIN PLAN FOR
SELECT *
FROM film
WHERE film_id = 18001;

SELECT PLAN_TABLE_OUTPUT FROM TABLE (DBMS_XPLAN.DISPLAY);

  /* b. Drop the primary key constraint from the film relation and re-execute the query and report the plan */
ALTER TABLE film DROP CONSTRAINT PK_FILMID;

EXPLAIN PLAN FOR
SELECT *
FROM film
WHERE film_id = 18001;

SELECT PLAN_TABLE_OUTPUT FROM TABLE (DBMS_XPLAN.DISPLAY);

  /* c. answer is in the report*/
