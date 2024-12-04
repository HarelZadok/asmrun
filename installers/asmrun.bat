@echo off
setlocal enabledelayedexpansion

REM Check for help or format info request
if /i "%~1"=="/new" if /i "%~2"=="/f?" goto :new_format_help
if "%~1"=="" goto :usage
if /i "%~1"=="/h" goto :usage
if /i "%~1"=="/?" goto :usage
if /i "%~1"=="/f?" goto :format_help
if /i "%~1"=="/new" goto :new_project

set "file=%~f1"
set "name=%~n1"
set "pause=0"
set "obj=0"
set "exe=0"
set "build=0"
set "format=win32"
set "showtime=0"
set "INSTALL_DIR=%LOCALAPPDATA%\Microsoft\WindowsApps"

:parse_args
if "%~2"=="" goto :check_args

if /i "%~2"=="/h" goto :usage
if /i "%~2"=="/?" goto :usage
if /i "%~2"=="/f?" goto :format_help
if /i "%~2"=="/time" (
    set "showtime=1"
    shift
    goto :parse_args
)
if /i "%~2"=="/p" (
    set "pause=1"
    shift
    goto :parse_args
)
if /i "%~2"=="/obj" (
    set "obj=1"
    shift
    goto :parse_args
)
if /i "%~2"=="/exe" (
    set "exe=1"
    shift
    goto :parse_args
)
if /i "%~2"=="/b" (
    set "build=1"
    shift
    goto :parse_args
)
if /i "%~2"=="/f" (
    if "%~3"=="" (
        powershell write-host "Error: Missing format after /f" -f Red
        echo Use /f? to see available formats
        exit /b 1
    )
    set "format=%~3"
    shift
    shift
    goto :parse_args
)
shift
goto :parse_args

:usage
powershell write-host "Usage:" -f Yellow
<nul set /p ="    asmrun filename.asm [options]"
echo.
echo.
powershell write-host "Options:" -f Yellow
<nul set /p ="    /p         Pause after execution"
echo.
<nul set /p ="    /obj       Keep object file in current directory"
echo.
<nul set /p ="    /exe       Keep executable in current directory"
echo.
<nul set /p ="    /b         Build only, do not run (requires /obj or /exe)"
echo.
<nul set /p ="    /f format  Select output format (default: win32, use /f? for list)"
echo.
<nul set /p ="    /h, /?     Show this help message"
echo.
<nul set /p ="    /f?        Show available output formats"
echo.
<nul set /p ="    /time      Show compilation time"
echo.
<nul set /p ="    /new       Create a new assembly project"
echo.
echo.
powershell write-host "Example:" -f Yellow
<nul set /p ="    asmrun HelloWorld.asm /p /exe              (32-bit Windows)"
echo.
<nul set /p ="    asmrun HelloWorld.asm /exe /f win64        (64-bit Windows)"
echo.
<nul set /p ="    asmrun HelloWorld.asm /exe /f elf64        (64-bit Linux)"
echo.
<nul set /p ="    asmrun /new MyProject /f win32             (Create a new project)"
echo.
exit /b 1

:format_help
powershell write-host "Available Output Formats:" -f Yellow
echo.
powershell write-host "Windows Formats:" -f Cyan
<nul set /p ="    win32    Windows 32-bit (default)"
echo.
<nul set /p ="    win64    Windows 64-bit"
echo.
<nul set /p ="    obj      MS-DOS/OS2/Win16 OMF"
echo.
echo.
powershell write-host "Unix/Linux Formats:" -f Cyan
<nul set /p ="    elf32    Linux/Unix 32-bit ELF"
echo.
<nul set /p ="    elf64    Linux/Unix 64-bit ELF"
echo.
<nul set /p ="    elfx32   Linux x32 ABI"
echo.
<nul set /p ="    aout     Linux a.out"
echo.
<nul set /p ="    aoutb    BSD a.out"
echo.
<nul set /p ="    coff     Generic COFF"
echo.
echo.
powershell write-host "macOS Formats:" -f Cyan
<nul set /p ="    macho32  macOS 32-bit"
echo.
<nul set /p ="    macho64  macOS 64-bit"
echo.
echo.
powershell write-host "Raw Binary Formats:" -f Cyan
<nul set /p ="    bin      Flat binary"
echo.
<nul set /p ="    ith      Intel HEX"
echo.
<nul set /p ="    srec     Motorola S-records"
echo.
echo.
powershell write-host "Other Formats:" -f Cyan
<nul set /p ="    mips     MIPS R3000 assembly"
echo.
<nul set /p ="    as86     as86 (bin86 toolchain)"
echo.
<nul set /p ="    ieee     IEEE-695"
echo.
<nul set /p ="    dbg      Debug trace"
echo.
exit /b 1

