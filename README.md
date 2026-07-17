# prefect-worker

Prefect の Process Work Pool 向け Worker Image をビルドし、Docker Hub に公開するためのリポジトリです。

## 管理するもの

このリポジトリは、次の Worker Image を Docker Hub の `mizucopo/prefect-flows` に公開します。

- Base Worker Image: Prefect 公式イメージを親にし、`gzip` コマンドと PostgreSQL 16/17/18 のクライアントツールを実行できる共通イメージ
- Process Worker Image: Base Worker Image に Docker CLI を追加した Process Work Pool 向けイメージ

`latest` タグは公開しません。Worker Image Tag は Upstream Prefect Image Tag、Worker Image の種類、必要に応じて Worker Image Revision から作ります。

Copier の回答値、テンプレートとの差分、安全な更新手順は [Copier運用](docs/copier.md) に記録しています。

## リリースする

通常の Worker Image Release では、`version` に Upstream Prefect Image Tag を書き、`revision` は空にします。

```sh
printf "3.7.4-python3.14\n" > version
: > revision
```

`version` には `prefect-` prefix を付けません。

同じ Upstream Prefect Image Tag と Worker Image の種類に対して修正版を再公開する場合だけ、`revision` に `r1`、`r2` のような Worker Image Revision を書きます。

```sh
printf "r1\n" > revision
```

`main` ブランチで `version`、`revision`、`images/base/Dockerfile`、`images/process/Dockerfile`、`scripts/resolve-worker-image-tags.sh`、または `.github/workflows/release-worker-images.yml` が更新されると、GitHub Actions が Worker Image Release を作成します。
Pull Requestでは同じファイルが変更された場合だけ、予定するgit tagとDocker Hub tagが未使用かを検査します。リリース対象を変更しない文書や設定だけのPull Requestでもworkflowは成功を報告し、重複タグ検査だけを省略します。
手動で実行する場合も、GitHub Actions の `Release Worker Images` workflow を `main` ブランチから実行します。

## リリースで作られるもの

`version` が `3.7.4-python3.14`、`revision` が空の場合、workflow は次の名前を使います。

| 種類 | 名前 |
| --- | --- |
| Worker Image Release Tag | `3.7.4-python3.14` |
| Base Worker Image | `mizucopo/prefect-flows:3.7.4-python3.14-base` |
| Process Worker Image | `mizucopo/prefect-flows:3.7.4-python3.14-process` |

`revision` が `r1` の場合は、それぞれの末尾に `-r1` を付けます。

workflow は次の順序でリリースします。

1. Worker Image Release Tag と Worker Image Tag が未使用であることを確認する
2. Base Worker Image を build して Docker Hub に push する
3. 公開済みの Base Worker Image から Process Worker Image を build して Docker Hub に push する
4. annotated git tag を作成する
5. GitHub Release を作成し、対応する Worker Image の参照を書く

Docker Hub への push には repository secret の `DOCKERHUB_TOKEN` を使います。Docker Hub のユーザー名は `mizucopo` として扱います。

既存の Docker tag や、別 commit を指す既存の Worker Image Release Tag は上書きしません。`main` ブランチ向けの Pull Request では、`Check Worker Image Release` workflow が同じ tag を事前に確認します。いずれかの tag が既に存在する場合、その Pull Request は merge 前に失敗します。

## タグ計算

```sh
RELEASE_TAG="$(cat version)"
BASE_IMAGE_TAG="$(cat version)-base"
PROCESS_IMAGE_TAG="$(cat version)-process"
```

`revision` が空でない場合は、それぞれの末尾に `-${revision}` を付けます。

## 手動ビルド

イメージタグ用の変数を設定します。

```sh
IMAGE_REPOSITORY="mizucopo/prefect-flows"
PREFECT_IMAGE_TAG="$(cat version)"
REVISION="$(cat revision)"
```

イメージタグを計算します。

```sh
BASE_IMAGE_TAG="${PREFECT_IMAGE_TAG}-base${REVISION:+-${REVISION}}"
PROCESS_IMAGE_TAG="${PREFECT_IMAGE_TAG}-process${REVISION:+-${REVISION}}"
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

Base Worker Image では、コンテナ内で `gzip` を PATH から直接実行できます。

また、PostgreSQL 16/17/18 のクライアントツールを versioned path から実行できます。複数 version を同居させるため、PostgreSQL クライアントを使う Flow では次のパスを指定します。

| PostgreSQL | `psql` | `pg_dumpall` | `pg_dump` |
| --- | --- | --- | --- |
| 16 | `/usr/lib/postgresql/16/bin/psql` | `/usr/lib/postgresql/16/bin/pg_dumpall` | `/usr/lib/postgresql/16/bin/pg_dump` |
| 17 | `/usr/lib/postgresql/17/bin/psql` | `/usr/lib/postgresql/17/bin/pg_dumpall` | `/usr/lib/postgresql/17/bin/pg_dump` |
| 18 | `/usr/lib/postgresql/18/bin/psql` | `/usr/lib/postgresql/18/bin/pg_dumpall` | `/usr/lib/postgresql/18/bin/pg_dump` |

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
  image: "mizucopo/prefect-flows:3.7.4-python3.14-process"
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
