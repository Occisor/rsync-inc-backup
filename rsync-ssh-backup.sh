#!/bin/sh

# Инкрементное резервное копирование.

# Опции запуска rsync
# -a    режим архива замена ключей -rlptgoD
# -H    копировать жесткие ссылки как жесткие ссылки (только в рамках одного раздела)
# -A    копировать атрибуты Posix ACL
# -X    копировать контекст SELinux
# -v    список файлов и короткий итог

# Настраиваемые параметры.
# Параметры SSH. Для автоматизации требуется настроить подключение по ключу.
# Example: "ssh -p 22 -i ~/.ssh/id_ed25519"
ssh_connection=""
# Исходная папка.
# Example: "name@192.168.1.1:/home/name/dir"
source_dir=""
# Путь для сохранения бэкапов.
# Example: "/home/name2/rsync-backup/dir"
backup_base_dir=""
# Количество архивов хранения бэкапов.
keep_arhives=8

# Получаем текущую дату в формате YYYY-MM-DD
backup_date=$(date +%Y-%m-%d)
backup_dir="$backup_base_dir/$backup_date"

# Проверка на наличие предыдущего бэкапа.
latest_backup=$(find "$backup_base_dir" -maxdepth 1 -type d -name '????-??-??' | sort | tail -n 1)

# Создаем директорию для бэкапов, если ее нет.
mkdir -p "$backup_dir"

# Проверка успешности создания директории.
if [ $? -ne 0 ]; then
    echo "Error: Failed to create directory for backups."
    exit 1
fi

# Выполняем бэкап с помощью rsync с использованием предыдущего бэкапа, если он есть.
if [ -n "$latest_backup" ]; then
    rsync -cahvPAX -e "$ssh_connection" --delete --link-dest="$latest_backup" "$source_dir/" "$backup_dir/" --log-file="$backup_base_dir/$backup_date.log" 2>> "$backup_base_dir/${backup_date}_er.log"
    # Принудительное изменение времени модификации, т.к. иначе оно не соответствует действительности.
    touch "$backup_dir"
# Иначе создаем новый.
else
    rsync -chavPAX -e "$ssh_connection" --delete "$source_dir/" "$backup_dir/" --log-file="$backup_base_dir/$backup_date.log" 2>> "$backup_base_dir/${backup_date}_er.log"
    # Принудительное изменение времени модификации, т.к. иначе оно не соответствует действительности.
    touch "$backup_dir"
fi

# Проверяем успешность выполнения rsync.
if [ $? -ne 0 ]; then
    echo "Error: rsync failed. Read logs in file: $backup_base_dir/$backup_date.log"
    # exit 1
fi

# Удаляем старые бэкапы.
find "$backup_base_dir" -maxdepth 1 -type d -name '????-??-??' | sort | head -n -$keep_arhives | while read -r old_backup; do
    if [ "$old_backup" != "$backup_dir" ]; then  # Не удаляем текущий бэкап.
        echo "Deleting the old backup: $old_backup"
        [ -d "$old_backup" ] && rm -rf "$old_backup"
        [ -f "${old_backup}_er.log" ] && rm -f "${old_backup}_er.log"
        [ -f "${old_backup}.log" ] && rm -f "${old_backup}.log"
    fi
done

echo "Backup complete!"
