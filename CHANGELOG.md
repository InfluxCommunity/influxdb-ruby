# Changelog

For the full commit log, [see here](https://github.com/influxdata/influxdb-ruby/commits/master).

## Unreleased changes

- None.

## v0.3.14, released 2017-02-06

- Added option `discard_write_errors` to silently ignore errors when writing
  to the server (#182, @mickey).
- Added `#list_series` and `#delete_series` to `InfluxDB::Client` (#183-186,
  @wrcola).

## v0.3.13, released 2016-11-23

- You can now `InfluxDB::Client#query`, `#write_points`, `#write_point` and
  `#write` now accept an additional parameter to override the database on
  invokation time (#173, #176, @jfragoulis).


## v0.3.12, released 2016-11-15

- Bugfix for broken Unicode support (regression introduced in #169).
  Please note, this is only properly tested on Ruby 2.1+ (#171).

## v0.3.11, released 2016-10-12

- Bugfix/Enhancement in `PointValue#escape`. Input strings are now scrubbed
  of invalid UTF byte sequences (#169, @ton31337).

## v0.3.10, released 2016-10-03

- Bugfix in `Query::Builder#quote` (#168, @cthulhu666).

## v0.3.9, released 2016-09-20

- Changed retry behaviour slightly. When the server responds with an incomplete
  response, we now assume a major server-side problem (insufficient resources,
  e.g. out-of-memory) and cancel any retry attempts (#165, #166).

## v0.3.8, released 2016-08-31

- Added support for named and positional query parameters (#160, @retorquere).

## v0.3.7, released 2016-08-14

- Fixed `prefix` handling for `#ping` and `#version` (#157, @dimiii).

## v0.3.6, released 2016-07-24

- Added feature for JSON streaming response, via `"chunk_size"` parameter
  (#155, @mhodson-qxbranch).

## v0.3.5, released 2016-06-09

- Reintroduced full dependency on "cause" (for Ruby 1.9 compat).
- Extended `Client#create_database` and `#delete_database` to fallback on `config.database` (#153, #154, @anthonator).

## v0.3.4, released 2016-06-07

- Added resample options to `Client#create_continuous_query` (#149).
- Fixed resample options to be Ruby 1.9 compatible (#150, @SebastianCoetzee).
- Mentioned in README, that 0.3.x series is the last one to support Ruby 1.9.

## v0.3.3, released 2016-06-06 (yanked)

- Added resample options to `Client#create_continuous_query` (#149).

## v0.3.2, released 2016-06-02

- Added config option to authenticate without credentials (#146, @pmenglund).

## v0.3.1, released 2016-05-26

- Fixed #130 (again). Integer values are now really written as Integers to InfluxDB.

## v0.3.0, released 2016-04-24

- Write queries are now checked against 204 No Content responses, in accordance with the official documentation (#128).
- Async options are now configurabe (#107).

## v0.2.6, released 2016-04-14

- Empty tag keys/values are now omitted (#124).

## v0.2.5, released 2016-04-14

- Async writer now behaves when stopping the client (#73).
- Update development dependencies and started enforcing Rubocop styles.

## v0.2.4, released 2016-04-12

- Added `InfluxDB::Client#version`, returning the server version (#117).
- Fixed escaping issues (#119, #121, #135).
- Integer values are now written as Integer, not as Float value (#131).
- Return all result series when querying multiple selects (#134).
- Made host cycling thread safe (#136).

## v0.2.3, released 2015-10-27

- Added `epoch` option to client constructor and write methods (#104).
- Added `#list_user_grants` (#111), `#grant_user_admin_privileges` (#112) and `#alter_retention_policy` (#114) methods.

## v0.2.2, released 2015-07-29

- Fixed issues with Async client (#101)
- Avoid usage of `gsub!` (#102)

## v0.2.1, released 2015-07-25

- Fix double quote tags escaping (#98)

## v0.2.0, released 2015-07-20

- Large library refactoring (#88, #90)
  - Extract config from client
  - Extract HTTP functionality to separate module
  - Extract InfluxDB management functions to separate modules
  - Add writer concept
  - Refactor specs (add cases)
  - Add 'denormalize' option to config
  - Recognize SeriesNotFound error
  - Update README
  - Add Rubocop config
  - Break support for Ruby < 2
- Added support for InfluxDB 0.9+ (#92)

## v0.1.9, released 2015-07-04

- last version to support InfluxDB 0.8.x
