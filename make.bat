@ECHO OFF

SET OUTDIR=out

IF "%1" == "clean" (
    IF EXIST %OUTDIR% (RMDIR /S/Q %OUTDIR%)
    IF EXIST bin (RMDIR /S/Q bin)
    IF EXIST include (RMDIR /S/Q include)
    IF EXIST lib (RMDIR /S/Q lib)
    IF EXIST share (RMDIR /S/Q share)
    GOTO end
)

PUSHD C:\Program Files (x86)\Microsoft Visual Studio\2019\Community
CALL VC\Auxiliary\Build\vcvars64.bat
POPD

IF NOT EXIST %OUTDIR% (MKDIR %OUTDIR%)
PUSHD %OUTDIR%
cmake -G Ninja ^
    -DCMAKE_INSTALL_PREFIX=%~dp0 ^
    -DCMAKE_BUILD_TYPE=Debug ^
    ..
IF %ERRORLEVEL% == 0 (ninja && ninja install)
POPD

:end
