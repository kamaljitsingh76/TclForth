\ File:    console.fth
\ Project: TclForth
\ Version: 0.55
\ License: Tcl
\ Author:  Wolf Wejgaard
\

: ConsoleWindows  { -- }
	"TclForth Version 0.55" Title
	".forth" "text" Widget Console
	"-padx 10 -pady 10 -relief sunken -border 1 -highlightcolor white" Console config   
	"-expand 1 -fill both" Console pack
	".code" "text" Widget CodeWindow
	"-height 6 -pady 10 -padx 10 -relief sunken -border 1 -highlightcolor white" CodeWindow config  
\	"-expand 0 -fill both" CodeWindow pack
;

\ ===================================================================================
\ Print to Forth console
\ ===================================================================================

proc print-fth {text} {
	$::Console insert end $text
}

proc printnl-fth {text} {
	$::Console insert end "$text\n"
}

Code printforth { -- }  
	if {[info procs print-fth]==""} {return}
	rename print print-tcl
	rename print-fth print
	rename printnl printnl-tcl
	rename printnl-fth printnl

\ ===================================================================================
\ Menus
\ ===================================================================================

Code ImportTcl {} 
	set file [tk_getOpenFile -filetypes {{"" {".tcl"}}} -initialdir ./]
	if {$file==""} {return}
	source $file

Code ImportForth {} 
	set file [tk_getOpenFile -filetypes {{"" {".fth"}}} -initialdir ./]
	if {$file==""} {return}
	LoadForth $file

: FileMenu { -- } 
	".menubar.file" Menu fMenu
	"File" fMenu Menubar addmenu
	"Load .tcl" "ImportTcl" fMenu addcommand
	"Load .fth" "ImportForth" fMenu addcommand
;

: SetupMenu {}
	".menubar.setup" Menu sMenu
	"Setup" sMenu Menubar addmenu
	"Clear Console" {ClearConsole; okprompt}	sMenu addcommand
	"Show Codewindow" {pack $CodeWindow -expand 0 -fill both} sMenu addcommand
	"Hide Codewindow" {pack forget $CodeWindow} sMenu addcommand
	"Open Tcl console" {catch "console show"} sMenu addcommand

Code GetWords { -- fwords } 
	set fwords [array names ::words]

: ShowWords  { | words -- }
	cast words list
	GetWords	words setlist  
 	words sort words join
	cr words print 
;

Tcl bind . <Control-w> {ShowWords; okprompt}

Code openURL { webadr -- } 
     if {$::tcl_platform(os)=="Darwin"} {
          eval exec open $webadr &
     } {
          eval exec [auto_execok start] $webadr &
     }

: HelpMenu {} 
	".menubar.help" Menu helpMenu
	"Help" helpMenu Menubar addmenu
	"Words" {ShowWords; okprompt} helpMenu addcommand
	"TclForth" {push "http://code.google.com/p/tclforth/wiki/Introduction"; openURL} helpMenu addcommand
	"Tcl" {push "http://www.tcl.tk/man/tcl/contents.htm"; openURL} helpMenu addcommand

: ConsoleMenu {}  
	FileMenu 
	SetupMenu
	HelpMenu

\ ===================================================================================
\ Command history
\ ===================================================================================

{} list comhistory

0 variable comindex

1.0 variable comstart

: SaveComline { comline -- } 
	comline "" != 
	if	comline comhistory append  	
		comhistory length comindex set 	
	then
;

: ShowComline { comline -- }
	comstart Console end  Console delete
	comline Console append
	1.0 Console yview
;

: PrevComline { -- }  
	comindex 0> if -1 comindex add then 
	comindex comhistory	ShowComline
;

: NextComline { -- }
	comindex incr
	comindex comhistory  length >= 
	if   comhistory length  comindex set   ""
	else comindex comhistory 
	then	ShowComline
;

\ ===================================================================================
\ Command line interpreter
\ ===================================================================================

1 variable withStack

: ShowStack { -- } 
	1 withStack set
;

: HideStack { -- }
	0 withStack set
;

: okprompt { -- }
	depth 0> withStack and
	if   "($::stack) ok> " 
	else "ok> " 
	then Console append update 
	Console insert comstart set
	1.0 Console yview
;

\ ===================================================================================
\ Forth Console
\ ===================================================================================

Code GetLine { -- }  
	global comp locals doi doj dok comstart 
	array unset locals 	
	set doi 0; set doj -1; set dok -2 
	set comp(text) {}; 	set comp(code) {}; set comp(objtype) {}
	set line [$::Console get "$comstart -1 chars" "insert lineend"]; 
	set line [string trim $line]
	set comp(text) $line;	set comp(i) 0; set comp(end) [string length $line]
	push $line; SaveComline
	$::Console insert end "\n"
	return $comp(end)

Code ShowCompCode { -- }
	global comp
	catch {
		$::CodeWindow delete 1.0 end
		$::CodeWindow insert 1.0 $comp(code)
	}

Code LoadLine { -- } 
	InterpretText
	ShowCompCode

Code EvalLine { -- }
	global comp
	$::CodeWindow delete 1.0 end
	if {[GetLine]} {
		if [catch LoadLine err]  {printnl "? $err"; ShowCompCode}
	}
	okprompt

: ClearConsole { -- }
	!s
	"1.0" Console end Console delete ;

Tcl bind . <Control-c> {ClearConsole; okprompt}

: ClearStack { -- }
	!s cr okprompt ;
	
Tcl bind . <Control-s> ClearStack

Code HideTclConsole { -- }
	catch {console hide}

: ForthConsole { -- }
	HideTclConsole
	ConsoleWindows
	"<Return> {EvalLine; break}" Console bind   
	"<Shift-Return> {cr; break}" Console bind       
	"<Up> {PrevComline; break}"  Console bind
	"<Down> {NextComline; break}" Console bind
	ConsoleMenu
	printforth
	"Ctrl-W = ShowWords
	Ctrl-S = ClearStack
	Ctrl-C = ClearConsole\n" .cr	
	okprompt
	Console wait
;

