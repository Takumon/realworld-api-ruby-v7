# README

## 概要

[Realworld](https://realworld-docs.netlify.app)の[バックエンド](https://realworld-docs.netlify.app/specifications/backend/introduction/)の実装

## メタ情報

- 本アプリの生成コマンド
  ```bash
  rails new realworld-api-ruby-v7 --api --skip-action-mailer --skip-action-mailbox
  ```
- Rubyのバージョン
  - 3.3.5
- Ruby on Railsのバージョン
  - 7.2.2

## ローカルでのテスト

Postmanを使います。以下を実行します。

```bash
APIURL=http://localhost:3000/api ./run-api-tests.sh
```

For more details, see [`run-api-tests.sh`](run-api-tests.sh).

## コマンド

- ローカルサーバーの起動
  ```bash
  bundle exec rails s
  ```
