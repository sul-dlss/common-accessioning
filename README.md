[![Build Status](https://travis-ci.org/sul-dlss/common-accessioning.svg?branch=master)](https://travis-ci.org/sul-dlss/common-accessioning) [![Coverage Status](https://coveralls.io/repos/sul-dlss/common-accessioning/badge.svg?branch=master&service=github)](https://coveralls.io/github/sul-dlss/common-accessioning?branch=master)

# DOR consolidated robots

This repository contains a number of Resque background jobs.
The jobs are enqueued by [workflow-server-rails](https://github.com/sul-dlss/workflow-server-rails).

Most of the jobs are run by [resque-pool](https://github.com/nevans/resque-pool) but some are invoked as cron jobs.  See `config/schedule.rb` for those.

## Workflows
The following workflows are supported by this repository:

* Assembly - Creates files in the workspace for a new object and kicks off accessioning
* Accession - Moves the metadata from the workspace into Fedora.  Moves files into preservation.
* Dissemination - cleans up the workspace after accessioning
* Release - Moves files to PURL and updates the marc record in the ILS
* Goobi notify - informs goobi there are new items
* ETD Submit - Starts accessioning for ETD objects and updates the ILS

## For developers
It's possible to invoke the jobs manually or have an interactive shell:

From the root of the robot project:

Interactive console:
```console
$ ROBOT_ENVIRONMENT=production ./bin/console
```

Running a single robot step manually (without checking current workflow status):
```console
$ ./bin/run_robot --druid druid:12345 --environment production Accession::Publish
```

## Running tests
A simple "rake" should do everything you need

## Deployment

See `Capfile` for deployment instructions
