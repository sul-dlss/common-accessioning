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

## Developers

### Configuration

Install `libvips` and `exiftool`, typically via `brew`.  These are pre-requisites for running the assemblyWF step that creates derivative JP2s.

The credentials for SideKiq Pro must be set on your laptop (e.g., in `.bash_profile`): `export BUNDLE_GEMS__CONTRIBSYS__COM=xxxx:xxxx`

You can get this value from the servers, just SSH into one of the app servers and echo the value:
```
echo $BUNDLE_GEMS__CONTRIBSYS__COM
```

Install the gems
```
bundle install
```

### Run the development stack

It's possible to invoke the jobs manually or have an interactive shell:

From the root of the robot project:

Interactive console:
```console
$ ROBOT_ENVIRONMENT=production ./bin/console
```

Running a single robot step manually (without checking current workflow status).  Note the workflow/step name should be the Module::Class name and not the workflow/step name
(e.g. "Accession::Publish" or "SpeechToText::FetchFiles")

```console
$ ./bin/run_robot --druid druid:12345 --environment production Accession::Publish
```

### Testing

A simple "rake" should do everything you need, which will run both rubocop and rspec.

```
rake
```

or just rubocop

```
rubocop
```

or just the tests

```
rspec
```

### Working on the console

During development, it can be useful to work with the objects available to the robots.  You can most easily do this on a server with content, such as stage.
This allows you to explore the data models and actions available.

```
cap stage ssh
ROBOT_ENVIRONMENT=production bin/console

druid='druid:qv402bt5465'
workflow_name='accessionWF'
process='end-accession'

object_client = Dor::Services::Client.object(druid)
cocina_object = object_client.find
workflow_service = LyberCore::WorkflowClientFactory.build(logger: nil)
workflow = LyberCore::Workflow.new(workflow_service:,druid:,workflow_name:,process:)

cocina_object.type
=> "https://cocina.sul.stanford.edu/models/book"
cocina_object.structural.contains.size
=> 17
workflow.status
=> "completed"
```

### Caption Cleanup

Files produced during media captioning can have specific phrases automatically removed (e.g. bad phrases that are produced by hallucinations).  There is a file that provides configuration on what is removed: `config/speech_to_text_filters.yaml` which accepts both strings and regular expressions.  Information on how to use it is provided in the top of the configuration file.

## Deployment

See `Capfile` for deployment instructions
