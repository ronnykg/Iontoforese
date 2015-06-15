transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -93 -work work {C:/Users/Admin/Documents/GitHub/Mestrado/VHDL/usb/usb_inc.vhd}
vcom -93 -work work {C:/Users/Admin/Documents/GitHub/Mestrado/VHDL/usb/isp_inc.vhd}
vcom -93 -work work {C:/Users/Admin/Documents/GitHub/Mestrado/VHDL/usb/hal.vhd}
vlib IEEE_PROPOSED
vmap IEEE_PROPOSED IEEE_PROPOSED
vcom -93 -work IEEE_PROPOSED {C:/Users/Admin/Documents/GitHub/Mestrado/VHDL/fixed_float_types_c.vhdl}
vcom -93 -work work {C:/Users/Admin/Documents/GitHub/Mestrado/VHDL/Types.vhd}
vcom -93 -work work {C:/Users/Admin/Documents/GitHub/Mestrado/VHDL/usb/devreq.vhd}
vcom -93 -work IEEE_PROPOSED {C:/Users/Admin/Documents/GitHub/Mestrado/VHDL/fixed_pkg_c.vhdl}
vcom -93 -work work {C:/Users/Admin/Documents/GitHub/Mestrado/VHDL/my_library.vhd}
vcom -93 -work work {C:/Users/Admin/Documents/GitHub/Mestrado/VHDL/usb/drv.vhd}
vcom -93 -work IEEE_PROPOSED {C:/Users/Admin/Documents/GitHub/Mestrado/VHDL/float_pkg_c.vhdl}
vcom -93 -work work {C:/Users/Admin/Documents/GitHub/Mestrado/VHDL/DE2_CLOCK.vhd}

