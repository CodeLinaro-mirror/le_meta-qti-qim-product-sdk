RDEPENDS:packagegroup-qcom-gst:append = "  \
        gstreamer1.0-plugins-qcom-oss-mlsnpe \
        gstreamer1.0-plugins-qcom-oss-mlqnn \
        gstreamer1.0-plugins-qcom-oss-mltflite \
  "

RDEPENDS:packagegroup-qcom-gst:remove:qcs9100 = "  \
        gstreamer1.0-plugins-qcom-oss-mlsnpe \
        gstreamer1.0-plugins-qcom-oss-mlqnn \
  "
