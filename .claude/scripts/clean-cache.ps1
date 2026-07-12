# Очистка кэша контекста: удаляет файлы старше 2 дней из .context-cache/
# Запускается автоматически хуком SessionStart (см. .claude/settings.json)
$cacheDir = Join-Path $PSScriptRoot "..\..\.context-cache"
if (Test-Path $cacheDir) {
    Get-ChildItem -Path $cacheDir -File -Recurse |
        Where-Object { $_.Name -ne "README.md" -and $_.LastWriteTime -lt (Get-Date).AddDays(-2) } |
        Remove-Item -Force -Confirm:$false
}
