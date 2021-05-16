@ECHO OFF

@REM https://github.com/google/glog/tree/4d391fe692ae6b9e0105f473945c415a3ce5a401

PUSHD C:\Program Files (x86)\Microsoft Visual Studio\2019\Community
CALL VC\Auxiliary\Build\vcvars64.bat
POPD

SET OUTDIR=out
IF NOT EXIST %OUTDIR% (MKDIR %OUTDIR%)
PUSHD %OUTDIR%
cmake -G Ninja ^
    -DWITH_GFLAGS=off ^
    -DBUILD_SHARED_LIBS=off ^
    -DCMAKE_INSTALL_PREFIX=%~dp0 ^
    -DCMAKE_BUILD_TYPE=Release ^
    ..\src
IF %ERRORLEVEL% == 0 (ninja && ninja install)
POPD
