# prefect-worker

## イメージ

`version` ファイルには、Base Worker Image で使う Upstream Prefect Image Tag を保存します。
`revision` ファイルには、Worker Image Revision を保存します。通常リリースでは空にします。

Worker Image は Docker Hub の `mizucopo/prefect-flows` に公開します。
イメージタグは Upstream Prefect Image Tag を先頭に置き、その後ろに Worker Image の種類を付けます。
`latest` タグは公開しません。

同じ Upstream Prefect Image Tag と Worker Image の種類に対して修正版を再公開する場合は、`revision` ファイルに Worker Image Revision を設定します。

```sh
printf "r1\n" > revision
```

## リリース

`main` ブランチで `version`、`revision`、または `.github/workflows/release-worker-images.yml` が更新されると、GitHub Actions が Worker Image Release を作成します。
手動で実行する場合も、GitHub Actions の `Release Worker Images` workflow を `main` ブランチから実行します。

workflow は `version` と `revision` から Worker Image Release Tag と Worker Image Tag を計算します。

```sh
RELEASE_TAG="prefect-$(cat version)"
BASE_IMAGE_TAG="prefect-$(cat version)-base"
PROCESS_IMAGE_TAG="prefect-$(cat version)-process"
```

`revision` が空でない場合は、それぞれの末尾に `-${revision}` を付けます。

workflow は Base Worker Image と Process Worker Image を Docker Hub に push した後、annotated git tag と GitHub Release を作成します。
GitHub Release には Docker Hub の `mizucopo/prefect-flows` へのリンクと、対応する Base Worker Image / Process Worker Image の参照を記載します。

Docker Hub への push には repository secret の `DOCKERHUB_TOKEN` を使います。
Docker Hub のユーザー名は `mizucopo` として扱います。

既存の Docker tag や、別 commit を指す既存の Worker Image Release Tag は上書きしません。
修正版を再公開する場合は、`revision` を `r1`、`r2` のように更新して新しい Worker Image Release として作成します。

## 手動ビルド

イメージタグ用の変数を設定します。

```sh
IMAGE_REPOSITORY="mizucopo/prefect-flows"
PREFECT_IMAGE_TAG="$(cat version)"
REVISION="$(cat revision)"
```

イメージタグを計算します。

```sh
BASE_IMAGE_TAG="prefect-${PREFECT_IMAGE_TAG}-base${REVISION:+-${REVISION}}"
PROCESS_IMAGE_TAG="prefect-${PREFECT_IMAGE_TAG}-process${REVISION:+-${REVISION}}"
```

最初に Base Worker Image をビルドします。

```sh
docker build \
  --build-arg PREFECT_IMAGE_TAG="${PREFECT_IMAGE_TAG}" \
  -t "${IMAGE_REPOSITORY}:${BASE_IMAGE_TAG}" \
  -f images/base/Dockerfile .
```

Base Worker Image を push します。

```sh
docker push "${IMAGE_REPOSITORY}:${BASE_IMAGE_TAG}"
```

公開済みの Base Worker Image から Process Worker Image をビルドします。

```sh
docker build \
  --build-arg BASE_IMAGE="${IMAGE_REPOSITORY}:${BASE_IMAGE_TAG}" \
  -t "${IMAGE_REPOSITORY}:${PROCESS_IMAGE_TAG}" \
  -f images/process/Dockerfile .
```

Process Worker Image を push します。

```sh
docker push "${IMAGE_REPOSITORY}:${PROCESS_IMAGE_TAG}"
```

## Compose

公開済みの Process Worker Image を使い、Host Docker Daemon の Docker socket をマウントします。

```yaml
prefect-process-worker:
  image: "mizucopo/prefect-flows:prefect-3.7.3-python3.14-process"
  restart: unless-stopped
  container_name: prefect-process-worker
  networks:
    - minipc
  depends_on:
    prefect-server:
      condition: service_healthy
  environment:
    PREFECT_API_URL: "http://prefect-server:4200/api"
  volumes:
    - /opt/prefect:/app
    - /var/run/docker.sock:/var/run/docker.sock
  working_dir: /app/flows
  command: sh -c "uv sync --frozen --no-dev && . .venv/bin/activate && prefect worker start --pool process-pool --type process"
```

## アーキテクチャ決定

- [Worker Image のタグ](docs/adr/0001-worker-image-tags.md)
- [Worker Image release automation](docs/adr/0002-worker-image-release-automation.md)
