cmake_minimum_required(VERSION 3.11.0)

if (NOT DEFINED RTOS)
  set(CMAKE_SYSTEM_NAME Generic)
else()
  set(CMAKE_SYSTEM_NAME ${RTOS})
endif()

set(CROSS_GCC_ARM_TOOLCHAIN TRUE)

if(MINGW OR CYGWIN OR WIN32)
    set(UTIL_SEARCH_CMD where)
elseif(UNIX OR APPLE)
    set(UTIL_SEARCH_CMD which)
endif()

if (NOT DEFINED TOOLCHAIN_PREFIX)
  set(TOOLCHAIN_PREFIX arm-none-eabi-)
endif()

execute_process(
  COMMAND ${UTIL_SEARCH_CMD} ${TOOLCHAIN_PREFIX}gcc
  OUTPUT_VARIABLE BINUTILS_PATH
  OUTPUT_STRIP_TRAILING_WHITESPACE
)

get_filename_component(ARM_TOOLCHAIN_DIR ${BINUTILS_PATH} DIRECTORY)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

set(CMAKE_C_COMPILER ${TOOLCHAIN_PREFIX}gcc CACHE STRING "C Compiler executable")
set(CMAKE_ASM_COMPILER ${CMAKE_C_COMPILER} CACHE STRING "ASM Compiler executable")
set(CMAKE_CXX_COMPILER ${TOOLCHAIN_PREFIX}g++ CACHE  STRING "CXX Compiler executable")

set(CMAKE_OBJCOPY ${ARM_TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}objcopy CACHE INTERNAL "objcopy tool")
set(CMAKE_SIZE_UTIL ${ARM_TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}size CACHE INTERNAL "size tool")

set(CMAKE_FIND_ROOT_PATH ${BINUTILS_PATH})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

if (NOT DEFINED ARM_CPU)
  message( FATAL_ERROR "ARM Core not specified, CMake will exit." )
else()
  set(CROSSGCC_FLAGS " -mcpu=${ARM_CPU}")
  if(${ARM_CPU} STREQUAL cortex-m7)
    set(CMAKE_SYSTEM_PROCESSOR "armv7")
  elseif(${ARM_CPU} STREQUAL cortex-m4)
    set(CMAKE_SYSTEM_PROCESSOR "armv7")
  elseif(${ARM_CPU} STREQUAL cortex-m3)
    set(CMAKE_SYSTEM_PROCESSOR "armv7")
  elseif(${ARM_CPU} STREQUAL cortex-m1)
    set(CMAKE_SYSTEM_PROCESSOR "armv6")
  elseif(${ARM_CPU} STREQUAL cortex-m0)
    set(CMAKE_SYSTEM_PROCESSOR "armv6")
  elseif(${ARM_CPU} STREQUAL cortex-m0plus)
    set(CMAKE_SYSTEM_PROCESSOR "armv6")
  else()
    message( WARNING "Toolchain file doesn't fully support [${ARM_CPU}], arch set to \"arm\"" )
    set(CMAKE_SYSTEM_PROCESSOR "arm")
  endif()
endif()

if(NOT DEFINED ARM_MODE)
  set(ARM_MODE thumb)
  message( STATUS "ARM Mode not specified, using thumb as default" )
endif()

if (ARM_MODE STREQUAL thumb)
  STRING(APPEND CROSSGCC_FLAGS " -mthumb")
elseif(ARM_MODE STREQUAL arm)
  #default behavior
else()
  message( FATAL_ERROR "Unknow ARM Mode ${ARM_MODE}, CMake will exit." )
endif()

if (NOT DEFINED ARM_FLOAT_ABI)
  set(ARM_FLOAT_ABI soft)
  message( STATUS "ARM Float ABI not specified, using soft as default" )
endif()

if (ARM_FLOAT_ABI MATCHES "(soft|softfp|hard)")
  STRING(APPEND CROSSGCC_FLAGS " -mfloat-abi=${ARM_FLOAT_ABI}")
else()
  message( FATAL_ERROR "Unknow ARM Float ABI ${ARM_FLOAT_ABI}, CMake will exit." )
endif()

if (ARM_FLOAT_ABI MATCHES "(softfp|hard)")
  if (NOT DEFINED ARM_FPU)
    set (ARM_FPU "auto")
  endif()
  STRING(APPEND CROSSGCC_FLAGS " -mfpu=${ARM_FPU}")
  if (CMAKE_SYSTEM_PROCESSOR STREQUAL armv7)
    set (CMAKE_SYSTEM_PROCESSOR armv7hf)
  endif()
else()
  set(ARM_FPU "")
endif()

set(CROSSGCC_COMPILER_FLAGS ${CROSSGCC_FLAGS})
set(CROSSGCC_LINKER_FLAGS ${CROSSGCC_FLAGS})

