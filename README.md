# Описание приложения:

- Flask приложение, написанное на Python.

- Требования указаны в файле requirements.

- База данных PostgreSQL. Переменные для БД указываются в файле .env, образец в репозитории в файле .env.example .

- Сборка образа приложения и его развертывание через Docker.

API запросы:
- GET /ping
```bash
curl http://localhost:5000/ping
# с ожидаемым результатом {"status": "ok"}
```
- POST /submit
```bash
curl -X POST http://localhost:5000/submit -H "Content-Type: application/json" -d '{"name": "Kirill", "score": 88}'
# с ожидаемым результатом  {"id": 1, "message": "Result submitted successfully"}
```
- GET /results
```bash
curl http://localhost:5000/results
# с ожидаемым результатом     [{"id": 1, "name": "Kirill", "score": 88, "timestamp": "2025-06-07T11:44:09.729659"}]
```


# CI/CD для работы с удаленными хостами.

## Используемые инструменты:

Для автоматизации развертывания приложения на удаленных хостах используется инструмент Jenkins.

Для хранения кода и управления версиями используется GitHub.

Для хранения Docker image используется DockerHub. https://hub.docker.com/repository/docker/ymazurau/flask-api/general

Для развёртывания и управления приложениями используется Docker. 


## Pipeline

- Описание:

Копирование кода с репозитория, сборка образа и развертывание приложения на тестовом и "прод" окружениях.

- Подготовка и создание Job:

Создаются Credentials, акузанные в jenkinsfile
```
// Jenkins credentials
DOCKER_CREDENTIALS_ID = 'docker-credentials-id'
SSH_CREDENTIALS_ID = 'ssh-remote-server'
SECRETS_FILE_ID = 'flask-secrets-file'
```
 Устанавливаются плагины: 
 Docker Pipeline, SSH Agent Plugin.
 
Создается Item Pipeline c параметрами:

  Pipeline script from SCM с параметром CMS=> Git, URL репозитория, ветки и автоматическим просматриванием репозитория.

  Script Path => Jenkinsfile
Указав эти параметры Jenkins автоматически находит в репозитории нужные файлы, указанные в jenkinsfile и выполняется все шаги сборки и развертывания приложения.

- Запуск Pipeline:

Запуск осуществляется с указанием параметров ( "Собрать с параметрами"), где задается REMOTE_HOST_IP и REMOTE_USER. Если переменные не меняются, можно указать в jenkinsfile значения по умолчанию.


- Этапы Pipeline:
1. Клонирование репозитория.
2. Проверка кода и запись лога.
3. ОБРАТИТЬ ВНИМАНИЕ! Продолжение выполнения pipeline только после подтверждения вручную
```
Проверьте flake8.log. Продолжить деплой?
Proceed or Abort
```
4. Установка Docker на удаленном тестовом хосте.
5. Build/Push Docker image.
6. Развертывание приложения на удаленном тестовом хосте.
Результат успешного выполнения на удаленной машине:
```
ubuntu@compute-vm-2-4-20-ssd-1749406637123:~$ sudo docker ps
CONTAINER ID   IMAGE                       COMMAND                  CREATED             STATUS                         PORTS                                         NAMES
35b8d0619386   ymazurau/flask-api:latest   "/entrypoint.sh"         About an hour ago   Up About an hour (unhealthy)   0.0.0.0:5000->5000/tcp, [::]:5000->5000/tcp   flask-api_web_1
c973b39f4240   postgres:15                 "docker-entrypoint.s…"   About an hour ago   Up About an hour               0.0.0.0:5432->5432/tcp, [::]:5432->5432/tcp   postgres_db
ubuntu@compute-vm-2-4-20-ssd-1749406637123:~$ curl http://localhost:5000/ping
{"status":"ok"}
ubuntu@compute-vm-2-4-20-ssd-1749406637123:~$ curl -X POST http://localhost:5000/submit -H "Content-Type: application/json" -d '{"name": "Kirill", "score": 88}'
{"id":2,"message":"Result submitted successfully"}
ubuntu@compute-vm-2-4-20-ssd-1749406637123:~$ curl http://localhost:5000/results
[{"id":2,"name":"Kirill","score":88,"timestamp":"2025-06-08T19:32:41.999500"},{"id":1,"name":"Kirill","score":88,"timestamp":"2025-06-08T18:27:21.240335"}]
ubuntu@compute-vm-2-4-20-ssd-1749406637123:~$ 
```
7. После успешного завершения развертывания в тестовом окружении, получаем лог-файл и проверяем непосредственно на хосте ( эмитируется работа QA специалистов на тестовом хосте) - подтверждаем "деплой" в "прод" вручную
```
Проверьте result.txt. Продолжить деплой?
Proceed or Abort
```
8. Проверяем работу приложения на "прод" хосте.

## Время выполнения:

Среднее время выполнения pipeline составляет 6 мин ( в pipeline два тех. таймаута по 15 сек.). Две "дефолтные" ( Ubuntu 24.04) VM поднимаются в облаке (yandex cloud) с конфигурацией: платформа Intel Ice Lake, гарантированная доля vCPU 100%, 2 CPU/4Gb RAM, SSD. 

Среднее время повторного выполнения на уже подготовленных машинах составляет 3 мин.

## Для проверки результата работы

http://37.9.53.70:5000/results