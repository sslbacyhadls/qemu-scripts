# Скрипт для разворачивания x86_64 виртуалок из ямлика

## Пример options.yaml файла

```
vm:
   - name: void
     ram: 4086
     image: ./Images/void-live-x86_64-musl-20250202-base.iso
     disk: void

disks:
   - name: void
     format: qcow2
     size: 20G
     directory: ./disks`
```
