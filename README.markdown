TODO
====

1. Ticker log
2. Ticker more config (FFG)
3. Tv series
4. Pretty printing (plugins)

Wants
=====

* Incorporate with habitrpg
* Incorporated irc bot

Ticker
------

* manga updates
    1. mangareader
    2. mangastream
* tv updates (nextep)
* FFG game of thrones 2nd edition!
* netrunner datapacks (worldofboardgames/prisjakt)
* RSS feeds
* upcoming movies (sf, imdb, ... ?)

Organize

category (netrunner, manga, tv-series, ...)
type (news) ??
title (The Valley, One Piece, ...)
id (unique event id?)
tags (?)

Logger
------

* Training log
    Track gym progress
* Food list/planning
* Track books read
* Blog posts written
* Track github/bitbucket commits etc
* Log expenses/budget (replace ynab?)

Planner
-------

* Todos
* Calendar (incorporate/replace google calendar)
* Organize (replace org?)

Tech
====

Database backend
* Postgres?

* Perl? 5? 6? Probably for ticker backend.
* Some lisp?
* rust?
* Julia for plotting/graphs?

Inspiration
===========

<https://news.ycombinator.com/item?id=8024073>

<http://aprilzero.com>

Database
========

Use postgres backend

For login: `psql -U postgres`

Show databases: `\l`
Select database: `\c db`
List of tables: `\d`
Describe a table: `\d`
Run sql filee: `\i db.sql`

:)

Use database `me`

```{.sql}
CREATE DATABASE me
```

Remove events with unused objects:

```
DELETE FROM events WHERE object::jsonb ? 'category' = 'f';
```


Dates
=====

2015-02-15T15:00:00.000Z

<http://en.wikipedia.org/wiki/ISO_8601>

Perl
====

Run a single test:

```
perl6 t/file.t
```

Run several tests:

```
prove -re perl6
```
