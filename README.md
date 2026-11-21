## Inject Some SQL

These are sample Rails applications for demonstrating many ways SQL can be injected in Rails.

### Setup

Clone the repo:

```
git clone https://github.com/presidentbeef/inject-some-sql.git
```

Pick Rails 8, 6, 5, 4 or 3. They each have their own subdirectory.

```
cd inject-some-sql/rails5
```

In the subdirectory, install dependences and set up the database:

```
bundle install
rake db:setup db:seed
```

Rails 8 is different from the others: its examples are about SQL injection
reaching the Solid Cache-backed `solid_cache_entries` table, not just
application tables, and that needs Postgres (not SQLite) to actually
demonstrate - see `rails8/README.md` for its own setup.

### Using a different Ruby build

Each app's Ruby version is pinned by its own `.ruby-version`. If you're using
[rbenv](https://github.com/rbenv/rbenv), override it with the `RBENV_VERSION`
environment variable - for example, to use a patched install or a version not 
included in rbenv's registry:

```
RBENV_VERSION=my-patched-ruby bundle install
```

### Run

Typical Rails start: 

```
rails s
```

Open up [localhost:3000](http://localhost:3000) in a browser. 

### Reset Database

It's easy to mess up a database with SQL injection. The server does attempt to
reset the database after each query, but that isn't foolproof.

To completely reset:

```
rake db:drop db:migrate db:seed
```

### Inject SQL!

The site lists a whole bunch of ActiveRecord queries.

Each query has input for a single parameter (although some queries may actually
have more than one). A sample injection is provided. Clicking "Run!" will run
the query shown.

## Adding/Modifying Queries

All queries are generated from `app/models/queries.rb`.

## Limitations

* This is a single player game because the SQL query is stored in a global variable.

## License

This code is made available under the MIT license.
