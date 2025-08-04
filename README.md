# Admin Scripts

A collection of my personal administrative scripts.

I keep them here on GitHub so I can quickly pull them onto a new system when needed.

You are welcome to use these scripts for any purpose under the terms of the MIT License.  
**Use at your own risk.**  
No warranties of any kind are provided.

These scripts were not designed for public use or distribution. I originally wrote them for myself only.

---
## `scripts/neovim-install.sh`

Этот скрипт устанавливает и настраивает Neovim как легковесный, но мощный консольный редактор, стилизованный под VSCode. Он предназначен для быстрой замены стандартных `nano` или `mcedit` на серверах.

![Neovim in action](screenshots/neovim-install.png)

### Что он делает?

1.  **Проверяет и устанавливает зависимости:** `neovim`, `git`, `curl`, `build-essential`, `xclip`, `ripgrep`.
2.  **Полностью очищает старые конфигурации** Neovim для чистой установки.
3.  **Устанавливает менеджер плагинов** `lazy.nvim`.
4.  **Создает конфигурационный файл** `init.lua` с плагинами и настройками для VSCode-подобного опыта.
5.  **Автоматически устанавливает все плагины** при первом запуске.

### Особенности

-   **VSCode-подобный интерфейс:** Тема по умолчанию `vscode`, привычные горячие клавиши.
-   **Подсветка синтаксиса:** Для множества языков с помощью `nvim-treesitter`.
-   **Нечеткий поиск:** `Telescope` для быстрого поиска файлов (`Ctrl+P`), текста в проекте (`Ctrl+G`) и открытых буферов (`Ctrl+B`).
-   **Удобное комментирование:** (`Ctrl`+`Shift`+`/`).
-   **Интерактивный выбор темы:** Команда `:Themes` для смены цветовой схемы.
-   **Работа с системным буфером обмена.**

### Основные горячие клавиши

| Клавиша(и) | Действие |
| --- | --- |
| `Ctrl+S` / `F2` | Сохранить файл |
| `Esc` `Esc` / `F10` | Выйти из редактора (с подтверждением сохранения) |
| `Ctrl+C` (в режиме выделения) | Копировать в системный буфер обмена |
| `Ctrl+Y` | Удалить текущую строку |
| `Ctrl+Z` | Отменить последнее действие |
| `F7` | Начать поиск по файлу |
| `F8` / `Shift+F8` | Следующий/предыдущий результат поиска |
| `Ctrl+P` | Поиск файлов в проекте (Fuzzy Find) |
| `Ctrl+G` | Поиск текста во всех файлах проекта (Live Grep) |
| `Ctrl+B` | Поиск по открытым буферам |
| `Ctrl`+`Shift`+`/` | Закомментировать/раскомментировать строку/блок |
