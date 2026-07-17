-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Adwaita")

hl.env("HYPRCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Adwaita")

-- Nvidia related
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
hl.env("__GL_VRR_ALLOWED", "0")

