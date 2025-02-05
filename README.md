# Развертывание web-приложения в YC с помощью terraform

## Описание проекта
Данный проект terraform развертывает web-приложение в Yandex Cloud с использованием Managed Service for Kubernetes, Application Load Balancer, Managed Service for MySQL и Container Registry. Приложение представляет собой Flask-сервис, который обрабатывает HTTP-запросы и отдаёт статические страницы с демо-контентом. Также реализовано логирование в управляемую базу данных MySQL.

## Архитектура

- *Managed Service for Kubernetes* — управляемый кластер k8s (региональный), в котором развернуты поды с веб-приложением. Worker-ноды кластера располагаются в разных зонах доступности.

- *Application Load Balancer* — маршрутизирует трафик между различными сервисами k8s.

- *Container Registry* — используется для хранения Docker-образа приложения.

- *Managed Service for MySQL* — база данных для хранения логов запросов к web-приложению через балансировщик, а так же сообщений, записанных с помощью web-приложения.

- *Cloud DNS* — привязка публичного доменного имени к сервису.
![Image](https://github.com/user-attachments/assets/8390ed79-3b08-4585-8026-eff160aaf7ca)

## Функционал

- Развёртывание Flask-приложения в Kubernetes.
- Маршрутизация через ALB:
  - `/page1.html` отправляется в целевую группу 1.
  - `/page2.html` отправляется в целевую группу 2.
  - `/logs` отображает логи из базы данных.
  - `/write/{string}` - записывает `{string}` в БД.
- Использование Container Registry для хранения Docker-образов.
- Подключение к управляемой базе MySQL через TLS.
- Доступ к сервису по публичному доменному имени через Cloud DNS.
- Логирование запросов ALB в базу данных с помощью Cloud Functions.
- Логирование сообщений в базу данных через само приложение.

## Установка и развёртывание

### 1. Подготовка окружения

Устанавливаем необходимые утилиты:
- `yc`
- `docker`
- `terraform`
- `jq`
- `mysql`

[Аутентифицируемся](https://yandex.cloud/ru/docs/cli/operations/profile/profile-create#interactive-create) в Yandex Cloud:

```bash
yc init
```

### 2. Развёртывание инфраструктуры

1. Клонируем репозиторий:

```bash
git clone <репозиторий>
cd <репозиторий>
```
3. Создаем файл terraform.tfvars в корне каталога, с содержимым:
```hcl
cloud_id  = "<your_cloud_id>"
folder_id = "<your_folder_id>"
dns       = "<your_domain_name>"
```
4. Инициализируем Terraform, предварительно [настроив](https://yandex.cloud/ru/docs/tutorials/infrastructure-management/terraform-quickstart#configure-provider) провайдер:
```
terraform init
```
State будет хранится в локальном backend в папке `/state`.

5. Проверяем, какие ресурсы будут созданы:
```
terraform plan
```
6. Развёртываем инфраструктуру:
```
terraform apply -auto-approve
```
После выполнения команды Terraform создаст все необходимые ресурсы в облаке.
Время развертывания всей инфраструктуры, в том числе балансировщика *~25 мин*.

## Проверка работоспособности

После того как terraform завершит работу проверяем работоспособность нашего приложения:
1. Ожидаем когда балансировщик ALB полностью развернется, т.к. его создание не контролируется terraform'ом, а зависит от ingress-контроллера в кластере k8s.
2. Если домен не делигирован серверам DNS Yandex, то можем добавить соответствующую запись `<ip> <dns_name>` в файд *hosts* (данная запись выводится *output*'ом после завершения работы *terraform*).
3. Через броузер, либо через *curl* делаем обращение к нашему web-приложению:
```bash
http://<dns_name>/page1.html
http://<dns_name>/page2.html
http://<dns_name>/write/<message>
```
4. Подключаемся к базе данных MySQL, предвариетльно установив сертификат:
```bash
mkdir -p ~/.mysql && \
wget "https://storage.yandexcloud.net/cloud-certs/CA.pem" \
   --output-document ~/.mysql/root.crt && \
chmod 0600 ~/.mysql/root.crt
```
```
mysql --host=<hostname> --port=3306 --ssl-ca=~/.mysql/root.crt --ssl-mode=VERIFY_IDENTITY --user=john --password=password test-db
```
где `hostname` - *FQDN* нашей БД (выводится *output*'ом после завершения работы *terraform*).
5. Проверяем таблицы БД:
```sql
USE test-db;
SELECT * FROM load_balancer_requests;
SELECT * FROM my_app_logs;
```
где `load_balancer_requests` - таблица, куда пишутся логи с балансировщика, `my_app_logs` - таблица, куда пишутся сообщения отправленные через наше web-приложение.