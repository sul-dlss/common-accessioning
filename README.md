[![Build Status](https://travis-ci.org/sul-dlss/common-accessioning.svg?branch=master)](https://travis-ci.org/sul-dlss/common-accessioning) [![Coverage Status](https://coveralls.io/repos/sul-dlss/common-accessioning/badge.svg?branch=master&service=github)](https://coveralls.io/github/sul-dlss/common-accessioning?branch=master)

# DOR consolidated robots

This repository contains a number of Resque background jobs.
The jobs are enqueued by [robot-master](https://github.com/sul-dlss/robot-master).

The [robot-master wiki](https://github.com/sul-dlss/robot-master/wiki) has more documenation about our robots.

## Execution

Should be run from the root of the robot project
Assumes there's a `ROBOT_ROOT/.rvmrc` file that will load the correct ruby version and gemset, if necessary

```console
robot_root$ ruby ./bin/run_robot accessionWF publish
```

With Options
Options must be placed BEFORE workflow and robot name:

```console
robot_root$ ruby ./bin/run_robot --druid druid:12345 accessionWF publish
```

From cron:

```
* * * * bash --login -c 'cd /path/to/robot_root && ruby./bin/run_robot.rb accessionWF publish' > /home/deploy/crondebug.log 2>&1
```

## Non-standard Robots

- public_xml_updater, aka republisher - Republishes public XML if certain datastreams have been updated in Fedora
    Started with the `bin/run_republisher_daemon` script.  See that script for start/stop syntax
- embargo_release
    Run from cron once a day to release items that are no longer under embargo

## Running tests
A simple "rake" should do everything you need

## Deployment

See `Capfile` for deployment instructions

## Development

Run `docker-compose` to bring up Redis which is a dependency of Resque.
