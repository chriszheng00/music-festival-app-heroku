CREATE TABLE "schema_migrations" ("version" varchar NOT NULL);
CREATE UNIQUE INDEX "unique_schema_migrations" ON "schema_migrations" ("version");
CREATE TABLE "festivals" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar, "latitude" float, "longitude" float, "start_date" date, "date" varchar, "location" varchar, "website" varchar, "description" text, "price" integer, "camping" varchar, "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL, "end_date" date);
CREATE TABLE "artists" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar, "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL);
CREATE TABLE "performances" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "festival_id" integer, "artist_id" integer, "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL);
CREATE TABLE "genres" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar, "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL);
CREATE TABLE "festival_genres" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "genre_id" integer, "festival_id" integer, "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL);
CREATE INDEX "index_festival_genres_on_genre_id" ON "festival_genres" ("genre_id");
CREATE INDEX "index_festival_genres_on_festival_id" ON "festival_genres" ("festival_id");
INSERT INTO schema_migrations (version) VALUES ('20160317195857');

INSERT INTO schema_migrations (version) VALUES ('20160322024101');

INSERT INTO schema_migrations (version) VALUES ('20160322183133');

