### **Скрипт для инкрементного бэкапа, с использованием rsync по ssh.**

При первом запуске создается полный бэкап, при последующих вносятся только изменения.

Для первичной настройки, скачайте и откройте файл скрипта `rsync-ssh-backup.sh`, заполните переменные в оостветствии с вашей ситуацией:

```
# Параметры SSH. Для автоматизации требуется предварительно настроить подключение по ключу.
# Указывается порт и путь к ключу.
# Example: "ssh -p 22 -i ~/.ssh/id_ed25519"
ssh_connection="ssh -p 22 -i ~/.ssh/id_ed25519"

# Исходная папка. Которую требуется поместить в бэкап.
# Заполняется: имя, ip-адрес и путь
# Example: "name@192.168.1.1:/home/name/dir"
source_dir="name@192.168.1.1:/home/name/dir"

# Путь для сохранения бэкапов.
# Example: "/home/name2/rsync-backup/dir"
backup_base_dir="/home/name2/rsync-backup/dir"

# Количество архивов хранения бэкапов.
# Если запускать бэкап раз в сутки, колчиество будет соответстовать каждому дню.
keep_arhives=8
```

Далее запускаете вручную или добавляете в crontab.
