[![CircleCI](https://circleci.com/gh/sul-dlss/common-accessioning.svg?style=svg)](https://circleci.com/gh/sul-dlss/common-accessioning)
[![Code Climate Test Coverage](https://codeclimate.com/github/sul-dlss/common-accessioning/badges/coverage.svg)](https://codeclimate.com/github/sul-dlss/common-accessioning/coverage)

# DOR consolidated robots

This repository contains a number of Sidekiq background jobs.
The jobs are enqueued by [workflow-server-rails](https://github.com/sul-dlss/workflow-server-rails).

## Workflows
The following workflows are supported by this repository:

* Assembly - https://github.com/sul-dlss/workflow-server-rails/blob/main/config/workflows/assemblyWF.xml
  * Transforms the stubContentMetadata.xml provided by Goobi into contentMetadata.xml
  * Creates derivative JP2 files for access and preservation if the object type is image or page.
  * Computes checksums for files in contentMetadata.xml
  * Adds exif, mimetype, file size data to contentMetadata
  * Kicks off accessioning
* Accession - https://github.com/sul-dlss/workflow-server-rails/blob/main/config/workflows/accessionWF.xml
  * Moves the metadata from the workspace into the SDR.
  * Moves objects into preservation.
* Dissemination - https://github.com/sul-dlss/workflow-server-rails/blob/main/config/workflows/disseminationWF.xml
  * cleans up the workspace after accessioning
* Release - https://github.com/sul-dlss/workflow-server-rails/blob/main/config/workflows/releaseWF.xml
  * Moves files to PURL and updates the marc record in Folio (adding fields that are needed for SearchWorks indexing and display)
* Goobi - https://github.com/sul-dlss/workflow-server-rails/blob/main/config/workflows/goobiWF.xml
  * informs goobi there are new items
* OCR - https://github.com/sul-dlss/workflow-server-rails/blob/main/config/workflows/ocrWF.xml
  * Performs OCR for images/PDFs/related content
* Caption - https://github.com/sul-dlss/workflow-server-rails/blob/main/config/workflows/captionWF.xml
  * Performs captioning for audio/video content

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

Note that `libvips` and `exiftool` are pre-requisites for running the assemblyWF step that creates derivative JP2s.

## Running tests
A simple "rake" should do everything you need

## Deployment

See `Capfile` for deployment instructions
