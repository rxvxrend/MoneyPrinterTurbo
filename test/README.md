# Каталог тестов MoneyPrinterTurbo

Этот каталог содержит unit-тесты проекта **MoneyPrinterTurbo**.

## Структура каталогов

- `services/`: тесты компонентов из каталога `app/services`
  - `test_video.py`: тесты видеосервиса
  - `test_task.py`: тесты сервиса задач
  - `test_voice.py`: тесты сервиса озвучки

## Запуск тестов

Тесты можно запускать встроенным в Python фреймворком `unittest`:

```bash
# Запустить все тесты
python -m unittest discover -s test

# Запустить конкретный файл тестов
python -m unittest test/services/test_video.py

# Запустить конкретный класс тестов
python -m unittest test.services.test_video.TestVideoService

# Запустить конкретный метод теста
python -m unittest test.services.test_video.TestVideoService.test_preprocess_video
```

## Добавление новых тестов

Чтобы добавить тесты для других компонентов, следуйте правилам:

1. Создавайте файлы тестов с префиксом `test_` в подходящем подкаталоге.
2. Используйте `unittest.TestCase` как базовый класс тестовых классов.
3. Называйте тестовые методы с префиксом `test_`.

## Ресурсы тестов

Файлы ресурсов, необходимые для тестов, помещайте в каталог `test/resources`.
