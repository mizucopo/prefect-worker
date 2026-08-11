# Copier運用

このリポジトリは `mizucopo/repo-template` の生成物を基準にしつつ、Prefect Worker Image 固有のビルドとリリースを管理します。

## 安全な更新手順

1. 作業ツリーが clean であることを確認する
2. 次のコマンドで、記録済みの回答値を使って更新する

   ```sh
   XDG_CACHE_HOME=/private/tmp/copier-cache \
     UV_CACHE_DIR=/private/tmp/uv-cache \
     copier update --trust --defaults
   ```

3. 生成差分をファイルごとに確認し、後述の固有差分を保持する
4. shell test、workflow lint、Docker build など適用可能な検証を実行する

強制的な `copier recopy` は、`version` などの固有差分を上書きするため、通常の更新には使いません。最新テンプレートの素の生成結果を確認する場合は、一時ディレクトリへ `copier copy` して比較します。

## メタデータ

`_src_path` と `_commit` は通常の回答値ではなく、Copier が更新元と適用済みrevisionを追跡するためのメタデータです。`_commit` は `copier update` によって更新します。

| 項目 | 現在値 | 判定と理由 |
| --- | --- | --- |
| `_src_path` | `git@github.com:mizucopo/repo-template.git` | 正しい。利用するテンプレートリポジトリを指す |
| `_commit` | Copierが記録するtemplate revision | 正しい。具体値は `.copier-answers.yml` を参照し、`copier update` で更新する |

## 回答値

| 項目 | 現在値 | 判定と理由 |
| --- | --- | --- |
| `author_name` | `みず` | 正しい。MIT LICENSE の著作者名と一致する |
| `author_email` | `mizu.copo@gmail.com` | 正しい。リポジトリのcommit作者メールと一致する。テンプレート標準のrelease workflowを有効にした場合は、`author_name` とともにannotated tagの作者設定に使われる |
| `docker_image_name` | `prefect-worker` | 正しい。Worker Imageの公開先として設定した Docker Hub repository `mizucopo/prefect-worker` と一致する |
| `docker_registry` | `mizucopo` | 正しい。Docker Hub のnamespaceおよびログインユーザーと一致する |
| `use_aws_ecr` | `false` | 正しい。配布先は AWS ECR ではなく Docker Hub |
| `use_chrome_extension` | `false` | 正しい。Chrome Extension のsource、package、buildは存在しない |
| `use_docker` | `true` | 正しい。このリポジトリの主要成果物は2種類の Docker image |
| `use_dependabot_docker` | `false` | 正しい。Dockerfileの `FROM` imageをbuild `ARG` で指定しており、Docker Dependabotの更新対象にならない |
| `use_dependabot_github_actions` | `true` | 正しい。固有workflowを含むGitHub Actionsのpin更新を監視する |
| `use_gh_actions_docker_quality` | `false` | 正しい。テンプレート標準は単一imageのbuild/smokeを前提とするため、依存順序のあるBase/Process 2 imageを検証する固有workflowを保持する |
| `use_gh_actions_docker_release` | `false` | 正しい。テンプレート標準は単一imageと `latest` tagを前提とするため、2種類のimmutableなWorker Imageを扱う固有workflowには適用できない |
| `use_gh_actions_pr_tag_check` | `false` | 正しい。Worker Image Release Tagと2種類のDocker tagを検査する固有workflowを使う |
| `use_gh_actions_release` | `false` | 正しい。Docker image公開後にGitHub Releaseを作る固有workflowを使う |
| `use_mit_license` | `true` | 正しい。MIT LICENSEを使用している |
| `use_python` | `false` | 正しい。親imageにはPythonが含まれるが、このリポジトリ自体はPython packageやPython toolchainを管理しない |
| `use_rust` | `false` | 正しい。Rust sourceとCargo projectは存在しない |
| `use_tauri` | `false` | 正しい。Tauri applicationは存在しない |

無効なruntimeや配布機能にだけ表示される条件付き質問は、回答ファイルへ推測で追加しません。現在は `python_version`、`rust_version`、`node_version`、Chrome Extension/Tauriの各設定、AWS account/region、Chrome Extension release設定が対象外です。

現在の `copier.yml` には、Shell runtime、テンプレート外のCI、Shell test、ドキュメント、デプロイを個別に表す回答項目はありません。これらは存在しない回答値を追加せず、リポジトリ固有のscript、workflow、README、ADRとして管理します。package managerも利用していないため、Python、Rust、Node.jsのruntime supportを有効化しません。

## テンプレート差分

### 解消する古い、または不要な独自差分

- `AGENTS.md` と `CLAUDE.md` は、最新テンプレートのIssue-first branch workflowと整形を採用する
- `.gitignore` は、最新テンプレートが追加したRust、Node.js、coverageの共通ignoreを採用する
- `.copier-answers.yml` は、現在のtemplate schemaで常時管理する `author_email`、無効なruntime回答の明示的な `false`、最新 `_commit` を記録する
- `.github/dependabot.yml` のDocker監視はbuild `ARG` 経由のimageを更新できないため削除し、独立したGitHub Actions監視だけをテンプレートから生成する

### `repo-template` 側へ汎用化する共通変更

Docker利用とDocker Dependabot監視を分離する共通変更は、[`repo-template` Issue #31](https://github.com/mizucopo/repo-template/issues/31) と [PR #32](https://github.com/mizucopo/repo-template/pull/32) で解消しました。このリポジトリは `use_docker: true` と `use_dependabot_docker: false` を併用し、Docker関連ファイルを維持したまま動作しない監視を生成しません。

独立したGitHub Actions監視は、[`repo-template` Issue #40](https://github.com/mizucopo/repo-template/issues/40) とPR #61で共通化されました。このリポジトリは `use_dependabot_github_actions: true` を記録し、固有release workflowを通常のrelease入力に含めずにaction pinだけを更新できます。

### このリポジトリに残す固有差分

- `version` はproject SemVerではなくUpstream Prefect Image Tagを保持する。親imageと公開tagを決める業務値であり、汎用テンプレートの `0.1.0` へ戻せない
- `revision` は同じUpstream Prefect Image Tagを再公開する場合だけ使うWorker Image Revisionを保持する。テンプレート標準releaseに同じ概念はない
- `.github/workflows/check-worker-image-release.yml` はgit tagと2種類のDocker Hub tagをmerge前に検査する
- `.github/workflows/docker-quality-checks.yml` はBase Worker Imageを検証・buildした後、そのlocal imageを親にProcess Worker Imageをbuildしてsmoke testするため、単一image向けのテンプレート標準workflowへ置換しない
- `.github/workflows/release-worker-images.yml` はBase Worker Imageを先に公開し、それを親にProcess Worker Imageを公開してからgit tagとGitHub Releaseを作る
- `images/`、`scripts/`、`tests/`、`README.md`、`CONTEXT.md`、`docs/adr/` はWorker Imageの機能、用語、検証、設計判断を管理するため、汎用テンプレートへ統合しない
