@echo off

REM Получаем текущий путь
set "currentPath=%~dp0"
set "pathLuaJIT=%currentPath%.squish"

REM Заключаем пути в кавычки
set "pathLuaJITWithQuotes="%pathLuaJIT%""

REM Проверка наличия luajit.exe
if not exist "%pathLuaJIT%\luajit.exe" (
    echo Ошибка: файл luajit.exe не найден в "%pathLuaJIT%"
    pause
    exit /b 1
)

REM Собирает все файлы и создает squishy
"%pathLuaJIT%\luajit.exe" "%pathLuaJIT%\script_squish.lua"

REM Запуск сборщика, билд в build
"%pathLuaJIT%\luajit.exe" "%pathLuaJIT%\lua\squish.lua" src

REM Удаление squishy после сборщика
cd src
if exist "squishy" (
    del "squishy"
) else (
    echo Внимание: файл squishy не найден для удаления
)
cd "%currentPath%"
