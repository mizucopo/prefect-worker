# Prefect Worker Images

This context describes the Docker images managed for Prefect work pools.

## Language

**Work Pool**:
A Prefect execution grouping that controls where matching flow runs are picked up and executed.
_Avoid_: Pool

**Process Work Pool**:
The existing Work Pool named `process-pool`, used to run Wrapper Flows that can start Role Image containers.
_Avoid_: process pool

**Worker Image**:
A Docker image managed by this repository that runs a Prefect Worker for the Process Work Pool.
_Avoid_: Pool Image

**Worker Image Repository**:
The Docker Hub repository `mizucopo/prefect-flows`, used as the shared publishing location for Worker Images managed by this repository.
_Avoid_: image destination, registry

**Base Worker Image**:
The shared parent image for Worker Images in this repository.
_Avoid_: base, common image

**Upstream Prefect Image Tag**:
The Prefect-provided Docker image tag used as the parent image for the Base Worker Image.
_Avoid_: version

**Worker Image Tag**:
A Docker tag for a Worker Image that starts with the Upstream Prefect Image Tag and ends with Worker Image-specific qualifiers such as the image variant and optional revision.
_Avoid_: version tag, custom tag

**Initial Worker Image Tag**:
A Worker Image Tag without a Worker Image Revision, used for the first publication of a Worker Image for a given Upstream Prefect Image Tag and image variant.
_Avoid_: latest, unversioned tag

**Worker Image Revision**:
An optional Worker Image Tag suffix used only when republishing a Worker Image from this repository for the same Upstream Prefect Image Tag and image variant.
_Avoid_: patch version, Prefect version

**Worker Image Release**:
The publication of the Base Worker Image and Process Worker Image for one Upstream Prefect Image Tag and optional Worker Image Revision.
_Avoid_: Docker release, version release

**Worker Image Release Tag**:
A git tag that marks the repository commit for a specific Upstream Prefect Image Tag and optional Worker Image Revision.
_Avoid_: version tag, image tag

**Process Worker Image**:
The Worker Image that extends the corresponding Base Worker Image with Docker CLI access for Wrapper Flows.
_Avoid_: Docker Worker Image

**Role Image**:
A Docker image managed outside this repository that contains an existing containerized batch workload to be scheduled by Prefect. It does not contain Prefect flow definitions or depend on Prefect.
_Avoid_: Pool Image, Worker Image, batch image

**Deployment**:
A Prefect scheduleable unit that assigns a flow run to a Work Pool and provides runtime job variables such as the Role Image to execute.
_Avoid_: job, schedule

**Wrapper Flow**:
A thin Prefect flow that schedules a Prefect-unaware Role Image by starting it as a Docker container.
_Avoid_: Role Image, Docker Worker

**Host Docker Daemon**:
The Docker daemon on the host machine, accessed by the Worker Image through a mounted Docker socket. The Worker Image provides Docker CLI access but does not run Docker-in-Docker.
_Avoid_: Docker-in-Docker, container daemon

**Worker**:
A Prefect process that monitors a Work Pool and submits flow runs to the configured execution backend.
_Avoid_: Worker Image