:new_format_help
echo.
powershell write-host "Project Template Formats:" -f Yellow
echo.
powershell write-host "Windows Formats:" -f Cyan
echo     win32    - Windows 32-bit Console Application
echo              * Uses stdcall calling convention
echo              * Windows API with @N decoration
echo.
echo     win64    - Windows 64-bit Console Application
echo              * Microsoft x64 calling convention
echo              * 32-byte shadow space
echo              * Register parameters (rcx, rdx, r8, r9)
echo.
echo     mips     - MIPS R3000 Assembly
echo              * Uses MIPS instruction set
echo              * No operating system or library dependencies
echo.
exit /b 0

:check_args
if !build!==1 if !obj!==0 if !exe!==0 (
    powershell write-host "Error: Build-only mode requires either /obj or /exe to save output files" -f Red
    exit /b 1
)

:main
if not exist "!file!" (
    powershell write-host "Error: File not found - !file!" -f Red
    exit /b 1
)

if !showtime!==1 (
    set "starttime=%time%"
)

if /i "!format!"=="mips" (
    if not exist "%INSTALL_DIR%\mars4_5.jar" (
        powershell write-host "Error: MARS MIPS simulator not found. Please run setup_asmrun.bat first" -f Red
        goto :done
    )
    powershell write-host "Running !name!.asm with MARS simulator..." -f Cyan
    if !build!==0 (
        echo.
        java -jar "%INSTALL_DIR%\mars4_5.jar" "!file!"
    )
    goto :done
)

powershell write-host "Building !name!.asm [!format! format]..." -f Cyan
set "tmp=%TEMP%\asm_%RANDOM%"
mkdir "!tmp!"

REM Compile with selected format
nasm -f "!format!" "!file!" -o "!tmp!\!name!.obj"

if errorlevel 1 (
    powershell write-host "Assembly failed" -f Red
    goto :done
)

if !showtime!==1 (
    call :show_time "Compilation"
)

if !obj!==1 (
    copy "!tmp!\!name!.obj" . >nul
    powershell "$size = (Get-Item '!name!.obj').Length; write-host ('Created !name!.obj ({0:N0} bytes)' -f $size)" -f Green
)

REM Link based on format
if /i "!format!"=="win64" (
    golink /entry:main /console "!tmp!\!name!.obj" kernel32.dll user32.dll > link.log 2>&1
    if errorlevel 1 (
        echo Linking failed:
        more +1 link.log | findstr /V /C:"GoLink" /C:"Copyright" /C:"Version" /C:"Error!"
        del link.log
        exit /b 1
    )
    del link.log
) else if /i "!format!"=="win32" (
    golink /entry:main /console "!tmp!\!name!.obj" kernel32.dll > link.log 2>&1
    if errorlevel 1 (
        echo Linking failed:
        more +1 link.log | findstr /V /C:"GoLink" /C:"Copyright" /C:"Version" /C:"Error!"
        del link.log
        exit /b 1
    )
    del link.log
) else (
    powershell write-host "Note: Cannot link '!format!' format - platform-specific linker needed" -f Yellow
    goto :done
)

if !exe!==1 (
    copy "!tmp!\!name!.exe" . >nul
    powershell "$size = (Get-Item '!name!.exe').Length; write-host ('Created !name!.exe ({0:N0} bytes)' -f $size)" -f Green
)

if !build!==1 goto :done

if /i "!format!"=="win32" (
    powershell write-host "Running !name!.asm..." -f Cyan
    echo.
    "!tmp!\!name!.exe"
) else if /i "!format!"=="win64" (
    powershell write-host "Running !name!.asm..." -f Cyan
    echo.
    "!tmp!\!name!.exe"
) else (
    powershell write-host "Note: Cannot run executable for format '!format!' on Windows" -f Yellow
)

