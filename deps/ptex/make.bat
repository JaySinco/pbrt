@ECHO OFF

@REM https://github.com/wdas/ptex/tree/4cd8e9a6db2b06e478dfbbd8c26eb6df97f84483

SET OUTDIR=out
SET BUILDTYPE=Release

IF "%1" == "debug" (SET BUILDTYPE=Debug)
ECHO -- Build configuration: "%BUILDTYPE%"

PUSHD C:\Program Files (x86)\Microsoft Visual Studio\2019\Community
CALL VC\Auxiliary\Build\vcvars64.bat
POPD

IF NOT EXIST %OUTDIR% (MKDIR %OUTDIR%)
PUSHD %OUTDIR%
cmake -G Ninja ^
    -DZLIB_LIBRARY=%~dp0..\zlib\%BUILDTYPE%\lib\zlibstatic.lib ^
    -DZLIB_INCLUDE_DIR=%~dp0..\zlib\%BUILDTYPE%\include ^
    -DPTEX_BUILD_SHARED_LIBS=off ^
    -DCMAKE_INSTALL_PREFIX=%~dp0%BUILDTYPE%  ^
    -DCMAKE_BUILD_TYPE=%BUILDTYPE% ^
    ..\src
IF %ERRORLEVEL% == 0 (ninja && ninja install)
POPD