string(APPEND CROSSGCC_COMPILER_FLAGS "\
    -fdata-sections\
    -ffunction-sections\
    -Wall\
    "
)

set(CROSSGCC_CXX_COMPILER_FLAGS ${CROSSGCC_COMPILER_FLAGS})

if (DEFINED RTTI)
  string(APPEND CROSSGCC_CXX_COMPILER_FLAGS " -frtti")
else()
  string(APPEND CROSSGCC_CXX_COMPILER_FLAGS " -fno-rtti")
endif()

set(CROSSGCC_COMPILER_FLAGS_RELEASE "\
    -O3\
    "
)

set(CROSSGCC_COMPILER_FLAGS_DEBUG "\
    -Og\
    "
)

set(CROSSGCC_LINKER_FLAGS ${CROSSGCC_FLAGS})

if (DEFINED LINKER_SCRIPT_FILE)
  string(APPEND CROSSGCC_LINKER_FLAGS " -T${LINKER_SCRIPT_FILE}")
endif()


string(APPEND CROSSGCC_LINKER_FLAGS "\
    -specs=nosys.specs\
    -lc\
    -lm\
    -lnosys\
    -Wl,-Map=${PROJECT_NAME}.map,--cref\
    -Wl,--gc-sections\
    "
)

set(CMAKE_TRY_COMPILE_PLATFORM_VARIABLES
  ARM_MODE
  ARM_CPU
  ARM_FLOAT_ABI
  ARM_FPU
  LINKER_SCRIPT_FILE
  TOOLCHAIN_PREFIX
  RTOS
  RTTI
)

set(CMAKE_C_FLAGS_INIT ${CROSSGCC_COMPILER_FLAGS})
set(CMAKE_CXX_FLAGS_INIT ${CROSSGCC_CXX_COMPILER_FLAGS})
set(CMAKE_ASM_FLAGS_INIT ${CROSSGCC_COMPILER_FLAGS})
set(CMAKE_C_FLAGS_DEBUG_INIT ${CROSSGCC_COMPILER_FLAGS_DEBUG})
set(CMAKE_CXX_FLAGS_DEBUG_INIT ${CROSSGCC_COMPILER_FLAGS_DEBUG})
set(CMAKE_ASM_FLAGS_DEBUG_INIT ${CROSSGCC_COMPILER_FLAGS_DEBUG})
set(CMAKE_C_FLAGS_RELEASE_INIT ${CROSSGCC_COMPILER_FLAGS_RELEASE})
set(CMAKE_CXX_FLAGS_RELEASE_INIT ${CROSSGCC_COMPILER_FLAGS_RELEASE})
set(CMAKE_ASM_FLAGS_RELEASE_INIT ${CROSSGCC_COMPILER_FLAGS_RELEASE})
set(CMAKE_EXE_LINKER_FLAGS_INIT ${CROSSGCC_LINKER_FLAGS})

# Touch toolchain variable to suppress "unused variable" warning.
# This happens if CMake is invoked with the same command line the second time.
if(CMAKE_TOOLCHAIN_FILE)
endif()

function(target_add_binary_format)
    cmake_parse_arguments(
            BINARY_FORMAT
            "BIN;HEX;ELF"
            "TARGET"
            ""
            ${ARGN}
        )
    if (BINARY_FORMAT_BIN)
    add_custom_command(TARGET ${BINARY_FORMAT_TARGET}
      POST_BUILD
      COMMAND ${CMAKE_OBJCOPY} -O binary $<TARGET_FILE:${BINARY_FORMAT_TARGET}> $<TARGET_FILE:${BINARY_FORMAT_TARGET}>.bin)
    endif()

    if (BINARY_FORMAT_HEX)
    add_custom_command(TARGET ${BINARY_FORMAT_TARGET}
      POST_BUILD
      COMMAND ${CMAKE_OBJCOPY} -O ihex $<TARGET_FILE:${BINARY_FORMAT_TARGET}> $<TARGET_FILE:${BINARY_FORMAT_TARGET}>.hex)
    endif()

    if (BINARY_FORMAT_ELF)
    add_custom_command(TARGET ${BINARY_FORMAT_TARGET}
      POST_BUILD
      COMMAND ${CMAKE_OBJCOPY} -O elf32-littlearm $<TARGET_FILE:${BINARY_FORMAT_TARGET}> $<TARGET_FILE:${BINARY_FORMAT_TARGET}>.elf)
    endif()
    
endfunction()

function(target_print_size)
    cmake_parse_arguments(
            BINARY_FORMAT
            ""
            "TARGET"
            ""
            ${ARGN}
        )
    add_custom_command(TARGET ${BINARY_FORMAT_TARGET}
        POST_BUILD
        COMMAND ${CMAKE_SIZE_UTIL} $<TARGET_FILE:${BINARY_FORMAT_TARGET}> )    
endfunction()
