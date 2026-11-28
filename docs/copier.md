# Copier運用

このリポジトリは `mizucopo/repo-template` の生成物を基準にしつつ、Prefect Worker Image 固有のビルドとリリースを管理します。

## 安全な更新手順

1. 作業ツリーが clean であることを確認する
2. 次のコマンドで、記録済みの回答値を使って更新する

   ```sh
   XDG_CACHE_HOME=/private/tmp/copier-cache \
     UV_CACHE_DIR=/private/tmp/uv-cache \
     copier update --trust --defaults --vcs-ref HEAD
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
| `project_name` | `prefect-worker` | 正しい。リポジトリ名とWorker Imageの名前に一致する |
| `project_description` | `Prefect Process Work Pool向けWorker Dockerイメージ` | 正しい。READMEと管理するimageの用途に一致する |
| `project_version` | `3.8.2` | 初期生成時のSemVer回答として保持する。現在のUpstream Prefect Image Tagは `version` が正本であり、この回答から採番しない |
| `use_version_management` | `true` | 新設項目の既定値を採用する。Worker Imageの公開入力として `version` を保持する |
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
| `use_gh_actions_docker_release` | `false` | 正しい。単一image向けの標準releaseは使わず、2種類のimmutableなWorker Imageを扱う固有workflowを保持する |
| `use_gh_actions_docker_project_pipeline` | `false` | 採番コミット、タグ確定時点、重複検査と復旧の動作が現行と異なるため、共通 release を有効化しない |
| `use_repo_template_policy` | `true` | 共通設定と workflow の逸脱を PR で検査する。既存運用に必要な workflow 3 本だけを完全パスで例外にする |
| `repo_template_policy_ruleset_source` | `false` | 個人所有の採用先なので通常の PR チェックを維持する。組織 Ruleset 用のソースは生成しない |
| `use_gh_actions_codeql` | `false` | 新設項目の既定値を採用する。CodeQL workflowの生成やGitHub側の設定変更は行わない |
| `use_gh_actions_release` | `false` | 正しい。Docker image公開後にGitHub Releaseを作る固有workflowを使う |
| `use_mit_license` | `true` | 正しい。MIT LICENSEを使用している |
| `use_python` | `false` | 正しい。親imageにはPythonが含まれるが、このリポジトリ自体はPython packageやPython toolchainを管理しない |
| `use_rust` | `false` | 正しい。Rust sourceとCargo projectは存在しない |
| `use_tauri` | `false` | 正しい。Tauri applicationは存在しない |

無効なruntimeや配布機能にだけ表示される条件付き質問は、回答ファイルへ推測で追加しません。現在は `python_version`、`rust_version`、`node_version`、Chrome Extension/Tauriの各設定、AWS account/region、Chrome Extension release設定が対象外です。

`repo_template_tauri_branding_assets_created: false` はCopierが管理する生成状態で、Tauriを使わないため既定値のまま保持します。廃止された `use_gh_actions_pr_tag_check` と旧runtime starter管理項目は、現行テンプレートの回答ファイルから削除されます。独自のtag検査workflowとWorker Imageの実装は削除しません。今回の更新では Repository Template Policy を有効にしました。Worker Image の公開に関する回答は変更しません。

現在の `copier.yml` には、Shell runtime、テンプレート外のCI、Shell test、ドキュメント、デプロイを個別に表す回答項目はありません。これらは存在しない回答値を追加せず、リポジトリ固有のscript、workflow、READMEとして管理します。package managerも利用していないため、Python、Rust、Node.jsのruntime supportを有効化しません。

## 共通ポリシーの強制範囲

個人所有のこのリポジトリでは、`repo-template-policy` は差分を知らせる通常の PR チェックです。検査コードはベース側を使いますが、チェック名を必須にしても、ワークフロー定義の出所は固定されません。

独立した書き込み権限のあるコード所有者と必須レビューを用意するまでは、初回導入と共通設定の変更を人が確認します。CI の結果だけで判断せず、ワークフロー、検査スクリプト、ポリシー、Copier の回答・適用コミットの差分を確認します。今回は CODEOWNERS、GitHub の管理設定、公開経路を変更しません。対応する構成は [repo-template の導入手順](https://github.com/mizucopo/repo-template/blob/main/docs/repo-template-policy-trust.md) を参照してください。

## テンプレート差分

### 解消する古い、または不要な独自差分

- `AGENTS.md`、`CONTRIBUTING.md`、PRテンプレート、`docs/agents/` は最新テンプレートを採用し、生成対象から外れた `CLAUDE.md` は削除する
- project固有の検証、release方針、設計文書への案内は、テンプレートが用意する `.codex/project.md` に記録する
- `.gitignore` は共通のAnsible runtime state除外を採用し、Docker build contextの説明は `docs/docker-build-context.md` を採用する
- `.copier-answers.yml` は現行schemaの既定値と最新 `_commit` を記録する。更新開始時とPR提出直前に `repo-template/main` を取得し、記録されたrevisionがその先端を指すことを確認する
- `.github/dependabot.yml` のDocker監視はbuild `ARG` 経由のimageを更新できないため削除し、独立したGitHub Actions監視だけをテンプレートから生成する

### `repo-template` 側へ汎用化する共通変更

Docker利用とDocker Dependabot監視を分離する共通変更は、[`repo-template` Issue #31](https://github.com/mizucopo/repo-template/issues/31) と [PR #32](https://github.com/mizucopo/repo-template/pull/32) で解消しました。このリポジトリは `use_docker: true` と `use_dependabot_docker: false` を併用し、Docker関連ファイルを維持したまま動作しない監視を生成しません。

独立したGitHub Actions監視は、[`repo-template` Issue #40](https://github.com/mizucopo/repo-template/issues/40) とPR #61で共通化されました。このリポジトリは `use_dependabot_github_actions: true` を記録し、固有release workflowを通常のrelease入力に含めずにaction pinだけを更新できます。

### このリポジトリに残す固有差分

- `version` はproject SemVerではなくUpstream Prefect Image Tagを保持する。親imageと公開tagを決める業務値であり、汎用テンプレートの `0.1.0` へ戻せない
- `revision` は同じ Upstream Prefect Image Tag を再公開する場合だけ使う Worker Image Revision。上流の authored revision でも値は保持できるが、既存の公開手順とは同等ではない。
- `.github/workflows/check-worker-image-release.yml`: `Check Worker Image Release / check` は、公開対象ファイルが変わる PR で Git tag と Docker Hub の base / process 両タグを公開前に検査する。共通 Docker Project Pipeline の PR 品質検査だけでは代替できない。
- `.github/workflows/docker-quality-checks.yml`: `Docker Quality Checks / docker-quality-checks` は `version` から Base のビルド引数を取り、Base の PostgreSQL クライアント検証から同じローカルイメージを親にした Process の build / smoke までを実施する。単一イメージの共通 Docker Quality Checks はこのビルド引数と依存順序を引き継げず、複数イメージ版への切り替えはチェック名と検査内容を変える。
- `.github/workflows/release-worker-images.yml`: 対象ファイルを変更する main push または main の手動実行に限り、Base → Process の順で既存の immutable tag を公開／復旧してから、ソースコミットを指す Git tag と GitHub Release を作る。最新タグは発行しない。上流の authored revision では main に採番コミットを追加し、イメージ公開より先にタグを確定する。公開時点と復旧の保証を変えないため、通常／復旧時の既存リリース本文の生成（#48）と既存タグの128文字境界のテスト（#49）を含めて現行経路を残す。
- 上記3本だけを `.github/repo-template-policy.json` の `local_workflows` に完全パスで記録する。共通設定キーは除外しない。
- `images/`、`scripts/`、`tests/`、`.github/scripts/`、`README.md`、`CONTEXT.md`、本書はWorker Imageの機能、用語、検証、現行仕様を管理するため、汎用テンプレートへ統合しない
