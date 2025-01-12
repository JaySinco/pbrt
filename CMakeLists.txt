# TODO: many of the best practices described here
# (https://www.slideshare.net/DanielPfeifer1/cmake-48475415) are violated
# in this file. Would be nice to address some of these.

CMAKE_MINIMUM_REQUIRED ( VERSION 3.2 )

# For sanitizers
SET (CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake" ${CMAKE_MODULE_PATH})

PROJECT ( PBRT-V3 )

OPTION(PBRT_FLOAT_AS_DOUBLE "Use 64-bit floats" OFF)

IF (PBRT_FLOAT_AS_DOUBLE)
  ADD_DEFINITIONS ( -D PBRT_FLOAT_AS_DOUBLE )
ENDIF()

OPTION(PBRT_SAMPLED_SPECTRUM "Use SampledSpectrum rather than RGBSpectrum" OFF)

IF (PBRT_SAMPLED_SPECTRUM)
  ADD_DEFINITIONS ( -D PBRT_SAMPLED_SPECTRUM )
ENDIF()

ENABLE_TESTING()

if (NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  message(STATUS "Setting build type to 'Release' as none was specified.")
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build." FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release"
    "MinSizeRel" "RelWithDebInfo")
endif()

FIND_PACKAGE ( Sanitizers )
FIND_PACKAGE ( Threads )

IF(CMAKE_BUILD_TYPE MATCHES RELEASE)
  ADD_DEFINITIONS (-DNDEBUG)
ENDIF()

SET_PROPERTY(GLOBAL PROPERTY USE_FOLDERS ON)

###########################################################################
# Annoying compiler-specific details

IF(CMAKE_COMPILER_IS_GNUCXX)
  SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=gnu++11")
  SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-conversion-null")
ELSEIF(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
  SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
  SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-deprecated-register")
ELSEIF(CMAKE_CXX_COMPILER_ID STREQUAL "Intel")
  SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

  FIND_PROGRAM(XIAR xiar)
  IF(XIAR)
    SET(CMAKE_AR "${XIAR}")
  ENDIF(XIAR)
  MARK_AS_ADVANCED(XIAR)

  FIND_PROGRAM(XILD xild)
  IF(XILD)
    SET(CMAKE_LINKER "${XILD}")
  ENDIF(XILD)
  MARK_AS_ADVANCED(XILD)

  # ICC will default to -fp-model fast=1, which performs value-unsafe optimizations which will
  # cause pbrt_test to fail. For safety, -fp-model precise is explicitly set here by default.
  set(FP_MODEL "precise" CACHE STRING "The floating point model to compile with.")
  set_property(CACHE FP_MODEL PROPERTY STRINGS "precise" "fast=1" "fast=2")

  SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fp-model ${FP_MODEL}")
ENDIF()

IF(MSVC)
  ADD_DEFINITIONS (/D _CRT_SECURE_NO_WARNINGS)
  SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /ignore:4099")
ENDIF()

INCLUDE (CheckIncludeFiles)

CHECK_INCLUDE_FILES ( alloca.h HAVE_ALLOCA_H )
IF ( HAVE_ALLOCA_H )
  ADD_DEFINITIONS ( -D PBRT_HAVE_ALLOCA_H )
ENDIF ()

CHECK_INCLUDE_FILES ( memory.h HAVE_MEMORY_H )
IF ( HAVE_MEMORY_H )
  ADD_DEFINITIONS ( -D PBRT_HAVE_MEMORY_H )
ENDIF ()

###########################################################################
# Check for various C++11 features and set preprocessor variables or
# define workarounds.

INCLUDE (CheckCXXSourceCompiles)
INCLUDE (CheckCXXSourceRuns)

CHECK_CXX_SOURCE_COMPILES (
  "int main() { float x = 0x1p-32f; }"
  HAVE_HEX_FP_CONSTANTS )
IF ( HAVE_HEX_FP_CONSTANTS )
  ADD_DEFINITIONS ( -D PBRT_HAVE_HEX_FP_CONSTANTS )
ENDIF ()

CHECK_CXX_SOURCE_COMPILES (
  "int main() { int x = 0b101011; }"
  HAVE_BINARY_CONSTANTS )
IF ( HAVE_BINARY_CONSTANTS )
  ADD_DEFINITIONS ( -D PBRT_HAVE_BINARY_CONSTANTS )
ENDIF ()

CHECK_CXX_SOURCE_COMPILES (
  "int main() { constexpr int x = 0; }"
  HAVE_CONSTEXPR )
IF ( HAVE_CONSTEXPR )
  ADD_DEFINITIONS ( -D PBRT_HAVE_CONSTEXPR )
  ADD_DEFINITIONS ( -D PBRT_CONSTEXPR=constexpr )
ELSE ()
  ADD_DEFINITIONS ( -D PBRT_CONSTEXPR=const )
ENDIF ()

CHECK_CXX_SOURCE_COMPILES (
  "struct alignas(32) Foo { char x; }; int main() { }"
  HAVE_ALIGNAS )
IF ( HAVE_ALIGNAS )
  ADD_DEFINITIONS ( -D PBRT_HAVE_ALIGNAS )
ENDIF ()

CHECK_CXX_SOURCE_COMPILES (
  "int main() { int x = alignof(double); }"
  HAVE_ALIGNOF )
IF ( HAVE_ALIGNOF )
  ADD_DEFINITIONS ( -D PBRT_HAVE_ALIGNOF )
ENDIF ()

CHECK_CXX_SOURCE_RUNS ( "
#include <signal.h>
#include <string.h>
#include <sys/time.h>
void ReportProfileSample(int, siginfo_t *, void *) { }
int main() {
    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_sigaction = ReportProfileSample;
    sa.sa_flags = SA_RESTART | SA_SIGINFO;
    sigemptyset(&sa.sa_mask);
    sigaction(SIGPROF, &sa, NULL);
    static struct itimerval timer;
    return setitimer(ITIMER_PROF, &timer, NULL) == 0 ? 0 : 1;
}
" HAVE_ITIMER )
IF ( HAVE_ITIMER )
  ADD_DEFINITIONS ( -D PBRT_HAVE_ITIMER )
ENDIF()

CHECK_CXX_SOURCE_COMPILES ( "
class Bar { public: Bar() { x = 0; } float x; };
struct Foo { union { int x[10]; Bar b; }; Foo() : b() { } };
int main() { Foo f; }
" HAVE_NONPOD_IN_UNIONS )
IF ( HAVE_NONPOD_IN_UNIONS )
  ADD_DEFINITIONS ( -D PBRT_HAVE_NONPOD_IN_UNIONS )
ENDIF ()

CHECK_CXX_SOURCE_COMPILES ( "
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
int main() {
   int fd = open(\"foo\", O_RDONLY);
   struct stat s;
   fstat(fd, &s);
   size_t len = s.st_size;
   void *ptr = mmap(0, len, PROT_READ, MAP_FILE | MAP_SHARED, fd, 0);
   munmap(ptr, len);   
}
" HAVE_MMAP )
if ( HAVE_MMAP )
  ADD_DEFINITIONS ( -D PBRT_HAVE_MMAP )
ENDIF ()

########################################
# noinline

CHECK_CXX_SOURCE_COMPILES (
"__declspec(noinline) void foo() { }
int main() { }"
HAVE_DECLSPEC_NOINLINE )

CHECK_CXX_SOURCE_COMPILES (
"__attribute__((noinline)) void foo() { }
int main() { }"
HAVE_ATTRIBUTE_NOINLINE )

IF ( HAVE_ATTRIBUTE_NOINLINE )
  ADD_DEFINITIONS ( -D "PBRT_NOINLINE=__attribute__\\(\\(noinline\\)\\)" )
ELSEIF ( HAVE_DECLSPEC_NOINLINE )
  ADD_DEFINITIONS ( -D "PBRT_NOINLINE=__declspec(noinline)" )
ELSE ()
  ADD_DEFINITIONS ( -D PBRT_NOINLINE )
ENDIF ()

########################################
# Aligned memory allocation

CHECK_CXX_SOURCE_COMPILES ( "
#include <malloc.h>
int main() { void * ptr = _aligned_malloc(1024, 32); }
" HAVE__ALIGNED_MALLOC )

CHECK_CXX_SOURCE_COMPILES ( "
#include <stdlib.h>
int main() {
  void *ptr;
  posix_memalign(&ptr, 32, 1024);
} " HAVE_POSIX_MEMALIGN )

CHECK_CXX_SOURCE_COMPILES ( "
#include <malloc.h>
int main() {
    void *ptr = memalign(32, 1024);
} " HAVE_MEMALIGN )

IF ( HAVE__ALIGNED_MALLOC )
  ADD_DEFINITIONS ( -D PBRT_HAVE__ALIGNED_MALLOC )
ELSEIF ( HAVE_POSIX_MEMALIGN )
  ADD_DEFINITIONS ( -D PBRT_HAVE_POSIX_MEMALIGN )
ELSEIF ( HAVE_MEMALIGN )
  ADD_DEFINITIONS ( -D PBRTHAVE_MEMALIGN )
ELSE ()
  MESSAGE ( SEND_ERROR "Unable to find a way to allocate aligned memory" )
ENDIF ()

########################################
# thread-local variables

CHECK_CXX_SOURCE_COMPILES ( "
#ifdef __CYGWIN__
// Hack to work around https://gcc.gnu.org/bugzilla/show_bug.cgi?id=64697
#error \"No thread_local on cygwin\"
#endif  // __CYGWIN__
thread_local int x; int main() { }
" HAVE_THREAD_LOCAL )

CHECK_CXX_SOURCE_COMPILES ( "
__declspec(thread) int x; int main() { }
" HAVE_DECLSPEC_THREAD )

CHECK_CXX_SOURCE_COMPILES ( "
__thread int x; int main() { }
" HAVE___THREAD )

IF ( HAVE_THREAD_LOCAL )
  ADD_DEFINITIONS ( -D PBRT_THREAD_LOCAL=thread_local )
ELSEIF ( HAVE___THREAD )
  ADD_DEFINITIONS ( -D PBRT_THREAD_LOCAL=__thread )
ELSEIF ( HAVE_DECLSPEC_THREAD )
  ADD_DEFINITIONS ( -D "PBRT_THREAD_LOCAL=__declspec(thread)" )
ELSE ()
  MESSAGE ( SEND_ERROR "Unable to find a way to declare a thread-local variable")
ENDIF ()

###########################################################################
# zlib

ADD_LIBRARY( zlibstatic STATIC IMPORTED GLOBAL )
SET_TARGET_PROPERTIES( zlibstatic PROPERTIES IMPORTED_LOCATION ${CMAKE_SOURCE_DIR}/deps/zlib/${CMAKE_BUILD_TYPE}/lib/zlibstatic.lib )
INCLUDE_DIRECTORIES( ${CMAKE_SOURCE_DIR}/deps/zlib/${CMAKE_BUILD_TYPE}/include )

###########################################################################
# OpenEXR

ADD_LIBRARY( IlmImf STATIC IMPORTED GLOBAL )
SET_TARGET_PROPERTIES( IlmImf PROPERTIES IMPORTED_LOCATION ${CMAKE_SOURCE_DIR}/deps/openexr/${CMAKE_BUILD_TYPE}/lib/IlmImf.lib )
ADD_LIBRARY( IlmThread STATIC IMPORTED GLOBAL )
SET_TARGET_PROPERTIES( IlmThread PROPERTIES IMPORTED_LOCATION ${CMAKE_SOURCE_DIR}/deps/openexr/${CMAKE_BUILD_TYPE}/lib/IlmThread.lib )
ADD_LIBRARY( Iex STATIC IMPORTED GLOBAL )
SET_TARGET_PROPERTIES( Iex PROPERTIES IMPORTED_LOCATION ${CMAKE_SOURCE_DIR}/deps/openexr/${CMAKE_BUILD_TYPE}/lib/Iex.lib )
ADD_LIBRARY( Imath STATIC IMPORTED GLOBAL )
SET_TARGET_PROPERTIES( Imath PROPERTIES IMPORTED_LOCATION ${CMAKE_SOURCE_DIR}/deps/openexr/${CMAKE_BUILD_TYPE}/lib/Imath.lib )
ADD_LIBRARY( Half STATIC IMPORTED GLOBAL )
SET_TARGET_PROPERTIES( Half PROPERTIES IMPORTED_LOCATION ${CMAKE_SOURCE_DIR}/deps/openexr/${CMAKE_BUILD_TYPE}/lib/Half.lib )
INCLUDE_DIRECTORIES( ${CMAKE_SOURCE_DIR}/deps/openexr/${CMAKE_BUILD_TYPE}/include/OpenEXR )
IF(WIN32)
  SET(OPENEXR_LIBS IlmImf IlmThread Iex Imath Half zlibstatic)
ELSE()
  SET(OPENEXR_LIBS IlmImf Imath Half)
ENDIF()

###########################################################################
# glog

IF(WIN32)
  ADD_DEFINITIONS( /D GOOGLE_GLOG_DLL_DECL= )
ENDIF()
ADD_LIBRARY( glog STATIC IMPORTED GLOBAL )
SET_TARGET_PROPERTIES( glog PROPERTIES IMPORTED_LOCATION ${CMAKE_SOURCE_DIR}/deps/glog/${CMAKE_BUILD_TYPE}/lib/glog.lib )
INCLUDE_DIRECTORIES( ${CMAKE_SOURCE_DIR}/deps/glog/${CMAKE_BUILD_TYPE}/include )

###########################################################################
# ptex

IF ( WIN32 )
  ADD_DEFINITIONS( /D PTEX_STATIC )
ENDIF ()
ADD_LIBRARY( Ptex_static STATIC IMPORTED GLOBAL )
SET_TARGET_PROPERTIES( Ptex_static PROPERTIES IMPORTED_LOCATION ${CMAKE_SOURCE_DIR}/deps/ptex/${CMAKE_BUILD_TYPE}/lib/Ptex.lib )
INCLUDE_DIRECTORIES( ${CMAKE_SOURCE_DIR}/deps/ptex/${CMAKE_BUILD_TYPE}/include )

###########################################################################
# On to pbrt...

SET ( PBRT_CORE_SOURCE
  src/core/api.cpp
  src/core/bssrdf.cpp
  src/core/camera.cpp
  src/core/efloat.cpp
  src/core/error.cpp
  src/core/fileutil.cpp
  src/core/film.cpp
  src/core/filter.cpp
  src/core/floatfile.cpp
  src/core/geometry.cpp
  src/core/imageio.cpp
  src/core/integrator.cpp
  src/core/interaction.cpp
  src/core/interpolation.cpp
  src/core/light.cpp
  src/core/lightdistrib.cpp
  src/core/lowdiscrepancy.cpp
  src/core/material.cpp
  src/core/medium.cpp
  src/core/memory.cpp
  src/core/microfacet.cpp
  src/core/parallel.cpp
  src/core/paramset.cpp
  src/core/parser.cpp
  src/core/primitive.cpp
  src/core/progressreporter.cpp
  src/core/quaternion.cpp
  src/core/reflection.cpp
  src/core/sampler.cpp
  src/core/sampling.cpp
  src/core/scene.cpp
  src/core/shape.cpp
  src/core/sobolmatrices.cpp
  src/core/spectrum.cpp
  src/core/stats.cpp
  src/core/texture.cpp
  src/core/transform.cpp
  )

SET ( PBRT_CORE_HEADERS
  src/core/api.h
  src/core/bssrdf.h
  src/core/camera.h
  src/core/efloat.h
  src/core/error.h
  src/core/fileutil.h
  src/core/film.h
  src/core/filter.h
  src/core/floatfile.h
  src/core/geometry.h
  src/core/imageio.h
  src/core/integrator.h
  src/core/interaction.h
  src/core/interpolation.h
  src/core/light.h
  src/core/lowdiscrepancy.h
  src/core/material.h
  src/core/medium.h
  src/core/memory.h
  src/core/microfacet.h
  src/core/mipmap.h
  src/core/parallel.h
  src/core/paramset.h
  src/core/parser.h
  src/core/pbrt.h
  src/core/primitive.h
  src/core/progressreporter.h
  src/core/quaternion.h
  src/core/reflection.h
  src/core/rng.h
  src/core/sampler.h
  src/core/sampling.h
  src/core/scene.h
  src/core/shape.h
  src/core/sobolmatrices.h
  src/core/spectrum.h
  src/core/stats.h
  src/core/stringprint.h
  src/core/texture.h
  src/core/transform.h
  )

FILE ( GLOB PBRT_SOURCE
  deps/.ext/src/*
  src/accelerators/*
  src/cameras/*
  src/filters/*
  src/integrators/*
  src/lights/*
  src/materials/*
  src/samplers/*
  src/shapes/*
  src/textures/*
  src/media/*
  )

INCLUDE_DIRECTORIES ( src )
INCLUDE_DIRECTORIES ( src/core )
INCLUDE_DIRECTORIES ( deps/.ext/src )

# Visual Studio source folders
SOURCE_GROUP (core REGULAR_EXPRESSION src/core/.*)
SOURCE_GROUP (ext REGULAR_EXPRESSION deps/.ext/src/.*)
SOURCE_GROUP (accelerators REGULAR_EXPRESSION src/accelerators/.*)
SOURCE_GROUP (cameras REGULAR_EXPRESSION src/cameras/.*)
SOURCE_GROUP (filters REGULAR_EXPRESSION src/filters/.*)
SOURCE_GROUP (integrators REGULAR_EXPRESSION src/integrators/.*)
SOURCE_GROUP (lights REGULAR_EXPRESSION src/lights/.*)
SOURCE_GROUP (materials REGULAR_EXPRESSION src/materials/.*)
SOURCE_GROUP (samplers REGULAR_EXPRESSION src/samplers/.*)
SOURCE_GROUP (shapes REGULAR_EXPRESSION src/shapes/.*)
SOURCE_GROUP (textures REGULAR_EXPRESSION src/textures/.*)
SOURCE_GROUP (media REGULAR_EXPRESSION src/media/.*)

###########################################################################
# pbrt libraries and executables

ADD_LIBRARY ( pbrt STATIC
  ${PBRT_YACC_LEX_SOURCE}
  ${PBRT_CORE_SOURCE}
  ${PBRT_CORE_HEADERS}
  ${PBRT_SOURCE}
  )
ADD_SANITIZERS ( pbrt )

# A non-exhaustive but pretty representative set..
# Note that we work-around shoddy c++11 support in MSVC2013
# (constexpr, etc.), so don't test for that stuff here
SET ( PBRT_CXX11_FEATURES
  cxx_auto_type
  cxx_explicit_conversions
  cxx_lambdas
  cxx_nullptr
  cxx_range_for
  cxx_static_assert
)
TARGET_COMPILE_FEATURES ( pbrt PRIVATE ${PBRT_CXX11_FEATURES} )

IF (WIN32)
  # Avoid a name clash when building on Visual Studio
  SET_TARGET_PROPERTIES ( pbrt PROPERTIES OUTPUT_NAME libpbrt )
ENDIF()

SET(ALL_PBRT_LIBS
  pbrt
  ${CMAKE_THREAD_LIBS_INIT}
  ${OPENEXR_LIBS}
  glog
  Ptex_static
  zlibstatic
)

# Main renderer
ADD_EXECUTABLE ( pbrt_exe src/main/pbrt.cpp )
ADD_SANITIZERS ( pbrt_exe )

SET_TARGET_PROPERTIES ( pbrt_exe PROPERTIES OUTPUT_NAME pbrt )
TARGET_COMPILE_FEATURES ( pbrt_exe PRIVATE ${PBRT_CXX11_FEATURES} )
TARGET_LINK_LIBRARIES ( pbrt_exe ${ALL_PBRT_LIBS} )

# Tools
ADD_EXECUTABLE ( bsdftest src/tools/bsdftest.cpp )
ADD_SANITIZERS ( bsdftest )
TARGET_COMPILE_FEATURES ( bsdftest PRIVATE ${PBRT_CXX11_FEATURES} )
TARGET_LINK_LIBRARIES ( bsdftest ${ALL_PBRT_LIBS} )

ADD_EXECUTABLE ( imgtool src/tools/imgtool.cpp )
ADD_SANITIZERS ( imgtool )
TARGET_COMPILE_FEATURES ( imgtool PRIVATE ${PBRT_CXX11_FEATURES} )
TARGET_LINK_LIBRARIES ( imgtool ${ALL_PBRT_LIBS} )

ADD_EXECUTABLE ( obj2pbrt src/tools/obj2pbrt.cpp )
TARGET_COMPILE_FEATURES ( obj2pbrt PRIVATE ${PBRT_CXX11_FEATURES} )
ADD_SANITIZERS ( obj2pbrt )

ADD_EXECUTABLE ( cyhair2pbrt src/tools/cyhair2pbrt.cpp )
ADD_SANITIZERS ( cyhair2pbrt )

# Unit test

FILE ( GLOB PBRT_TEST_SOURCE
  src/tests/*.cpp
  src/tests/gtest/*.cc
  )

ADD_EXECUTABLE ( pbrt_test ${PBRT_TEST_SOURCE} )
ADD_SANITIZERS ( pbrt_test )
TARGET_COMPILE_FEATURES ( pbrt_test PRIVATE ${PBRT_CXX11_FEATURES} )
TARGET_LINK_LIBRARIES ( pbrt_test ${ALL_PBRT_LIBS} )

ADD_TEST ( pbrt_unit_test pbrt_test )

# Installation

INSTALL ( TARGETS
  pbrt_exe
  bsdftest
  imgtool
  obj2pbrt
  cyhair2pbrt
  DESTINATION
  bin
  )

INSTALL ( TARGETS
  pbrt
  DESTINATION
  lib
  )
