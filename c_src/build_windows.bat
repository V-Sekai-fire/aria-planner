@echo off
REM SPDX-License-Identifier: MIT
REM Copyright (c) 2025-present K. S. Ernest (iFire) Lee
REM
REM Windows native build script for Chuffed solver NIF
REM This uses Windows native compiler (MSVC or MinGW)

setlocal

REM Get Erlang paths
for /f "tokens=*" %%i in ('erl -eval "io:format(\"~s\", [code:root_dir()])" -noshell -s init stop') do set ERLANG_ROOT=%%i
for /f "tokens=*" %%i in ('erl -eval "io:format(\"~s\", [erlang:system_info(version)])" -noshell -s init stop') do set ERLANG_VERSION=%%i

set ERLANG_ERTS_DIR=%ERLANG_ROOT%\erts-%ERLANG_VERSION%
set ERLANG_INCLUDE_DIR=%ERLANG_ERTS_DIR%\include

REM Create priv directory if it doesn't exist
if not exist priv mkdir priv

REM Try MSVC first
where cl.exe >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo Using MSVC compiler...
    cl.exe /std:c++17 /O2 /W3 /D_WIN32 /EHsc /LD /I"%ERLANG_INCLUDE_DIR%" chuffed_solver.cpp /Fe:priv\chuffed_solver_nif.dll
    if %ERRORLEVEL% == 0 (
        echo Built: priv\chuffed_solver_nif.dll
        goto :end
    )
)

REM Try MinGW g++
where g++.exe >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo Using MinGW g++ compiler...
    g++.exe -std=c++17 -fPIC -O2 -Wall -Wextra -D_WIN32 -I"%ERLANG_INCLUDE_DIR%" -shared -o priv\chuffed_solver_nif.dll chuffed_solver.cpp
    if %ERRORLEVEL% == 0 (
        echo Built: priv\chuffed_solver_nif.dll
        goto :end
    )
)

echo Error: No suitable C++ compiler found.
echo Please install either:
echo   - Microsoft Visual C++ (cl.exe)
echo   - MinGW-w64 (g++.exe)
exit /b 1

:end
endlocal


