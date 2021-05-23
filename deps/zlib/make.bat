@ECHO OFF

@REM https://github.com/mitsuba-renderer/zlib/tree/54d591eabf9fe0e84c725638f8d5d8d202a093fa

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
    -DZLIB_BUILD_STATIC_LIBS=on ^
    -DZLIB_BUILD_SHARED_LIBS=off ^
    -DCMAKE_INSTALL_PREFIX=%~dp0%BUILDTYPE% ^
    -DCMAKE_BUILD_TYPE=%BUILDTYPE% ^
    ..\src
IF %ERRORLEVEL% == 0 (cmake --build . && cmake --install .)
POPD
