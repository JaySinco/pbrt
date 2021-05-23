@ECHO OFF

@REM https://github.com/wjakob/openexr/tree/84793a726d77ad6cb9a510011c3907df809c32a4

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
    -DILMBASE_NAMESPACE_VERSIONING=off ^
    -DOPENEXR_NAMESPACE_VERSIONING=off ^
    -DOPENEXR_BUILD_SHARED_LIBS=off ^
    -DILMBASE_BUILD_SHARED_LIBS=off ^
    -DCMAKE_INSTALL_PREFIX=%~dp0%BUILDTYPE% ^
    -DCMAKE_BUILD_TYPE=%BUILDTYPE% ^
    ..\src
IF %ERRORLEVEL% == 0 (cmake --build . && cmake --install .)
POPD

XCOPY /Y/I/F src\OpenEXR\IlmImf\*.h %BUILDTYPE%\include\OpenEXR\
XCOPY /Y/I/F out\OpenEXR\IlmImf\IlmImf.lib %BUILDTYPE%\lib\
