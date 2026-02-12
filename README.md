# Dante SOCKS5 Proxy Auto-Installer for Ubuntu 24.04

![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04-orange?style=flat-square&logo=ubuntu)
![Dante](https://img.shields.io/badge/Dante-1.4.x-green?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)

Однострочный скрипт для быстрой установки и настройки Dante SOCKS5 прокси-сервера на Ubuntu 24.04 с поддержкой авторизации.

## 🚀 Быстрый старт

```bash
# 1. Скачать скрипт
wget https://github.com/AlexMishiev/install-dante.git

# 2. Отредактировать переменные (пароль и сетевой интерфейс)
nano install-dante.sh

# 3. Сделать исполняемым и запустить
chmod +x install-dante.sh
sudo ./install-dante.sh
```

## ⚙️ Настройка перед установкой
Откройте скрипт и измените две переменные в начале файла:

```bash
# Обязательно укажите свой пароль!
PROXY_PASS="ВашСуперСложныйПароль123!"

# Проверьте ваш сетевой интерфейс командой: ip a
EXTERNAL_IF="ens3"  # Обычно: ens3, ens4, eth0, eno1, enp0s3
```

## 📋 Что делает скрипт
✅ Устанавливает Dante Server

✅ Создаёт пользователя proxyuser с вашим паролем

✅ Автоматически конфигурирует /etc/danted.conf

✅ Настраивает автозагрузку

✅ Открывает порт в UFW (если активен)

✅ Проверяет работоспособность

✅ Показывает данные для подключения

## 🔌 Подключение к прокси
IP сервера:  (автоопределяется)

Порт:        1080

Логин:       proxyuser

Пароль:      ваш_пароль_из_скрипта

## 🛠 Требования
1. Ubuntu 24.04 (Noble Numbat)
2. Root-доступ
3. Выход в интернет

## 📁 Структура конфигурации
/etc/danted.conf     # Основной конфиг

## 📊 Проверка статуса
```bash
# Статус сервиса
systemctl status danted

# Логи в реальном времени
journalctl -u danted -f

# Проверка конфигурации
danted -t

# Проверка порта
ss -tlnp | grep 1080
```

## 🔒 Безопасность
* Пользователь запускается без shell (/bin/false)
* Поддержка username/password авторизации
* Резервное копирование оригинального конфига

## 🐛 Возможные проблемы
* Проблема: Неверно указан сетевой интерфейс
Решение: Проверьте командой ip a и исправьте EXTERNAL_IF

* Проблема: Не запускается сервис
Решение: danted -t покажет ошибку в конфигурации

