# Two In A Million: A Coding Challenge

## Setup

For convenience, the recommended way to start the server is by using Docker, if you have it installed.
Run `docker compose up` and wait until the command stops producing output and
one of the final lines says "Running … at 0.0.0.0:3000 (http)".

Alternatively, you can run the app on your host machine.
First, please, make sure that you have PostgreSQL installed and listening on port 5432,
and set the environment variables POSTGRES_USER and POSTGRES_PASSWORD to contain the DB server credentials.
Then, run the server as follows:

  * `mix setup` to install dependencies and prepare the database,
  * `mix phx.server` to start the Phoenix endpoint.

Either way, once you have the server running, you can visit [`localhost:3000`](http://localhost:3000) from your browser.

## Structure

`LotteryController` is supporting the endpoint, forwarding requests to the `LotteryServer` and sending back the responses.

`LotteryServer` is where we trigger the regular updates of the user points and the `max_number`, and pick the current winners. It is automatically started when the application launches. It delegates to `Users` to perform database queries.


## Tests

To run the tests in a Docker container, issue `docker compose run app test`. To do the same locally, use the standard `mix test`.
