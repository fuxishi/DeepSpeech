#!/bin/bash

set -xe

export OS=$(uname)
if [ "${OS}" = "Linux" ]; then
    export DS_ROOT_TASK=${HOME}
    export SWIG_ROOT="${HOME}/ds-swig"
    export DS_CPU_COUNT=$(nproc)
fi;

if [ "${OS}" = "${TC_MSYS_VERSION}" ]; then
    export DS_ROOT_TASK=${TASKCLUSTER_TASK_DIR}
    export SWIG_ROOT="$(cygpath ${USERPROFILE})/ds-swig"
    export PLATFORM_EXE_SUFFIX=.exe
    export DS_CPU_COUNT=$(nproc)
fi;

if [ "${OS}" = "Darwin" ]; then
    export SWIG_ROOT="${TASKCLUSTER_ORIG_TASKDIR}/ds-swig"
    export DS_ROOT_TASK=${TASKCLUSTER_TASK_DIR}
    export DS_CPU_COUNT=$(sysctl hw.ncpu |cut -d' ' -f2)

    # It seems chaining |export DYLD_LIBRARY_PATH=...| does not work, maybe
    # because of SIP? Who knows ...
    if [ ! -z "${EXTRA_ENV}" ]; then
        eval "export ${EXTRA_ENV}"
    fi;
fi;

SWIG_BIN=swig${PLATFORM_EXE_SUFFIX}
DS_SWIG_BIN=ds-swig${PLATFORM_EXE_SUFFIX}
if [ -f "${SWIG_ROOT}/bin/${DS_SWIG_BIN}" ]; then
    export PATH=${SWIG_ROOT}/bin/:$PATH
    export SWIG_LIB="$(find ${SWIG_ROOT}/share/swig/ -type f -name "swig.swg" | xargs dirname)"
    # Make an alias to be more magic
    if [ ! -L "${SWIG_ROOT}/bin/${SWIG_BIN}" ]; then
        ln -s ${DS_SWIG_BIN} ${SWIG_ROOT}/bin/${SWIG_BIN}
    fi;
    swig -version
    swig -swiglib
fi;

export TASKCLUSTER_ARTIFACTS=${TASKCLUSTER_ARTIFACTS:-/tmp/artifacts}
export TASKCLUSTER_TMP_DIR=${TASKCLUSTER_TMP_DIR:-/tmp}

export ANDROID_TMP_DIR=/data/local/tmp

mkdir -p ${TASKCLUSTER_TMP_DIR} || true

export DS_TFDIR=${DS_ROOT_TASK}/DeepSpeech/tf
export DS_DSDIR=${DS_ROOT_TASK}/DeepSpeech/ds
export DS_EXAMPLEDIR=${DS_ROOT_TASK}/DeepSpeech/examples

export DS_VERSION="$(cat ${DS_DSDIR}/VERSION)"

export ANDROID_SDK_HOME=${DS_ROOT_TASK}/DeepSpeech/Android/SDK/
export ANDROID_NDK_HOME=${DS_ROOT_TASK}/DeepSpeech/Android/android-ndk-r18b/

WGET=${WGET:-"wget"}
TAR=${TAR:-"tar"}
XZ=${XZ:-"pixz -9"}
UNXZ=${UNXZ:-"pixz -d"}

if [ "${OS}" = "${TC_MSYS_VERSION}" ]; then
  WGET=/usr/bin/wget.exe
  TAR=/usr/bin/tar.exe
  XZ="xz -9 -T0 -c -"
  UNXZ="xz -9 -T0 -d"
fi

model_source="${DEEPSPEECH_TEST_MODEL}"
model_name="$(basename "${model_source}")"
model_name_mmap="$(basename -s ".pb" "${model_source}").pbmm"
model_source_mmap="$(dirname "${model_source}")/${model_name_mmap}"

ldc93s1_sample_filename=''

SUPPORTED_PYTHON_VERSIONS=${SUPPORTED_PYTHON_VERSIONS:-3.5.8:ucs4 3.6.10:ucs4 3.7.6:ucs4 3.8.1:ucs4}

# When updating NodeJS / ElectronJS supported versions, do not forget to increment
# deepspeech.node-gyp-cache.<X> in both `system.node_gyp_cache` (taskcluster/.shared.yml)
# and route index (taskcluster/node-gyp-cache.yml) to ensure the cache is updated
SUPPORTED_NODEJS_VERSIONS=${SUPPORTED_NODEJS_VERSIONS:-10.18.1 11.15.0 12.8.1 13.1.0}
SUPPORTED_ELECTRONJS_VERSIONS=${SUPPORTED_ELECTRONJS_VERSIONS:-5.0.13 6.0.12 6.1.7 7.0.1 7.1.8}
