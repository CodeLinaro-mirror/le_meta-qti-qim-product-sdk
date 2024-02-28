# Copyright (c) 2024 Qualcomm Innovation Center, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause-Clear

SSTATETASKS += "do_generate_qim_prod_sdk "
SSTATE_OUT_DIR = "${DEPLOY_DIR}/qim_prod_sdk_artifacts/"
SSTATE_IN_DIR = "${TOPDIR}/${SDK_PN}"
TMP_SSTATE_IN_DIR = "${TOPDIR}/${SDK_PN}_tmp"
SAMPLES_PATH ?= "NULL"
TOOLCHAIN_PATH ?= "NULL"
TOOLS_PATH ?= "NULL"
README_PATH ?= "NULL"
SETUP_PATH ?= "NULL"

# We only need the packaging tasks - disable the rest
do_configure[noexec] = "1"
do_compile[noexec] = "1"
do_populate_lic[noexec] = "1"
do_package_qa[noexec] = "1"

LICENSE = "BSD-3-Clause-Clear"
INSANE_SKIP:${PN} += "already-stripped"
ALLOW_EMPTY:${PN} = "1"

python __anonymous () {
    package_type = d.getVar("IMAGE_PKGTYPE", True)
    if package_type == "ipk":
        bb.build.addtask('do_generate_qim_prod_sdk', 'do_package_write_ipk', 'do_packagedata', d)
        d.appendVarFlag('do_package_write_ipk', 'prefuncs', ' do_reorganize_pkg_dir')
    elif package_type == "deb":
        bb.build.addtask('do_generate_qim_prod_sdk', 'do_package_write_deb', 'do_packagedata', d)
        d.appendVarFlag('do_package_write_deb', 'prefuncs', ' do_reorganize_pkg_dir')
}

addtask do_generate_qim_prod_sdk_setscene
do_generate_qim_prod_sdk[postfuncs] += "organize_qim_prod_sdk_files"
do_generate_qim_prod_sdk[sstate-inputdirs] = "${SSTATE_IN_DIR}"
do_generate_qim_prod_sdk[sstate-outputdirs] = "${SSTATE_OUT_DIR}"
do_generate_qim_prod_sdk[dirs] = "${SSTATE_IN_DIR} ${SSTATE_OUT_DIR} ${TMP_SSTATE_IN_DIR}"
do_generate_qim_prod_sdk[cleandirs] = "${SSTATE_IN_DIR} ${SSTATE_OUT_DIR} ${TMP_SSTATE_IN_DIR}"
do_generate_qim_prod_sdk[stamp-extra-info] = "${MACHINE_ARCH}"
do_generate_qim_prod_sdk[depends] = " \
         snpe:do_packagedata \
         qnn:do_packagedata \
         packagegroup-qcom-qim-product:do_packagedata \
         qim-sdk:do_generate_qim_sdk \
         tflite-sdk:do_generate_tflite_sdk \
   "

# Add a task to generate qim product sdk
do_generate_qim_prod_sdk () {
    # generate QIM PRODUCT SDK package
    if [ ! -d ${TMP_SSTATE_IN_DIR}/${SDK_PN} ]; then
        mkdir -p ${TMP_SSTATE_IN_DIR}/${SDK_PN}/
    fi
    cp -r ${WORKDIR}/*install.sh ${TMP_SSTATE_IN_DIR}/${SDK_PN}/
    PKG_LISTS="${@get_pkgs_list(d)}"
    for pkg in ${PKG_LISTS}
    do
        cp ${pkg} ${TMP_SSTATE_IN_DIR}/${SDK_PN}/
    done
    cd ${TMP_SSTATE_IN_DIR}
    tar -cf ${SSTATE_IN_DIR}/${SDK_PN}.tar ./${SDK_PN}/*
    cp ${DEPLOY_DIR}/qimsdk_artifacts/qim-sdk*.tar.gz .
    cp ${DEPLOY_DIR}/tflitesdk_artifacts/tflite-sdk*.tar.gz .
    tar -rf ${SSTATE_IN_DIR}/${SDK_PN}.tar ./qim-sdk*.tar.gz ./tflite-sdk*.tar.gz
}

# Add a task to copy sample code/toolchain/setup scripts,
# and orgnanize as final sdk artifact
organize_qim_prod_sdk_files () {
    # orgnanize runtime packages
    if ls ${SSTATE_IN_DIR}/${SDK_PN}* >/dev/null 2>&1; then
        install -d ${SSTATE_IN_DIR}/${SDK_PN}/runtime
        mv ${SSTATE_IN_DIR}/${SDK_PN}*.tar ${SSTATE_IN_DIR}/${SDK_PN}/runtime/
    else
        bbfatal "No ${SDK_PN} packages generated, will miss base function! Please check it!"
    fi

    # orgnanize README docs
    if ls ${README_PATH} >/dev/null 2>&1; then
        cp -r ${README_PATH} ${SSTATE_IN_DIR}/${SDK_PN}/
    else
        bbwarn "No README docs find in ${README_PATH}, Please Note it!"
    fi

    # organize all files as final sdk
    cd ${SSTATE_IN_DIR}
    tar -cf ${SSTATE_IN_DIR}/${SDK_PN}_${PV}.tar ./${SDK_PN}/*
    cp ${DEPLOY_DIR}/qimsdk_artifacts/qim-sdk*.tar.gz .
    cp ${DEPLOY_DIR}/tflitesdk_artifacts/tflite-sdk*.tar.gz .
    tar -rf ${SSTATE_IN_DIR}/${SDK_PN}_${PV}.tar ./qim-sdk*.tar.gz ./tflite-sdk*.tar.gz
    rm -r ${TMP_SSTATE_IN_DIR}
}

def get_pkgs_list(d):
  import os
  pkgtype = d.getVar("IMAGE_PKGTYPE", True)
  deploydir = d.getVar("DEPLOY_DIR", True)
  pkgslist = []
  for _, pkgdirs, _ in os.walk(os.path.join(deploydir, pkgtype)):
    for pkgdir in pkgdirs:
      for f in os.listdir(os.path.join(deploydir, pkgtype, pkgdir)):
        if "qnn" in os.path.basename(f) or "snpe" in os.path.basename(f):
          #bb.warn(os.path.basename(f))
          pkgslist.append(os.path.join(deploydir, pkgtype, pkgdir, f))
  return " \\\n ".join(pkgslist)

python do_generate_qim_sdk_setscene() {
    sstate_setscene(d)
}

do_cleanall[depends] = "qim-sdk:do_cleanall tflite-sdk:do_cleanall"
