[![Build Status](https://travis-ci.org/sul-dlss/common-accessioning.svg?branch=master)](https://travis-ci.org/sul-dlss/common-accessioning) [![Coverage Status](https://coveralls.io/repos/sul-dlss/common-accessioning/badge.svg?branch=master&service=github)](https://coveralls.io/github/sul-dlss/common-accessioning?branch=master)

# Documentation

Check the [Wiki](https://github.com/sul-dlss/robot-master/wiki) in the robot-master repo.

# DOR common-accessioning Robots

## An overview of the workflow

You can see the steps of the workflow in `config/workflows/accessionWF`

You can see the dependencies and settings for each step in `config/workflows/accessionWF/process-config.yaml`

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

## Lite Objects

If you want to create a minimal `Dor::Item` that will exercise most of the common-accessioning robots, you can create a `Dor::AccessionLite` object.  To use:

- Go to the root of the deployed common-accessioning project
- To create a new Lite object, run the following:

  ```console
  ./bin/lite_obj create
  ```
- To reset the accessionWF workflow for a lite object, run the following:

  ```console
 ./bin/lite_obj reset {druid}
  ```

  The actual accessionWF being used is read from the file:
 `ROBOT_ROOT/config/workflows/accessionWF/lite.xml`

## Non-standard Robots

- public_xml_updater, aka republisher - Republishes public XML if certain datastreams have been updated in Fedora
    Started with the `bin/run_republisher_daemon` script.  See that script for start/stop syntax
- embargo_release
    Run from cron once a day to release items that are no longer under embargo

## Running tests
A simple "rake" should do everything you need

## Deployment

See `Capfile` for deployment instructions

## Versions
 - 1.7.0 Robots are now versioning-aware
 - 1.7.4 Updated dor-services to get latest moab-versioning.
 - 1.7.14 Desc metadata robot will raise and exception if the desc metadata couldnt be populated
 - 1.7.16 Update jhove-service to v1.0.2
 - 1.7.17 Updated dor-services to v3.21.0.
 - 1.8.0 Added disseminationWF:cleanup robot
 - 1.10.0 Embargo release of 20% visible items
 - 1.12.0 Latest dor-services and ruby 1.9.3 compatibility