:done
rd /s /q "!tmp!" >nul 2>&1

if !pause!==1 (
    powershell write-host "Press any key to continue..." -f Yellow
    pause >nul
)
endlocal
exit /b 0

:new_project
shift
set "proj_name=%~1"
set "format="
set "proj_dir=%CD%\%proj_name%"

:parse_new_args
shift
if "%~1"=="" goto end_parse_new
if /i "%~1"=="/f" (
    set "format=%~2"
    shift
    goto parse_new_args
)
goto parse_new_args

:end_parse_new

if "%format%"=="" (
    call :show_help
    exit /b 1
)

if /i not "%format%"=="win32" if /i not "%format%"=="win64" if /i not "%format%"=="mips" (
    powershell write-host "Error: Invalid format. Must be win32, win64 or mips" -f Red
    exit /b 1
)

REM Create project directory
if exist "!proj_dir!" (
    powershell write-host "Error: Directory already exists: !proj_dir!" -f Red
    exit /b 1
)
mkdir "!proj_dir!"

REM Create source file from embedded template
set "src=!proj_dir!\!proj_name!.asm"
if /i "!format!"=="win32" (
    call :write_win32_template "!src!"
    if errorlevel 1 (
        powershell write-host "Error: Failed to create source file" -f Red
        rd /s /q "!proj_dir!" >nul 2>&1
        exit /b 1
    )
) else if /i "!format!"=="win64" (
    call :write_win64_template "!src!"
    if errorlevel 1 (
        powershell write-host "Error: Failed to create source file" -f Red
        rd /s /q "!proj_dir!" >nul 2>&1
        exit /b 1
    )
) else if /i "!format!"=="mips" (
    call :write_mips_template "!src!"
    if errorlevel 1 (
        powershell write-host "Error: Failed to create source file" -f Red
        rd /s /q "!proj_dir!" >nul 2>&1
        exit /b 1
    )
)

REM Create README.md
set "readme=!proj_dir!\README.md"
echo # !proj_name! > "!readme!"
echo. >> "!readme!"
echo Assembly project created with format: !format! >> "!readme!"
echo. >> "!readme!"
echo ## Building >> "!readme!"
echo. >> "!readme!"
echo ```batch >> "!readme!"
echo asmrun !proj_name!.asm /exe /f !format! >> "!readme!"
echo ``` >> "!readme!"

REM Create .gitignore
set "gitignore=!proj_dir!\.gitignore"
echo *.exe > "!gitignore!"
echo *.o >> "!gitignore!"
echo *.obj >> "!gitignore!"

powershell -Command "$h='Write-Host'; & $h '+----------------------------------------+' -ForegroundColor Cyan; & $h '|     Assembly Project Creation Tool     |' -ForegroundColor Cyan; & $h '+----------------------------------------+' -ForegroundColor Cyan; & $h ''; & $h 'Project Details:' -ForegroundColor Yellow; & $h -NoNewLine ' * Name: ' -ForegroundColor White; & $h '!proj_name!' -ForegroundColor Green; & $h -NoNewLine ' * Format: ' -ForegroundColor White; & $h '!format!' -ForegroundColor Green; & $h -NoNewLine ' * Path: ' -ForegroundColor White; & $h '!proj_dir!' -ForegroundColor Green; & $h ''; & $h 'Created Files:' -ForegroundColor Yellow; & $h -NoNewLine ' * ' -ForegroundColor White; & $h -NoNewLine '!proj_name!.asm ' -ForegroundColor Cyan; & $h '- Main source file' -ForegroundColor DarkGray; & $h -NoNewLine ' * ' -ForegroundColor White; & $h -NoNewLine 'README.md ' -ForegroundColor Cyan; & $h '- Project documentation' -ForegroundColor DarkGray; & $h -NoNewLine ' * ' -ForegroundColor White; & $h -NoNewLine '.gitignore ' -ForegroundColor Cyan; & $h '- Git configuration' -ForegroundColor DarkGray; & $h ''; & $h 'Next Steps:' -ForegroundColor Yellow; & $h -NoNewLine ' 1. ' -ForegroundColor White; & $h -NoNewLine 'cd ' -ForegroundColor DarkCyan; & $h -NoNewLine '\"!proj_dir!\"' -ForegroundColor Green; & $h ''; & $h -NoNewLine ' 2. ' -ForegroundColor White; & $h 'asmrun !proj_name!.asm /f !format!' -ForegroundColor DarkCyan"
echo.

