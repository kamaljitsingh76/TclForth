# File:    tfmain.tcl
# Project: TclForth
# Version: 0.55
# License: Tcl
# Author:  Wolf Wejgaard  
#

package require Tk
catch {console show}

source compiler.tcl

LoadForth forth.fth

LoadForth tk.fth

LoadForth console.fth

ForthConsole

