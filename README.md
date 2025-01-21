### OTUS High Load Lesson #14 | Subject: Настройка централизованного сбора логов в кластер Elasticsearch
-----------------
### ЦЕЛЬ: Настроить централизованный сбор логов с различных серверов проекта и их хранение в кластер Elasticsearch для удобного поиска и анализа
-----------------
### ТРЕБОВАНИЯ: 
#### 1. Развертывание кластера Elasticsearch
- Создать и настроить кластер Elasticsearch. Развернуть кластер Elasticsearch, состоящий из как минимум трех виртуальных машин (ВМ), которые будут выполнять функции узлов кластера.
- Настроить узлы кластера. Обеспечить правильную конфигурацию узлов для работы в кластере, включая настройку сетевого взаимодействия и параметров кластера (например, discovery.seed_hosts, cluster.initial_master_nodes).
#### 2.  Настройка сбора логов
- Выбрать инструмент для сбора логов. Решить какой инструмент будет использоваться для сбора логов с серверов. Возможные варианты включают Filebeat, Logstash или другие подходящие агрегаторы логов.
- Установить и настроить инструмент для сбора логов. Установить выбранный инструмент на все серверы проекта, включая веб-серверы, балансеры и базы данных. Настроить его для отправки логов в кластер Elasticsearch.
- Конфигурировать шаблоны и индексы. Создать и настроить шаблоны индексов и правила для обработки логов в Elasticsearch, чтобы обеспечить правильное хранение и структурирование данных.
#### 3. Проверка и тестирование
- Проверить сбор логов. Убедиться, что логи корректно собираются и отправляются в Elasticsearch. Проверить, что данные появляются в Elasticsearch и могут быть проанализированы.
- Настроить визуализацию. Опционально, для удобства анализа, настроить инструменты визуализации, такие как Kibana, для просмотра и анализа собранных логов.
----------------
### ОЖИДАЕМЫЕ РЕЗУЛЬТАТЫ:
- Работает кластер Elasticsearch из минимум трех узлов.
- Логи со всех указанных серверов (веб-серверы, балансеры, базы данных) успешно собираются и хранятся в Elasticsearch.
- Настроена возможность просмотра и анализа логов в Elasticsearch.

### ВЫПОЛНЕНИЕ
>[!NOTE]
>Я выполнил ДЗ в двух вариантах:
>1. Руками поднял elasticsearch-кластер из трёх нод для ознакомления с кластеризацией elasticsearch. Описание и скриншоты ниже.
>2. С помощью terraform и ansible настроил автоматическое развёртывание elasticsearch+logstash+kibana на одной ноде, настроил перенаправление логов с виртуальных машин проекта на эту ноду.
>
>
>   Автоматическое развёртывание только одной ноды, а не трёх, делал с целью экономии ресурсов в яндекс облаке и экономии времени на написание плейбуков. Такой же совет дал и преподаватель.

#### Установка и настройка Elasticsearch-кластера из трёх нод

Поднимаем три виртуальных машины, которые будут использоваться в качестве нод elasticsearch: 
![image](https://github.com/user-attachments/assets/3559df7d-e8d2-4dd8-a8a1-a80a4b81bdfb)

__На каждой ноде__:
```bash
/etc/hosts
10.16.0.19 elasticsearch1
10.16.0.30 elasticsearch2
10.16.0.34 elasticsearch3
```
```bash
echo "deb [trusted=yes] https://mirror.yandex.ru/mirrors/elastic/8/ stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
apt-get update && apt-get install elasticsearch
systemctl enable elasticsearch.service
```
__На ноде elasticsearch1__:
```
/etc/elasticsearch/elasticsearch.yml
...
cluster.name: es-cluster
network.host: 0.0.0.0
transport.host: 0.0.0.0
cluster.initial_master_nodes: ["elasticsearch1"]
...
```
```bash
systemctl start elasticsearch.service
```
меняем пароль для пользователя elastic:
```bash
/usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic -i
```
генерируем токен для добавления нод:
```bash
/usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s node
```
__На нодах elasticsearch2 и elasticsearch3__:
```
/etc/elasticsearch/elasticsearch.yml
...
cluster.name: es-cluster
network.host: 0.0.0.0
transport.host: 0.0.0.0
...
```
добавляем ноду в кластер (токен ранее создавали на первой ноде):
```bash
/usr/share/elasticsearch/bin/elasticsearch-reconfigure-node --enrollment-token <token>
```
```bash
systemctl start elasticsearch.service
```
__На каждой ноде__:
```
/etc/elasticsearch/elasticsearch.yml
...
discovery.seed_hosts: ["elasticsearch1", "elasticsearch2", "elasticsearch3"]
cluster.initial_master_nodes: ["elasticsearch1", "elasticsearch2", "elasticsearch3"]
# cluster.initial_master_nodes: ["elasticsearch1"]
...
```
```bash
systemctl restart elasticsearch.service
```
__Проверяем статус кластера:__
```bash
curl -k -u elastic:<pass> -X GET https://localhost:9200/_cat/nodes?v
```
![image](https://github.com/user-attachments/assets/fb44643a-1a59-4bb8-ad2b-18e06ce95636)

```bash
curl -k -u elastic:<pass> -X GET https://localhost:9200/_cat/health
```
![image](https://github.com/user-attachments/assets/9b7954a8-ed60-4dbf-962a-1500fa4d8c29)

Как видим, три ноды доступны в кластере. Состояние кластера _green_. Далее можно создавать индексы, указывая количество шардов и реплик (в нашем случае оптимальным вариантом будет 3 шарда и 2 реплики).
 


