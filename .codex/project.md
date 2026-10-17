# Prefect Worker Image 固有の指示

用語は `CONTEXT.md`、Worker Image Tagとreleaseの設計は `docs/adr/`、Copier回答と固有差分は `docs/copier.md` を参照します。既存の設計判断と変更が衝突する場合は明示してください。

## 検証

`.github/workflows/docker-quality-checks.yml` に従い、次を実行します。

```sh
shellcheck scripts/*.sh tests/*.sh .github/scripts/*.sh
bash tests/resolve-worker-image-tags.sh
bash tests/base-worker-image-postgresql-clients.sh
actionlint
```

Docker buildとsmoke testはworkflowの順序で、Base Worker Image、Process Worker Imageの順に実行します。ローカル検証ではimageをpushしません。両Dockerfileは `COPY` / `ADD` を使わず、追加のbuild context入力は不要です。

## リリース方針

テンプレートの公開機構は使いません。Worker Image Releaseの入力と公開条件は `README.md` と `.github/workflows/release-worker-images.yml` が正本です。

`version` はUpstream Prefect Image Tag、`revision` は任意のWorker Image Revisionです。projectのSemVerとして採番しないでください。release入力を変更しないテンプレート・文書更新ではWorker Image Releaseを行わず、テンプレート向けの `release:*` ラベルも不要です。
