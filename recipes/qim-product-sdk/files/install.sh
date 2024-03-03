#!/bin/bash

# Copyright (c) 2024 Qualcomm Innovation Center, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause-Clear

SDK_NAME="QIM_PRODUCT_SDK"

FOUND_PKGS=""
QIM_PKG_DIR="/opt/qcom/qimsdk/"
PKG_LIST_FILE="/opt/qcom/qimsdk/$SDK_NAME.list"


# check permission for execute this script
function check_permission() {
    if [ "$(whoami)" != "root" ]; then
        echo "ERROR: need root permission"
        exit 1
    fi
}

# scan packages in current path
function scan_qim_prod_packages() {
    FOUND_PKGS=`find . -name "*.ipk" \
        | grep -v "\-dbg_" \
        | grep -v "\-dev_" \
        | grep -v "\-staticdev_" \
        | tr '\n' ' '`
}

function qim_sdk_env_file() {
    echo "export PATH=${QIM_PKG_DIR}/usr/bin:\$PATH" > ${QIM_PKG_DIR}/qim-sdk.sh
    echo "export LD_LIBRARY_PATH=${QIM_PKG_DIR}/usr/lib:\$LD_LIBRARY_PATH" >> ${QIM_PKG_DIR}/qim-sdk.sh
    echo "export GST_PLUGIN_PATH=${QIM_PKG_DIR}/usr/lib/gstreamer-1.0:\$GST_PLUGIN_PATH" >> ${QIM_PKG_DIR}/qim-sdk.sh
    echo "export LD_LIBRARY_PATH=${QIM_PKG_DIR}/lib:\$LD_LIBRARY_PATH" >> ${QIM_PKG_DIR}/qim-sdk.sh
    echo "export GST_PLUGIN_SCANNER=${QIM_PKG_DIR}/usr/libexec/gstreamer-1.0/gst-plugin-scanner" >> ${QIM_PKG_DIR}/qim-sdk.sh

    chmod +x ${QIM_PKG_DIR}/qim-sdk.sh
}

# install packages and save list to file
function install_qim_prod_packages() {

    install_command="opkg install --force-reinstall --force-depends --force-overwrite -o ${QIM_PKG_DIR}"

    for PKG_FILE in $FOUND_PKGS; do
        $install_command $PKG_FILE
    done

    if [ -f "$PKG_LIST_FILE" ]; then
        rm -f "$PKG_LIST_FILE"
    fi

    for pkg in $FOUND_PKGS; do
        pkg_name=`echo $pkg | awk -F'/' '{print $NF}' | awk -F'_' '{print $1}'`
        echo $pkg_name >> $PKG_LIST_FILE
    done
}

function main() {

    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    echo ">>> Install scripts for $SDK_NAME"
    echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
    echo

    check_permission

    if [ -f $PKG_LIST_FILE ]; then
        printf "WARN: $SDK_NAME has installed, "
        while true; do
            read -p "Do you wish to install anyway? (Y/N)" yn
            case $yn in
                [Yy]* ) break;;
                [Nn]* ) exit 1;;
                * ) echo "Please answer yes or no.";;
            esac
        done
    fi

    scan_qim_prod_packages

    if [ ! -d "/opt/qcom/qimsdk/" ]; then
        mkdir -p /opt/qcom/qimsdk
    fi

    if [ ! -d "$QIM_PKG_DIR" ]; then
        mkdir -p "$QIM_PKG_DIR"
    fi

    install_qim_prod_packages
    qim_sdk_env_file

    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    echo ">>> Installation done for $SDK_NAME at $QIM_PKG_DIR"
    echo ">>> source $QIM_PKG_DIR/qim-sdk.sh before running usecases"
    echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
    echo
}

main "$@"
