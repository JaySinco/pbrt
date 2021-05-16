@ECHO OFF

@REM https://github.com/wdas/ptex/tree/4cd8e9a6db2b06e478dfbbd8c26eb6df97f84483

PUSHD C:\Program Files (x86)\Microsoft Visual Studio\2019\Community
CALL VC\Auxiliary\Build\vcvars64.bat
POPD

SET OUTDIR=out
IF NOT EXIST %OUTDIR% (MKDIR %OUTDIR%)
PUSHD %OUTDIR%
cmake -G Ninja ^
    -DZLIB_LIBRARY=%~dp0..\zlib\lib\zlibstatic.lib ^
    -DPTEX_BUILD_SHARED_LIBS=off ^
    -DCMAKE_INSTALL_PREFIX=%~dp0 ^
    -DCMAKE_BUILD_TYPE=Release ^
    ..\src
IF %ERRORLEVEL% == 0 (ninja && ninja install)
POPD
