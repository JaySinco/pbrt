@ECHO OFF

SET OUTDIR=out
SET BINDIR=bin
SET TOOLDIR=%~dp0deps\.tools\Release\bin
SET BUILDTYPE=Release

IF "%1" == "clean" (
    IF EXIST %OUTDIR% (RMDIR /S/Q %OUTDIR%)
    IF EXIST %BINDIR% (RMDIR /S/Q %BINDIR%)
    GOTO end
)

IF "%1" == "fmt" (
    %TOOLDIR%\cloc.exe --quiet src
    FOR /R %~dp0src %%f IN (*) DO (%TOOLDIR%\clang-format.exe -i %%f)
    GOTO end
)

IF "%1" == "debug" (SET BUILDTYPE=Debug)
ECHO -- Build configuration: "%BUILDTYPE%"

PUSHD C:\Program Files (x86)\Microsoft Visual Studio\2019\Community
CALL VC\Auxiliary\Build\vcvars64.bat
POPD

IF NOT EXIST %OUTDIR% (MKDIR %OUTDIR%)
PUSHD %OUTDIR%
cmake -G Ninja ^
    -DCMAKE_EXE_LINKER_FLAGS="/manifest:no" ^
    -DCMAKE_RUNTIME_OUTPUT_DIRECTORY=%~dp0%BINDIR%\ ^
    -DCMAKE_BUILD_TYPE=%BUILDTYPE% ^
    ..
IF %ERRORLEVEL% == 0 (cmake --build .)
POPD

:end
