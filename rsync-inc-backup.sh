#!/bin/sh

# Инкрементное резервное копирование.

# Опции запуска rsync
# -a    режим архива замена ключей -rlptgoD
# -H    копировать жесткие ссылки как жесткие ссылки (только в рамках одного раздела)
# -A    копировать атрибуты Posix ACL
# -X    копировать контекст SELinux
# -v    список файлов и короткий итог

# Настраиваемые параметры.
# Параметры rsync
# Example: "-cahvPAX"
rsync_settings="-cahvPAX"
# Параметры SSH.
# Если параметр пустой, то ssh не будет использоваться.
# Для автоматизации требуется настроить подключение по ключу.
# Example: "ssh -p 22 -i ~/.ssh/id_ed25519"
ssh_connection=""
# Исходная папка.
# Example for ssh: "name@192.168.1.1:/home/name/dir"
# Example for local path: "/home/name/dir"
source_dir=""
# Путь для локального сохранения бэкапов.
# Example: "/home/name2/rsync-backup/dir"
backup_base_dir=""
# Количество архивов хранения бэкапов.
keep_arhives=8

# Проверяем наличие параметров.
if [ -z "$source_dir" ]; then
    echo "Error: Source directory is not specified."
    exit 1
fi
if [ -z "$backup_base_dir" ]; then
    echo "Error: Backup base directory is not specified."
    exit 1
fi

# Создаем директорию для бэкапов, если ее нет.
mkdir -p "$backup_base_dir"
# Проверка успешности создания директории.
if [ $? -ne 0 ]; then
    echo "Error: Failed to create directory for backups."
    exit 1
fi

# Проверка на наличие предыдущего бэкапа.
latest_backup=$(find "$backup_base_dir" -maxdepth 1 -type d -name '????-??-??_??-??-??' | sort | tail -n 1)

# Получаем текущую дату в формате YYYY-MM-DD
backup_date=$(date +%Y-%m-%d_%H-%M-%S)
backup_dir="$backup_base_dir/$backup_date"

# Выполняем бэкап с помощью rsync с использованием предыдущего бэкапа, если он есть.
if [ -n "$latest_backup" ]; then
    if [ -z "$ssh_connection" ]; then
        rsync "$rsync_settings" --delete --link-dest="$latest_backup" "$source_dir/" "$backup_dir/" --log-file="$backup_base_dir/$backup_date.log" 2>> "$backup_base_dir/${backup_date}_er.log"
        # Принудительное изменение времени модификации, т.к. иначе оно не соответствует действительности.
        touch "$backup_dir"
    else
        rsync "$rsync_settings" -e "$ssh_connection" --delete --link-dest="$latest_backup" "$source_dir/" "$backup_dir/" --log-file="$backup_base_dir/$backup_date.log" 2>> "$backup_base_dir/${backup_date}_er.log"
        touch "$backup_dir"
    fi
# Иначе создаем новый.
else
    if [ -z "$ssh_connection" ]; then
        rsync "$rsync_settings" --delete "$source_dir/" "$backup_dir/" --log-file="$backup_base_dir/$backup_date.log" 2>> "$backup_base_dir/${backup_date}_er.log"
        touch "$backup_dir"
    else
        rsync "$rsync_settings" -e "$ssh_connection" --delete "$source_dir/" "$backup_dir/" --log-file="$backup_base_dir/$backup_date.log" 2>> "$backup_base_dir/${backup_date}_er.log"
        touch "$backup_dir"
    fi
fi

# Проверяем успешность выполнения rsync.
if [ $? -ne 0 ]; then
    echo "Error: rsync failed. Read logs in file: $backup_base_dir/$backup_date.log"
    # exit 1
fi

# Удаляем старые бэкапы.
find "$backup_base_dir" -maxdepth 1 -type d -name '????-??-??_??-??-??' | sort | head -n -$keep_arhives | while read -r old_backup; do
    if [ "$old_backup" != "$backup_dir" ]; then  # Не удаляем текущий бэкап.
        echo "Deleting the old backup: $old_backup"
        [ -d "$old_backup" ] && rm -rf "$old_backup"
        [ -f "${old_backup}_er.log" ] && rm -f "${old_backup}_er.log"
        [ -f "${old_backup}.log" ] && rm -f "${old_backup}.log"
    fi
done

echo "Backup complete!"
