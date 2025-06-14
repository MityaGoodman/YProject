# YProject

## Описание проекта

В рамках домашнего задания реализовал следующее:

### 1. Доменные модели

* **Category**

  * Поля соответствуют JSON-объекту из ответа бэкенда для списка категорий.
  * Направление операции определяется через `enum Direction { income, outcome }`.
  * Иконка хранится в поле `emoji` типа `Character` (эмоджи).

* **BankAccount**

  * Поля соответствуют JSON-объекту из ответа бэкенда для списка банковских счетов.
  * Поле `balance` имеет тип `Decimal`.

* **Transaction**

  * Поля соответствуют JSON-объекту из ответа бэкенда для списка операций.
  * Поле `amount` имеет тип `Decimal`.
  * Поле `transactionDate` представлено типом `Date`.

### 2. Сериализация и десериализация

Для `Transaction` реализовано расширение:

* `static func parse(jsonObject: Any) -> Transaction?` — парсит Foundation-объект (`[String:Any]`, `String`, `NSNumber` и т.д.) в модель `Transaction`.
* `var jsonObject: Any` — возвращает словарь `[String:Any]`, готовый для `JSONSerialization`, для обратного преобразования в JSON.

### 3. TransactionsFileCache

Класс `TransactionsFileCache` обеспечивает хранение операций в локальном JSON-файле:

* Приватный `Set<Transaction>` для хранения, гарантирующий уникальность по `id`.
* `init(fileURL: URL)` — инициализация с указанием файла, загрузка существующих данных.
* `loadFromFile()` — чтение и парсинг массива операций из JSON-файла.
* `saveToFile()` — сохранение текущего списка операций в JSON-файл.
* `add(_:)` — добавление новой операции и автоматическое сохранение.
* `remove(id:)` — удаление операции по `id` и автоматическое сохранение.
* Поддержка нескольких файлов через разные экземпляры с разными `fileURL`.

### 4. Моки сервисов

Интерфейсы (протоколы) и их mock-реализации для быстрого тестирования и UI-прототипирования:

* **CategoriesService**

  * `func fetchAll() async -> [Category]`
  * `func fetch(by isIncome: Direction) async -> [Category]`

* **BankAccountsService**

  * `func fetchPrimaryAccount() async -> BankAccount?`
  * `func updateBalance(_ account: BankAccount, to newBalance: Decimal) async`

* **TransactionsService**

  * `func fetch(from: Date, to: Date) async -> [Transaction]`
  * `func create(_ transaction: Transaction) async`
  * `func update(_ transaction: Transaction) async`
  * `func delete(id: Int) async`

Mock-реализации (`MockCategoriesService`, `MockBankAccountService`, `MockTransactionsService`) используют в качестве источника данных локальные модели и `TransactionsFileCache`.

### 5. CSV-парсер

* Реализовано расширение `Transaction`:

  * `init?(csvFields: [String], dateFormatter: ISO8601DateFormatter)` — инициализатор из массива полей CSV.
  * `static func parseCSV(_ csv: String) -> [Transaction]` — парсинг CSV-текста в массив моделей.

---
