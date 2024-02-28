inherit autotools pkgconfig

LICENSE          = "Qualcomm-Technologies-Inc.-Proprietary"
LIC_FILES_CHKSUM = "file://${QCOM_COMMON_LICENSE_DIR}/${LICENSE};md5=58d50a3d36f27f1a1e6089308a49b403"

SUMMARY          = "SNPE-SDK"
DESCRIPTION      = "Snapdragon Neural Processing Engine SDK"

SRC_URI = "file://snpe"
S = "${WORKDIR}/snpe"

do_fetch() {
    if [ ! -f "/usr/bin/qpm-cli" ]; then
        echo "QPM is not installed on host machine, Please try after QPM installation!!"
        exit 1
    fi
    mkdir -p snpe
    if [ -d "/opt/qcom/aistack/snpe/${SNPE_VERSION}" ]; then
        cp -r /opt/qcom/aistack/snpe/${SNPE_VERSION}/* snpe/.
    else
        /usr/bin/qpm-cli --license-activate qualcomm_neural_processing_sdk
        yes y | /usr/bin/qpm-cli --extract qualcomm_neural_processing_sdk --version ${SNPE_VERSION}
        cp -r /opt/qcom/aistack/snpe/${SNPE_VERSION}/* snpe/.
    fi
}

def platform_dir(d):
    gccversion  = d.getVar("GCCVERSION", True).strip('%').split('.')[0]
    gccversion_integer = int(gccversion)
    sdk_lib_dir = d.getVar("S", True) + "/lib/"
    dir_prefix = "aarch64-oe-linux-gcc"
    for version in range (gccversion_integer, 8, -1):
        gccversion = str(version)
        pf_dir = dir_prefix + gccversion
        if os.path.exists(sdk_lib_dir) and os.path.isdir(sdk_lib_dir):
            for folder in os.listdir(sdk_lib_dir):
                if folder.startswith(pf_dir):
                    pf_dir += "*"
                    return pf_dir

PLATFORM_DIR = "${@platform_dir(d)}"

# Add Hexagon version for other targets below
HEXAGON_DIR:qcm6490 = "hexagon-v68"

do_compile[noexec] = "1"
do_package_qa[noexec] = "1"

do_install() {
    install -d ${D}/${bindir}
    install -d ${D}/${includedir}
    install -d ${D}/${libdir}/rfsa/adsp

    install -m 0755 ${S}/lib/${PLATFORM_DIR}/* ${D}/${libdir}
    install -m 0755 ${S}/bin/${PLATFORM_DIR}/* ${D}/${bindir}
    install -m 0755 ${S}/lib/${HEXAGON_DIR}/unsigned/* ${D}/${libdir}/rfsa/adsp

    cp -r ${S}/include/SNPE/* ${D}/${includedir}
    chmod -R 0755 ${D}/${includedir}
}

INHIBIT_PACKAGE_STRIP = "1"
INHIBIT_PACKAGE_DEBUG_SPLIT = "1"

INSANE_SKIP_${PN} += "arch"

SOLIBS = ".so"
FILES_SOLIBSDEV = ""

FILES:${PN} += "${libdir}/*"
FILES:${PN} += "${libdir}/rfsa/adsp"
FILES:${PN} += "${bindir}/*"
FILES:${PN}-dev += "${includedir}/*"
