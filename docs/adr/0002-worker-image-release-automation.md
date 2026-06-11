# Worker Image release automation

Worker Image Releases are automated from `main` so that each release produces a pair of immutable Docker Hub tags, an annotated Worker Image Release Tag, and a GitHub Release that points back to the Docker Hub repository. The workflow derives names from the Upstream Prefect Image Tag in `version` and the optional Worker Image Revision in `revision`, refuses to overwrite existing Docker or git tags, and creates the GitHub Release only after both Worker Images have been pushed so that a published release always points to available images.

Pull Requests targeting `main` run the same release tag calculation as a pre-merge check and fail if the Worker Image Release Tag or either Worker Image Tag already exists. This keeps duplicate release identifiers from reaching `main`, where the release workflow would otherwise fail after merge.
