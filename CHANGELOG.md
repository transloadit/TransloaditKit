## Ideas

- [ ] Use websockets to pass immediate assembly status update events, vs polling
- [ ] Use the same networking between TusKit & TransloaditKit

## v1.0.0

- [ ] More elaborate section how to use the project with examples in the README.md. Explain that you should roll your own filepicker code.  Add an example that showcases working with Templates (this is the recommended way)
- [ ] Write a Release Blogpost (the more technical background, the better :)
- [x] Have call with to kick things off
- [x] Get Travis tests on their feet: https://travis-ci.org/transloadit/TransloaditKit/builds/224287281
- [x] Create the Assembly right before starting the upload, so that you know the machine it runs on, and can upload to the tusd server on that same machine: e.g. `https://api2-anurati.transloadit.com/resumable/files/`. So if you do a 
`> POST api2.transloadit.com/assemblies`
you get back an `assembly_ssl_url` in the resulting JSON body like:
`https://anurati.transloadit.com/assemblies/5bb26c001ad711e7a3cb9b5d337d8300`. This contains the `websocket_url` and the `tusd_url`. You'll use the `tusd_endpoint` to post files to.
- [x] Pass the `assembly_url` as meta data to tus, vs the id as mentioned in the latest wiki over at https://github.com/tus/tusd/wiki/Uploading-to-Transloadit-using-tus
- [x] Poll assembly url json so and introduce the option to `wait` for the encoding/storing (vs fire & forget right after the upload concludes). Here are the status codes: https://transloadit.com/docs/api-docs/#27-response-codes
- [x] Verify we're using HTTPS by default everywhere
- [x] Add a screencast/demo
- [x] Rename to TransloaditKIT (i think? whatever you think is best here @MMasterson)
- [x] We'll skip the Billing & Template APIs for now, as our main target is ios devices and these have very low priority
- [x] Get README.md in line with our other SDKs. That means it has at least one:`## Intro`, `## Install` `## Usage`, `## Example` (see <https://github.com/transloadit/node-sdk#intro>). @ifedapoolarewaju might be able answer questions / provide guidance here.
- [x] Check for more final [statuses](https://transloadit.com/docs/api-docs/#27-response-codes) (REQUEST_ABORTED, ASSEMBLY_CANCELED, ASSEMBLY_COMPLETED and ASSEMBLY_CRASHED (not in "ok" key but "error"))
- [x] Add a travis test that does an integration test against our service testing the above, including the AssemblyStatus polling so it can check the dimensions on the resized image. Then we really know for sure 😄 (and get All travis tests passing ofc)
- [x] Use `transloadit` for podname, keep TransloaditKit as repo and project name, deprecate all other projects by stating that, and linking to the new
- [x] Debug why template creation hangs forever /cc @tim-kos 
- [x] Debug why template creation fails /cc @tim-kos 
- [x] Move out auth keys & secrets from Git, and into e.g. env files and Travis CI environment secrets (or something else secure that's idiomatic to Apple development)
