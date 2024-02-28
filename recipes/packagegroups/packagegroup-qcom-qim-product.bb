SUMMARY = "Qualcomm QIM Product SDK package groups"
LICENSE = "BSD-3-Clause-Clear"
LIC_FILES_CHKSUM = "file://${QCOM_COMMON_LICENSE_DIR}${LICENSE};md5=3771d4920bd6cdb8cbdf1e8344489ee0"

PROVIDES = "${PACKAGES}"
PACKAGE_ARCH = "${MACHINE_ARCH}"

inherit packagegroup

SRC_URI += "file://install.sh"
SRC_URI += "file://uninstall.sh"

PACKAGES = " \
      packagegroup-qcom-qim-product \
    "

RDEPENDS:packagegroup-qcom-qim-product = " \
    packagegroup-qcom-gst \
    packagegroup-qcom-ml \
  "
