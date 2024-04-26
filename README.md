# docker-exec-for-bastion-rockylinux
[ECS](https://docs.aws.amazon.com/ja_jp/AmazonECS/latest/developerguide/Welcome.html)で[RockyLinux](https://rockylinux.org/ja/)の踏み台を実行する。

<br>

# Requirement
以下の環境で動作確認済み<br>
- [Fargate](https://docs.aws.amazon.com/ja_jp/AmazonECS/latest/userguide/what-is-fargate.html)1.4.0

<br>

# Installation
git cloneコマンドで本Repositoryを任意のディレクトリ配下にcloneする。

<br>

# Settings
[.env](./.env)を設定することで、任意の設定でContainerを実行する事が可能である。

## BaseImageTagの設定
[.env](./.env)内の`BASE_IMAGE_TAG`に[RockyLinux](https://hub.docker.com/_/rockylinux/tags)の任意のImageTagを設定する。

```
BASE_IMAGE_TAG = ${ImageTag}
```

## 実行ユーザー名の設定
[.env](./.env)内の`USER_NAME`にコンテナ起動後の実行ユーザーを設定する。

```
USER_NAME = ${実行ユーザー名}
```

<br>

# Usage

## コンテナ実行
本Repository直下[docker_image_register.sh](./docker_image_register.sh)が存在するディレクトリで以下のコマンドを実行する。

```bash
./docker_image_register.sh
```

> [!NOTE]
> [cloudformation-ecs-bastion](https://github.com/NaoyaOgura0828/cloudformation-templates/tree/main/cloudformation-ecs-bastion)を利用した環境構築を前提としている。<br>
> [cloudformation-ecs-bastion](https://github.com/NaoyaOgura0828/cloudformation-templates/tree/main/cloudformation-ecs-bastion)を利用しない場合は、`bastion`という名称でECRにRepositoryを構築すること。

<br>
