transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -93 -work work {C:/Users/Admin/Documents/Mestrado-github/Iontoforese/VHDL/usb/usb_inc.vhd}
vcom -93 -work work {C:/Users/Admin/Documents/Mestrado-github/Iontoforese/VHDL/usb/isp_inc.vhd}
vcom -93 -work work {C:/Users/Admin/Documents/Mestrado-github/Iontoforese/VHDL/usb/hal.vhd}
vlib IEEE_PROPOSED
vmap IEEE_PROPOSED IEEE_PROPOSED
vcom -93 -work IEEE_PROPOSED {C:/Users/Admin/Documents/Mestrado-github/Iontoforese/VHDL/fixed_float_types_c.vhdl}
vcom -93 -work work {C:/Users/Admin/Documents/Mestrado-github/Iontoforese/VHDL/Types.vhd}
vcom -93 -work work {C:/Users/Admin/Documents/Mestrado-github/Iontoforese/VHDL/usb/devreq.vhd}
vcom -93 -work IEEE_PROPOSED {C:/Users/Admin/Documents/Mestrado-github/Iontoforese/VHDL/fixed_pkg_c.vhdl}
vcom -93 -work work {C:/Users/Admin/Documents/Mestrado-github/Iontoforese/VHDL/my_library.vhd}
vcom -93 -work work {C:/Users/Admin/Documents/Mestrado-github/Iontoforese/VHDL/usb/drv.vhd}
vcom -93 -work IEEE_PROPOSED {C:/Users/Admin/Documents/Mestrado-github/Iontoforese/VHDL/float_pkg_c.vhdl}
vcom -93 -work work {C:/Users/Admin/Documents/Mestrado-github/Iontoforese/VHDL/DE2_CLOCK.vhd}

