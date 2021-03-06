#########################################################################
##          BlackTools - The Ultimate Channel Control Script           ##
##                    One TCL. One smart Eggdrop                       ##
#########################################################################
###########################   VOICEONMSG TCL   ##########################
#########################################################################
##						                       ##
##     BlackTools  : http://blacktools.tclscripts.net	               ##
##     Bugs report : http://www.tclscripts.net/	                       ##
##     Online Help : irc://irc.undernet.org/tcl-help 	               ##
##                   #TCL-HELP / UnderNet                              ##
##                   You can ask in english or romanian                ##
##					                               ##
#########################################################################

proc voiceonmsg:public:me {nick host hand chan keyword arg} {
	global black
	voiceonmsg:public $nick $host $hand $chan $arg
}

proc voiceonmsg:public {nick host hand chan arg} {
	global black
if {![validchan $chan]} {
	return
}
if {[setting:get $chan voiceonmsg]} {
if {![info exists black(voiceonmsg:list:$chan)]} {
	set black(voiceonmsg:list:$chan) ""
}
	set host "$nick"
if {[isvoice $nick $chan]} { return }
if {[isop $nick $chan]} { return }
if {![botisop $chan]} { return }
if {![info exists black(voiceonmsg:$host:$chan)]} {
if {[lsearch -exact [string tolower $black(voiceonmsg:list:$chan)]  [string tolower $host]] == -1} {
	lappend black(voiceonmsg:list:$chan) $host
}
	set black(voiceonmsg:$host:$chan) 1
	utimer 300 [list voiceonmsg:remove $host $chan]
	return
}
if {[lsearch -exact [string tolower $black(voiceonmsg:list:$chan)]  [string tolower $host]] == -1} {
	lappend black(voiceonmsg:list:$chan) $host
}
	set current_count $black(voiceonmsg:$host:$chan)
	set black(voiceonmsg:$host:$chan) [expr $current_count + 1]
	
foreach tmr [utimers] {
if {[string match "*voiceonmsg:remove:expire $host $chan*" [join [lindex $tmr 1]]]} {
	killutimer [lindex $tmr 2]
			}	
		}
	utimer 300 [list voiceonmsg:remove:expire $host $chan]
	set linenum [setting:get $chan voiceonmsg-linenum]
if {$linenum == ""} {
	set linenum $black(voiceonmsg:linenum)
}
if {$black(voiceonmsg:$host:$chan) >= $linenum} {
	utimer 2 [list pushmode $chan +v $nick]
	voiceonmsg:remove $host $chan
		}
	}
}

proc voiceonmsg:remove {host chan} {
	global black
	foreach tmr [utimers] {
if {[string match "*voiceonmsg:remove:expire $host $chan*" [join [lindex $tmr 1]]]} {
	killutimer [lindex $tmr 2]
		}
if {[string match "*voiceonmsg:remove $host $chan*" [join [lindex $tmr 1]]]} {
	killutimer [lindex $tmr 2]
		}
	}
}

proc voiceonmsg:remove:the_list {h chan} {
	global black
if {[info exists black(voiceonmsg:list:$chan)]} {
if {[lsearch -exact [string tolower $black(voiceonmsg:list:$chan)] [string tolower $h]] > -1} {
	set position [lsearch -exact [string tolower $black(voiceonmsg:list:$chan)] [string tolower $h]]
	set black(voiceonmsg:list:$chan) [lreplace $black(voiceonmsg:list:$chan) $position $position]
		}
	}
}

proc voiceonmsg:remove:expire {host chan} {
	global black
	foreach tmr [utimers] {
if {[string match "*voiceonmsg:remove:expire $host $chan*" [join [lindex $tmr 1]]]} {
	killutimer [lindex $tmr 2]
		}
	}

if {[info exists black(voiceonmsg:$host:$chan)]} {
	unset black(voiceonmsg:$host:$chan)
	}
}

proc voiceonmsg:changenick {nick host hand chan newnick} {
	global black
if {![validchan $chan]} {
	return
}
if {[setting:get $chan voiceonmsg]} {
if {[info exists black(voiceonmsg:list:$chan)] && $black(voiceonmsg:list:$chan) != ""} {
	set h $nick
if {[lsearch -exact [string tolower $black(voiceonmsg:list:$chan)] [string tolower $h]] > -1} {
	set position [lsearch -exact [string tolower $black(voiceonmsg:list:$chan)] [string tolower $h]]
	set black(voiceonmsg:list:$chan) [lreplace $black(voiceonmsg:list:$chan) $position $position]
			}
	lappend black(voiceonmsg:list:$chan) $newnick
if {[info exists black(voiceonmsg:$h:$chan)]} {
	set black(voiceonmsg:$newnick:$chan) $black(voiceonmsg:$h:$chan)
	unset black(voiceonmsg:$h:$chan)
			}
		}
	}
}

proc voiceonmsg:part {nick host hand chan arg} {
	global black
	voiceonmsg:remove:expire $nick $chan
	voiceonmsg:remove:the_list $nick $chan
}

proc voiceonmsg:split {nick host hand chan args} {
	global black
	voiceonmsg:remove:expire $nick $chan
	voiceonmsg:remove:the_list $nick $chan
}

proc voiceonmsg:kick {nick host hand chan kicked reason} {
	global black
	voiceonmsg:remove:expire $kicked $chan
	voiceonmsg:remove:the_list $kicked $chan
}

proc voiceonmsg:timer {} {
	global black
	set channels ""
foreach chan [channels] {
if {[setting:get $chan voiceonmsg]} {
	lappend channels $chan
		}
	}
if {$channels != ""} {
	voiceonmsg:act $channels 0
	timer 1 voiceonmsg:timer
	}
}

proc voiceonmsg:act {channels counter} {
	global black
	set chan [lindex $channels $counter]
	set cc [expr $counter + 1]
if {[info exists black(voiceonmsg:list:$chan)] && $black(voiceonmsg:list:$chan) != ""} {
foreach nick [chanlist $chan] {
	set h $nick
	set position [lsearch -exact [string tolower $black(voiceonmsg:list:$chan)] [string tolower $h]]
if {$position > -1} {
	set handle [nick2hand $nick $chan]
if {![matchattr $handle "-|gf" $chan]} {
	set idletime [setting:get $chan voiceonmsg-idletime]
if {$idletime == ""} {
	set idletime $black(voiceonmsg:idletime)
}
	set idletime [time_return_minute $idletime]
if {[getchanidle $nick $chan] >= $idletime} {
if {[isvoice $nick $chan]} {
	utimer 2 [list pushmode $chan -v $nick]
			}	
	voiceonmsg:remove:expire $h $chan
	voiceonmsg:remove:the_list $h $chan
		}
	}
} else {

if {![info exists black(voiceonmsg:$h:$chan)]} {
	voiceonmsg:remove:the_list $h $chan
		} else {	
	voiceonmsg:remove:expire $h $chan
	voiceonmsg:remove:the_list $h $chan
				}
			}
		}
	}
if {[lindex $channels $cc] == ""} {
	return
	} else {
	voiceonmsg:act $channels $cc
	}
}

proc remove:flood:join {chan} {
	global black
if {[info exists black(countflood:join:$chan)]} {
	unset black(countflood:join:$chan)
	}
}

##############
#########################################################################
##   END                                                               ##
#########################################################################