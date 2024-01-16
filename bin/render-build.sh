#!/usr/bin/env bash
# exit on error
set -o errexit

bundle install
DISABLE_DATABASE_ENVIRONMENT_CHECK=1 ./bin/rails db:drop
./bin/rails db:create
./bin/rails db:migrate
./bin/rails assets:precompile
./bin/rails assets:clean
