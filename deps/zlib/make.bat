@ECHO OFF

@REM https://github.com/mitsuba-renderer/zlib/tree/54d591eabf9fe0e84c725638f8d5d8d202a093fa

PUSHD C:\Program Files (x86)\Microsoft Visual Studio\2019\Community
CALL VC\Auxiliary\Build\vcvars64.bat
POPD

SET OUTDIR=out
IF NOT EXIST %OUTDIR% (MKDIR %OUTDIR%)
PUSHD %OUTDIR%
cmake -G Ninja ^
    -DZLIB_BUILD_STATIC_LIBS=on ^
    -DZLIB_BUILD_SHARED_LIBS=off ^
    -DCMAKE_INSTALL_PREFIX=%~dp0 ^
    -DCMAKE_BUILD_TYPE=Release ^
    ..\src
IF %ERRORLEVEL% == 0 (ninja && ninja install)
POPD
