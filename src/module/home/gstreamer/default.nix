{ pkgs, ... }:

{
  home.packages = with pkgs.gst_all_1; [
    gstreamer
    gst-vaapi
    gst-libav
    gst-plugins-base
    gst-plugins-good
    gst-plugins-ugly
  ];
}
