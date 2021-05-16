@ECHO OFF

@REM https://github.com/wjakob/openexr/tree/84793a726d77ad6cb9a510011c3907df809c32a4

PUSHD C:\Program Files (x86)\Microsoft Visual Studio\2019\Community
CALL VC\Auxiliary\Build\vcvars64.bat
POPD

SET OUTDIR=out
IF NOT EXIST %OUTDIR% (MKDIR %OUTDIR%)
PUSHD %OUTDIR%
cmake -G Ninja ^
    -DZLIB_LIBRARY=%~dp0..\zlib\lib\zlibstatic.lib ^
    -DILMBASE_NAMESPACE_VERSIONING=off ^
    -DOPENEXR_NAMESPACE_VERSIONING=off ^
    -DOPENEXR_BUILD_SHARED_LIBS=off ^
    -DILMBASE_BUILD_SHARED_LIBS=off ^
    -DCMAKE_INSTALL_PREFIX=%~dp0 ^
    -DCMAKE_BUILD_TYPE=Release ^
    ..\src
IF %ERRORLEVEL% == 0 (ninja && ninja install)
POPD