exit /b 0

:write_win32_template
(
    echo ; !proj_name!.asm - Win32 Console Application
    echo ; Build: asmrun !proj_name!.asm /exe /f win32
    echo.
    echo section .data
    echo     msg db "Hello, World", 0x0D, 0x0A, 0    ; Message with CRLF and null terminator
    echo     msg_len equ $ - msg                      ; Message length
    echo.
    echo section .text
    echo     extern _GetStdHandle@4
    echo     extern _WriteConsoleA@20
    echo     extern _ExitProcess@4
    echo     global main                              ; Entry point for console subsystem
    echo.
    echo main:
    echo     ; Get handle to stdout and write message
    echo     push    dword -11                        ; STD_OUTPUT_HANDLE
    echo     call    _GetStdHandle@4                  ; Call GetStdHandle
    echo     push    dword 0                          ; lpReserved
    echo     push    dword msg_len                    ; nNumberOfCharsToWrite
    echo     push    dword msg                        ; lpBuffer
    echo     push    eax                              ; hConsoleOutput (stdout handle^)
    echo     call    _WriteConsoleA@20                ; Call WriteConsoleA
    echo.
    echo     ; Exit process
    echo     push    dword 0                          ; Exit code
    echo     call    _ExitProcess@4                   ; Call ExitProcess
) > "%~1"
exit /b 0

:write_win64_template
(
    echo ; !proj_name!.asm - Win64 Console Application
    echo ; Build: asmrun !proj_name!.asm /exe /f win64
    echo.
    echo section .data
    echo     msg db "Hello, World", 0x0D, 0x0A, 0    ; Message with CRLF and null terminator
    echo     msg_len equ $ - msg                      ; Message length
    echo.
    echo section .text
    echo     extern GetStdHandle
    echo     extern WriteConsoleA
    echo     extern ExitProcess
    echo     global main                              ; Entry point for console subsystem
    echo.
    echo main:
    echo     ; Get handle to stdout
    echo     mov rcx, -11                             ; STD_OUTPUT_HANDLE
    echo     call GetStdHandle                        ; Call GetStdHandle
    echo.
    echo     ; Write message to console
    echo     mov rcx, rax                             ; Handle to stdout
    echo     lea rdx, [msg]                           ; Address of the message
    echo     mov r8, msg_len                          ; Message length
    echo     xor r9, r9                              ; lpReserved (null^)
    echo     call WriteConsoleA                       ; Call WriteConsoleA
    echo.
    echo     ; Exit process
    echo     xor rcx, rcx                             ; Exit code 0
    echo     call ExitProcess                         ; Call ExitProcess
) > "%~1"
exit /b 0

:write_mips_template
>"%~1" (
    echo # !proj_name!.asm - MIPS R3000 Assembly
    echo # Build: asmrun !proj_name!.asm /exe /f mips
    echo.
    echo .data
    echo msg: .asciiz "Hello, World\n"    # Message with newline
    echo.
    echo.
    echo .text
    echo .globl main         # Entry point
    echo main:
    echo     # Print message
    echo     li $v0, 4       # syscall 4 (print_str^)
    echo     la $a0, msg     # Load address of msg
    echo     syscall
    echo.
    echo     # Exit program
    echo     li $v0, 10      # syscall 10 (exit^)
    echo     syscall
    echo.
)
if errorlevel 1 exit /b 1
exit /b 0

:show_time
set "endtime=%time%"
for /f "tokens=1-4 delims=:,." %%a in ("%starttime%") do (
    set /a "start=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)*100+1%%d %% 100"
)
for /f "tokens=1-4 delims=:,." %%a in ("%endtime%") do (
    set /a "end=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)*100+1%%d %% 100"
)
set /a elapsed=end-start
set /a hh=elapsed/(60*60*100), rest=elapsed%%(60*60*100), mm=rest/(60*100), rest%%=60*100, ss=rest/100, cc=rest%%100
if %mm% lss 10 set mm=0%mm%
if %ss% lss 10 set ss=0%ss%
if %cc% lss 10 set cc=0%cc%
echo %~1 took %ss%.%cc% seconds
exit /b
