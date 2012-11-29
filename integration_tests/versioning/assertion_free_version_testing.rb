# Creates a new object
# Creates a test workflow, setting the accessioned lifecycle to completed
# Archives testWF
# Opens, then closes a version

i = Dor::Item.new
ds = i.datastreams['versionMetadata']
ds.content = ds.ng_xml.to_s
i.save

xml =<<-XML
<workflow id="testWF">
     <process name="start-ingest" status="completed" />
    <process name="step-two" status="completed" lifecycle="accessioned"/>
</workflow>
XML

Dor::WorkflowService.create_workflow 'dor', i.pid, 'testWF', xml
Dor::WorkflowService.archive_workflow 'dor', i.pid, 'testWF'

i.open_new_version
i.new_version_open?
i.close_version
i.new_version_open?