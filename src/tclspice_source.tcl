
namespace eval spicewish {
    
    #added name space to all external calls 
    # packagecmd,  -command,   bind, after, -postcommand
    
    set ::spicewishversion "0.1"
    
    #set ::plot_background \#004040
    set ::plot_background white
    
    
    #------------------------------------------------
    # nutmeg extensions  (eqivalent functions to nutmeg)
    # (requires  readline, 
    
    package require Tclx
    
    #toplevel counters
    set ::toplevel_count 1
    
    #Colour schemes.
    # - Colours allocated on a rotating colour sheme   ::trace_index_counter  counts the traces issued
    # -OR- if a particular hash exists for a trace, this is used
    
    set ::linecolour(default) "grey"
    set ::linecolour(0) "red"
    set ::linecolour(1) "blue"
    set ::linecolour(2) "orange"
    set ::linecolour(3) "green"
    set ::linecolour(4) "magenta"
    set ::linecolour(5) "brown"
    
    
    
    #-alternate line dashes
    set ::dashlist(default) "" ;#- solid by default
    set ::dashlist(0) "2 2"; #- fine dots
    set ::dashlist(1) "5 5"; #- large dahes
    set ::dashlist(2) "10 2"; #- large dahes, small gap
    set ::dashlist(3) "2 10"; #- 
    set ::dashlist(4) "3 1 2"; #- 
    set ::dashlist(5) "20 5"; #- 
    

    #---------------------------------------------------------------------------------------------------------------------------------------
    # 10/3/03 -ad
    # test if a passed spice vector exists
    #
    proc spicevector_exists { vector  } { 
	
	# run first step to get data
	if { $::spice::steps_completed < 1 } { spice::step 1 }
	
	# get list of vectors 
	set list [spice::spice_data]

	# loop foreach vector
	foreach node $list { 
	    set node [ lindex $node 0 ]
	    set nodeU [ string toupper $node ]     ;#- uppercase
	    set vectorU [ string toupper $vector ] ;#- uppercase 

	    if { [ string match $nodeU $vectorU ] } { return 1 } 
	}
	return 0 
    }

    #---------------------------------------------------------------------------------------------------------------------------------------
    # 10/3/03 -ad
    # add additional externally created vectors to spicewish
    #  - creates two vectors 'ext_$name' and 'ext_$name_time'
    #
    proc add_external_vector { name vectorX vectorY } {
	
	# creates a unique vecrtors using passed name
	set name [ string tolower $name ]
	set vectorName "ext_$name"

	# check that vectorName doesn't already exists in spice, or precreated
	if { [ spicevector_exists $name ] } { 
	    puts "vector '$name' already exists in spice"
	    return 
	}

	# check that not already created as an external vector
	set vectorList [ blt::vector names ]
	foreach vector $vectorList  {
	    set vectorU [ string toupper $vector ] ;#- uppercase
	    set nameU [ string toupper "::spicewish::$vectorName" ] ;#- uppercase
	    if { [ string match $vectorU $nameU ] } { 
		puts "vector '$name' already added as an external vector"
		return
	    }
	}

	# create blt vector
	blt::vector create $vectorName
	blt::vector create $vectorName\_time
	$vectorName set $vectorX
	$vectorName\_time set $vectorY

	# update hiertable
	#spicewish::add_external_vector hi "1 2" " 1 3"
    } 

    #--------------------------------------------------------------------------------------------------------------------------------------
    # 18/3/3 -ad
    # add an external vector from a data file
    #
    proc externalVector_add_fromFile { vecName fileName { startLine 0 }  } {
	
	# creates a unique vecrtors using passed name
	set vecName [ string tolower $vecName ]
	set vectorName "ext_$vecName"

	# test that file exists 
	if { ! [ file exists $fileName ] } { 
	    puts "can't read file '$fileName' "
	    return 
	}
	
	# test that vecName is not a duplicate of a spice vecName
	if { [ spicevector_exists $vecName ] } { 
	    puts "vector '$vecName' already exists in spice"
	    return 
	}

	# test that vecName is not already a external vector
	set vectorList [ blt::vector names ]
	foreach vector $vectorList  {
	    set vectorL [ string tolower $vector ] ;#- lowercase
	    set nameL [ string tolower "::spicewish::$vectorName" ] ;#- lowercase
	    if { [ string match $vectorL $nameL ] } { 
		puts "vector '$vecName' already added as an external vector"
		return
	    }
	}

	# -- read file 
	set xdata ""
	set ydata ""
	set fileId [open $fileName r]
	
	set lineCnt 0
	while { ! [ eof $fileId ] } {
	    gets $fileId linestring
	    foreach { dTime dPeriod } $linestring { }
	    if { $lineCnt > $startLine  } {
		lappend xdata $dTime
		lappend ydata $dPeriod
	    }
	    incr lineCnt
	}

	# -- save to external vector
	blt::vector create $vectorName
	blt::vector create $vectorName\_time
	$vectorName set $ydata
	$vectorName\_time set $xdata
    } 


    #---------------------------------------------------------------------------------------------------------------------------------------
    proc run { } {spice::bg run}
    
    proc halt { } {spice::halt }

    #----------------------------------------------------------------------------------------------------------------------------------------
    # 10/3/3 -ad
    # returns list of spice nodes
    #
    proc listnodes { } { 
	#puts listnodes
	set list ""
	if { $::spice::steps_completed <  1 } { spice::step  1 }

	foreach node [ spice::spice_data ] { 
	    set node [ lindex $node 0 ] 
	    set node [ string tolower $node ] 
	    lappend list $node 
	}
	return $list 
    }


    


    #----------------------------------------------------------------------------------------------------------------------------------------
    #  10/3/3 -ad 
    #  generate a new viewier
    proc create_viewier { } {
	
	global disp_zoom_level disp_dx 
	
	#make a new toplevel
	set tl [toplevel ".tclspice$::toplevel_count"]
	wm title $tl "tclspice plot #$::toplevel_count"
	set .tclspice$::toplevel_count.dx  0
	set disp_dx 0
	set gr_n ".tclspice$::toplevel_count"
	
	# create drop down menu
	pack [ frame .tclspice$::toplevel_count.f ] -side top -fill both 
	
	# create trace and place slot info bar - bottom
	pack [ frame .tclspice$::toplevel_count.tracePlaceInfoBar  -background grey ] -side bottom -fill x 
	
	# create frame for graph & trace and place
	pack [ frame $tl.scope  ] -side bottom  -expand 1 -fill both
	frame $tl.scope.tp -background grey 

	# create blt graph
	set ::graph_to_use [blt::graph $tl.scope.g -width 1000 -height 200]  ;#- .g

	# evals required due to '$tl' variable used in widget path
	eval "$tl.scope.g axis configure x -scrollcommand { $tl.scope.x set } "
	eval "$tl.scope.g axis configure y -scrollcommand { $tl.scope.y set } "
	eval "scrollbar $tl.scope.x  -orient horizontal -command { $tl.scope.g axis view x } -width 9"
	eval "scrollbar $tl.scope.y  -command { $tl.scope.g axis view y } -width 9"

	$tl.scope.g grid configure -hide no \
	    -dashes { 4 4 }     ;#- Add a grid
 
	$tl.scope.g crosshairs on   ;# -crosshairs

	$tl.scope.g axis configure x \
	    -command spicewish::graph_Y_axis_callback \
	    -subdivisions 2

	$tl.scope.g legend configure -activerelief raised ;# graph legend config 

	# zoom controls
	#ZoomStack $::graph_to_use Shift-Button-1 Shift-Button-3
	ZoomStack $::graph_to_use Button-1 Button-3

	blt::table $tl.scope \
	    0,0 $tl.scope.tp -fill both \
	    0,1 $tl.scope.g -fill both \
	    1,1 $tl.scope.x -fill x \
	    0,2 $tl.scope.y -fill y 

	blt::table configure $tl.scope   c2  r1 c0  -resize none  
	
	
	# graph legend active on button 3
#	$::graph_to_use legend bind all <Button-1> { %W legend activate [%W legend get current] }
#	$::graph_to_use legend bind all <ButtonRelease-1> {  %W legend deactivate [%W legend get current]}
	$::graph_to_use legend bind all <Shift-Button-1> { %W legend activate [%W legend get current] }
	$::graph_to_use legend bind all <Shift-ButtonRelease-1> {  %W legend deactivate [%W legend get current]}

	
	# creates the drag and drop packet for each of the plots in the legend
	blt::drag&drop source  $::graph_to_use -packagecmd {spicewish::make_package %t %W } -button 1
	set token [blt::drag&drop token  $::graph_to_use -activebackground blue ]
	pack [ label $token.label -text "" ]
	
	# highlights the nearest traces to the cursors legend
	$::graph_to_use element bind all <Enter> { 
	    %W legend activate [%W element get current] 
	    spicewish::TracePlace_set_scale_y2 %W [%W element get current] 
	}
	$::graph_to_use element bind all <Leave> { %W legend deactivate [%W element get current] }
	
	#make a bindng for mouse motion etc
	bind $::graph_to_use <ButtonPress-3> { spicewish::tclspice_button_handler 3 %W %x %y }
	bind $::graph_to_use <Motion> { spicewish::tclspice_motion_handler %W %x %y }
		
	# button 2 pop up menu
	bind $::graph_to_use <ButtonPress-2> { 
	    spicewish::tclspice_button_handler 2 %W %x %y 
	}
	
	#
	$::graph_to_use legend bind all <Button-2> { %W legend activate [%W legend get current] }
	$::graph_to_use legend bind all <ButtonRelease-2> {  %W legend deactivate [%W legend get current]}
	
	set ::trace_place_selected($tl.scope.g) 0 
	
	# -- menu [ options ]
	pack [ menubutton .tclspice$::toplevel_count.f.options -text "options" -menu .tclspice$::toplevel_count.f.options.m  ] -side left
	set options_menu [menu .tclspice$::toplevel_count.f.options.m -tearoff 0]
	$options_menu add command -label "rename graph" -command "spicewish::entry_selection_box .tclspice$::toplevel_count  graph" 
	$options_menu add command -label "clear graph"  -command "spicewish::spice_gr_cleargraph $tl.scope.g"
	$options_menu add command -label "save to postscript" -command "spicewish::entry_selection_box .tclspice$::toplevel_count  save_to_postscript" 
	$options_menu add checkbutton -label "Trace Place"  -onvalue 1 -offvalue 0  -variable ::trace_place_selected($tl.scope.g) -command "spicewish::TracePlace $tl" 
	$options_menu add command -label "close" -command { exit }
	
	# -- menu [ traces ]
	pack [ menubutton .tclspice$::toplevel_count.f.traces -text "traces" -menu .tclspice$::toplevel_count.f.traces.m ] -side left
	set traces_menu [menu .tclspice$::toplevel_count.f.traces.m -tearoff 0 ]
	$traces_menu add command -label "Add/remove  traces" -command "spicewish::trace_selection_box  update  $tl.scope.g" 
	$traces_menu add cascade -label "Remove trace" -menu $traces_menu.remove_plot
	$traces_menu add command -label "Update traces" -command "spicewish::spice_update_traces $tl.scope.g"
	menu $traces_menu.remove_plot -tearoff 0 -postcommand "spicewish::create_remove_plot_menu $tl $traces_menu"
	
	
	#-------------------------------------------------------------------------------------------------------------
	proc create_remove_plot_menu {tl traces_menu } { 
	    $traces_menu.remove_plot delete 0 last   ;# - clear the old list
	    # add the current traces
	    
	    # repalce the traces in alphabetical order
	    set trace_list [ lsort -dictionary    [$tl.scope.g element names]   ]
	    
	    foreach trace $trace_list  {
		$traces_menu.remove_plot add command -label $trace -command "$tl.scope.g element delete $trace"
	    }
	}
	#--------------------------------------------------------------------------------------------------------------
	
	
	set ::graph_dx($tl) 0.00000000000000
	set ::graph_dy($tl) 0.00000000000000
	set ::graph_x1($tl) 0.00000000000000
	set ::graph_y1($tl) 0.00000000000000
	set ::graph_x2($tl) 0.00000000000000
	set ::graph_y2($tl) 0.00000000000000
	
	# measurements 
	pack [ label $tl.f.dyv -textvariable  graph_dy($tl)  -background "lightgrey" -width 16 ] -side right
	pack [ label $tl.f.dy -text "dy :" -background "lightgrey" ] -side right
	bind  $tl.f.dyv <ButtonPress-1> {  regexp  {(.[0-9A-z]+)} %W temp; puts "dy :  $::graph_dy($temp)"}
	
	pack [ label $tl.f.dxv -textvariable  graph_dx($tl)  -background "grey" -width 16 ] -side right
	pack [ label $tl.f.dx -text "dx : " -background "grey" ] -side right
	bind  $tl.f.dxv <ButtonPress-1> {  regexp  {(.[0-9A-z]+)} %W temp; puts "dx :  $::graph_dx($temp)"}
	
	pack [ label $tl.f.y2v -textvariable  graph_y2($tl)  -background "lightgrey" -width 16  ] -side right
	pack [ label $tl.f.y2 -text "y2 :"  -background "lightgrey"] -side right
	bind  $tl.f.y2v <ButtonPress-1> {  regexp  {(.[0-9A-z]+)} %W temp; puts "y2 :  $::graph_y2($temp)"}
	
	pack [ label $tl.f.y1v -textvariable  graph_y1($tl)  -background "grey"  -width 16] -side right
	pack [ label $tl.f.y1 -text "y1 :" -background "grey"  ] -side right
	bind  $tl.f.y1v <ButtonPress-1> {  regexp  {(.[0-9A-z]+)} %W temp; puts "y1 :  $::graph_y1($temp)"}
	
	pack [ label $tl.f.x2v -textvariable  graph_x2($tl)  -background "lightgrey"  -width 16 ] -side right
	pack [ label $tl.f.x2 -text "x2 :" -background "lightgrey"  ] -side right
	bind  $tl.f.x2v <ButtonPress-1> {  regexp  {(.[0-9A-z]+)} %W temp; puts "x2 :  $::graph_x2($temp)"}
	
	pack [ label $tl.f.x1v -textvariable  graph_x1($tl) -background "grey" -width 16  ] -side right
	pack [ label $tl.f.x1 -text "x1 :" -background "grey"  ] -side right
	bind  $tl.f.x1v <ButtonPress-1> {  regexp  {(.[0-9A-z]+)} %W temp; puts "x1 :  $::graph_x1($temp)"}
	
    }



    #---------------------------------------------------------------------------------------------------------------------------------------
    # plot command,  replacement of nutmeg's plot command, mapped onto 
    #                the new code 
    proc plot { args } {
	

	create_viewier  ;# - see proc above
	
	# clear out old stuff
	spice_gr_cleargraph $::graph_to_use ;#- zap the old text and re-initialise the 
	
	add_traces $::graph_to_use  $args
	
	#save the plot line in a variable so it can be run again - e.g. when gui restarted
	set "::${::graph_to_use}_plotlist" [subst $args] ;#- expand as argument
	## no good becasue traces can be added and removed
	# XXXXXXXXXx
	
	# used to speed up y2axis, not recalcing the same slot twice
	set ::trace_place_y2axis_slot($::graph_to_use) ""
	set ::trace_place_y2axis_zoom($::graph_to_use) ""
	
	incr ::toplevel_count ;#- move to next toplevel

    }
    
    #---------------------------------------------------------------------------------------------------------------------------
    #
    #
    proc spice_update_traces { graph  { mode "" } { trace_list ""} } {
	
	# --  mode --
	# - "remove"  - removes traces in list from scope
	# - "add"        - add traces in list to scope
	# - "update"   - replaces the traces displayed with given list
	# - ""              - just update the current traces in the graph
	
	
	set scope_trace_list  [ $graph element names ] 
	
	# traces are been 'added' or 'removed'
	if { ( $trace_list != "") && ($mode != "") } {
	    
	    # removes passed traces from the legend if the exists
	    if { $mode == "remove" } {
		foreach trace $trace_list { 
		    if { [ $graph element exists $trace ] } { $graph element delete $trace }
		}
	    }
	    
	    # adds passed traces to the legend if the don't exists
	    if { $mode == "add" } { 
		foreach trace $trace_list {
		    if { [ $graph element exists $trace ]  == 0 } { $graph element create $trace }
		}
	    }
	    
	    # list traces in legend
	    set scope_trace_list  [ $graph element names ] 
	    
	    # mode "update" current traces just need refreshing  with new time steps
	    if { $mode == "update" } {
		# this just replaces the plot list with list passed
		#	set scope_trace_list { } 
		set scope_trace_list $trace_list 
	    }
	    
	}
	
	# remove all traces from the graph
	foreach trace [ $graph element names ]  { $graph element delete $trace }
	
	# repalce the traces in alphabetical order
	set trace_list [ lsort -dictionary   $scope_trace_list ]
	foreach trace $trace_list { $graph element create $trace } 
	
	#-----------------------------------------------------------------
	proc spice_trace_list_position { graph trace } {
	    
	    set trace_list [ lsort -dictionary   [ $graph  element names ] ]
	    set list_position [lsearch  $trace_list $trace] 
	    
	    if { $list_position == -1 } { return  -1 }
	    
	    return $list_position
	} 
	#-----------------------------------------------------------------
    	
	
	# delete all the old blt vectors 
	# create new vectors
	foreach vector_name  [ blt::vector names ::$graph\_trace_* ]  {  blt::vector destroy $vector_name }
	
	# retrieves the time vector
	blt::vector create _time
	spice::spicetoblt time _time 0 [ expr   \$::spice::steps_completed - 1]
	
	set index 0 
	# loop for each node in thelegend
	foreach trace_name [ $graph element names ]  {
	    
	    # if a saved trace that has been pre run 
	    if { [ regexp {_OLD} $trace_name ]  } { 
		
		set saved_plots_file [ open "$::spicefilename.gui_plots.tcl" "r"] 
		set trace_name_old "$trace_name\_OLD"
		gets $saved_plots_file string
		
		while { [eof $saved_plots_file ] == 0}  {
		    if { [ regexp $trace_name $string] } { 
			foreach xy { x y } {
			    
			    set start [ string first  " : " $string ]
			    set string [ string range $string [ expr $start + 3 ] end ]
			    
			    if { $xy == "x" } { _time set "$string "} 
			    if { $xy == "y" } {
				blt::vector create _vector
				_vector set "$string"
			    }
			    gets $saved_plots_file string
			}
		    }
		    gets $saved_plots_file string
		}
		
		close $saved_plots_file
		
		set symbol ""
		
	    } else {
		
		# if spice
		if {  [ spicevector_exists $trace_name ] } {  
		    
		    # retrieves the time vector
		    blt::vector create _time
		    spice::spicetoblt time _time 
	
		    # get the new trace values
		    blt::vector create _vector
		    spice::spicetoblt $trace_name _vector 
		    
		    set symbol "circle"
		    
		} else { 
		    blt::vector destroy _time
		    blt::vector create _time
		    blt::vector create _vector

		    _time set      ::spicewish::ext_$trace_name\_time
		    _vector set  ::spicewish::ext_$trace_name
		    set symbol ""
		    # spicewish::add_external_vector VCO "1 2 3" "1 2 1" 

		}
	    }
	    
	    # create an element on the graph called $Yname using the X and Y vectors
	    #-choose colour etc
	    if { [info exists ::linecolour($trace_name)] } {
		set colour $::linecolour($trace_name) ;#- if specific colour assigned to the trace
	    } elseif { [info exists ::linecolour($index)] } {
		set colour $::linecolour($index)  ;#- if within number of traces
	    } else { 
		
		# set colour $::linecolour(default) 
		# creates a random colour 
		set randred [format "%03x" [expr {int (rand() * 4095)}]]
		set randgreen [format "%03x" [expr {int (rand() * 4095)}]]
		set randblue [format "%03x" [expr {int (rand() * 4095)}]]
		set colour "#$randred$randgreen$randblue"
	    }
	    
	    set ::linecolour($trace_name) $colour ;# saves the traces colour 
	    
	    $graph element configure  $trace_name \
		-ydata "$_vector(:)" \
		-xdata "$_time(:)" \
		-symbol $symbol \
		-linewidth 2 \
		-pixels 3 \
		-color $colour

	    # vectors required for save 
	    blt::vector create $graph\_trace_Y[ spice_trace_list_position $graph $trace_name ]
	    blt::vector create $graph\_trace_X[ spice_trace_list_position $graph $trace_name ]
	    
	    _time dup $graph\_trace_X[ spice_trace_list_position $graph $trace_name ]
	    _vector dup $graph\_trace_Y[ spice_trace_list_position $graph $trace_name ]
	    
	    blt::vector destroy _vector
	    
	    incr index
	}
	
	# update the trace and place grid 
	TracePlace_update $graph 
    }
    
    #-----------------------------------------------------------------------------------------------------------------------------
    # creates temp vectors for 'trace'
    
    proc spice_return_trace_vectors { graph trace } {
	
	# delete any old temp value created by this procedure
	foreach vector [ blt::vector names temp_vector_* ] { blt::vector destroy $vector }
	
	# valid trace
	if { [ $graph element  exists  $trace ] != 1 } { return -1 }
	
	set list_position [ spice_trace_list_position $graph $trace ]
	
	$graph\_trace_X$list_position dup temp_vector_X
	$graph\_trace_Y$list_position dup temp_vector_Y	
	
	return 1
	
    }
    
    #------------------------------------------------------------------------------------------------------------------
    # called from pop up menu, when mouse over active trace
    
    proc TracePlace_remove_trace_from_slot { window } {
	
	# called from pop up menu when mouse over a trace on the screen "remove a1_x1_y0"
	
	regexp  {(.[0-9A-z]+)} $window window_clean
	set graph "$window_clean.scope.g"
	set tracePlace_w "$window_clean.scope.tp.ft.tracePlaceGrid"
	
	# exits if none of the legends are active
	if { [$graph legend activate] == "" } { return } 
	
	# exits if trace and place is not active 
	if { $::trace_place_selected($graph) == 0 } { return }  
	
	# get the current trace
	set trace  [ $graph legend activate ] 
	
	set slot_col -1
	
	# runs through all the slot lists and removes trace
	for {set col_cnt 0 } {$col_cnt <= $::columns} {incr col_cnt } {
	    for {set row_cnt 0} { $row_cnt <= [ expr (pow(2, $col_cnt) -1)  ] } {incr row_cnt } {
		
		if {  [ lcontain $::slot_trace_list($tracePlace_w.f_$col_cnt\_$row_cnt.b) $trace ] } {
		    
		    set slot_col $col_cnt
		    set slot_row $row_cnt
		    
		    set string_start [ string first $trace $::slot_trace_list($tracePlace_w.f_$col_cnt\_$row_cnt.b)  ]
		    set string_finish [ expr $string_start + [ string length $trace  ] - 1]
		    set ::slot_trace_list($tracePlace_w.f_$col_cnt\_$row_cnt.b)  [ string replace $::slot_trace_list($tracePlace_w.f_$col_cnt\_$row_cnt.b)  $string_start $string_finish "" ]
		    
		}
	    }
	}
	
	# exits if trace is not in any list
	if { $slot_col == -1 } { return } 
	
	# removes the trace from scope , drops the legend relief 
	$graph element configure $trace -labelrelief flat 
	$graph element configure $trace -hide 1	
	
	# removes trace from traceplace info bar bottom
	if { [$window_clean.tracePlaceInfoBar.fakeGraph element exists $trace ] } { $window_clean.tracePlaceInfoBar.fakeGraph element delete $trace }
	
	# update the slots canvas markers
	TracePlace_update_slot_canvas_markers $tracePlace_w $slot_col $slot_row
    }
    
    #-------------------------------------------------------------------------------------------------------------
    # creates a drag and drop package
    
    proc make_package {token graph { args ""} } {
	
	regexp  {(.[0-9A-z]+)} $graph scope_name
	set scope_name "$scope_name.scope.g"
	
	
	# exits if trace and place is not active 
	if { $::trace_place_selected($scope_name) == 0 } { return }  
	
	# case where a trace place slot is selected - for all slots traces to be moved to another slot
	if { $args ==  "tracePlaceGrid" } {
	    set list $::slot_trace_list($graph)
	    set list_length [llength $list]
	    
	    if { $list_length == 0 } { return }
	    
	    if { $list_length == 1 } {
		
		# removes all the " " at the end of the string
		while { [ string range $list [ expr [ string length $list] -1]   [ expr [ string length $list] -1]   ] == " " } {
		    set list [ string range $list 0 [ expr [ string length $list] - 2] ]
		}
		
		# removes all the " " at the start of the string
		while { [ string range $list 0 0 ]  == " " } {
		    set list [ string range $list 1 [ expr [ string length $list] - 1] ] 
		}
		
		$token.label configure -text $list  -background [ $scope_name element cget $list -color ] -height 1
		
	    } else {
		# more than one trace in the box
		$token.label configure -text "Traces"  -background green -height 1
	    }
	    return [list $list]
	}
	
	# exits if none of the legends are active
	if { [$graph  legend activate] == "" } { return } 
	
	$token.label configure -text [$graph legend activate] -background [ $scope_name element cget [$graph legend activate ] -color ] -height 1  
	
	return [ $graph legend activate ] 
    }
    
    
    #------------------------------------------------------------------------------------
    #BOTH buttons 1 & 2 
    proc tclspice_button_handler { button widget x y } {
	
	#get realcoords from pix
	set xreal  [$widget axis invtransform x $x]
	set yreal  [$widget axis invtransform y $y]
	
	# pop up box for markers
	if {$button == 2} {
	    pop_up_menu $widget $x $y
	}
	
    }
    
    
    #--------------------------------------------------------------------------------------
    # 
    #
    proc add_traces { graph args } {
	
	regexp  {(.[0-9A-z]+)} $graph window_name
	set graph_w "$window_name.scope.g"
	
	while { [ string range $args 0 0    ] == "\{" } {
	    set args [ string range $args 1 [ expr [ string length $args] - 1] ]
	}
	
	while { [ string range $args  [ expr [ string length $args] - 1]  [ expr [ string length $args] - 1]   ] == "\}" } {
	    set args [ string range $args 0 [ expr [ string length $args] - 2] ]
	}
	
	#puts "list add : $args"
	
	# blt plots need re work so that there are more than 6 colours then grey 
	# spice::bltplot $args
	spice_update_traces $graph_w add $args
	
    }
    
    
    
    #-----------------------------------------------------------------------------------------
    
    proc update_traces { widget trace_list  } {
	spice_update_traces $widget update $trace_list
    }
    
    #-----------------------------------------------------------------------------------------------
    proc remove_traces {widget trace } { 
	spice_update_traces $widget remove $args
    }
    
    #-----------------------------------------------------------------------------------------------------
    set ::pop_up_menu  "normal_mode"
    set ::disp_zoom_level 0
    
    #-------------------------------------------------------------------------------------------------------
    # creates the pop up menu
    
    proc pop_up_menu { widget x y } {
	global disp_zoom_level
	
	regexp  {(.[0-9A-z]+)} $widget window_name
	
	# returns if not over trace
	if { [ $window_name.scope.g legend activate] == "" } { return }
	
	set xreal $x
	set yreal $y
	
	catch {destroy .markerEntry }   ;# destroy old entry box
	catch {destroy .m}                     ;# destroy old pop up      
	menu .m -tearoff 0
	
	.m add command -label "Remove  [ $window_name.scope.g legend activate]" -command "spicewish::TracePlace_remove_trace_from_slot $window_name"
	
	.m add command -label "scale" -command "spicewish::TracePlace_set_scale_y2 $window_name.scope.g [ $window_name.scope.g legend activate]"
	
	.m add command -label "triggerpoints" 
	
	scan [wm geometry $window_name ] "%dx%d+%d+%d" width height xpos ypos
	set info_bar_y [ winfo height $window_name.f ]
	set trace_place_offset_x [ winfo x $window_name.scope.g ]
	
	tk_popup .m [expr $xpos + $x + $trace_place_offset_x] [expr $ypos + $y + $info_bar_y + $info_bar_y] ""
	
    }
    
    # -> slot 
    #     -> node
    #           - > data
    #           -> minvalue
    #           -> maxvalue
    #     -> minvalue
    #     -> maxvalue
    #     -> startposition
    #     -> finishposition

    # create_traceplace      'graph'
    # traceplace_add          'graph' 'slot' 'nodes'
    #  - adds nodes to slot
    # traceplace_remove    'graph'  'slot' 'nodes'
    #  - 
    # traceplace_move       'graph' 'slot nodes'
    #  - 
    # traceplace_update     'graph' '{min max} {min max} ..n'
    #  - 
    # traceplace_nodes      'graph' 'slot'
    #  - returns the list nodes in slot

    #------------------------------------------------------------------------------------------------------------------------
    # set up the y axis when using trace and place
    # 
    
    proc TracePlace_set_scale_y2 {graph { trace ""}} {
	
	# makes sure that a trace is passed
	if { $trace == "" } { puts "no trace passed" ; return }
	
	# exits if trace and place is not active 
	if { $::trace_place_selected($graph) == 0 } { return }  
	
	regexp  {(.[0-9A-z]+)} $graph window_clean
	set tracePlace_w "$window_clean.scope.tp.ft.tracePlaceGrid"
	
	# searches to which list the trace is from
	set slot_col -1
	for {set col_cnt 0 } {$col_cnt <= $::columns} {incr col_cnt } {
	    for {set row_cnt 0} { $row_cnt <= [ expr (pow(2, $col_cnt) -1)  ] } {incr row_cnt } {
		if {  [ lcontain $::slot_trace_list($tracePlace_w.f_$col_cnt\_$row_cnt.b) $trace ] } {
		    set slot_col $col_cnt
		    set slot_row $row_cnt
		}	
	    }
	}
	if { $slot_col == -1 } {  return } 
	
	# global variable that keeps track of which slot the scale is based on
	# should speed up cutting out the resizeing below
	
	if { ($::trace_place_y2axis_slot($window_clean.scope.g) == "$slot_col\_$slot_row")
	     &&
	     ($::trace_place_y2axis_zoom($window_clean.scope.g) == "[ $graph yaxis cget -min ]_[ $graph yaxis cget -max ]") } { return }
	
	set ::trace_place_y2axis_slot($window_clean.scope.g) "$slot_col\_$slot_row"
	#  set ::trace_place_y2axis_zoom($window_clean.scope.g) "$yaxis_min_$yaxis_max"
	
	
	# calculates maximum and minimum value of trace
	set trace_max_value ""
	set trace_min_value ""
	
	# runs through all traces on screen within the slot to find make 
	foreach trace_m $::slot_trace_list($tracePlace_w.f_$slot_col\_$slot_row.b) {
	    
	    # trace is not displayed on screen 
	    if { [ $window_clean.scope.g element cget $trace_m -hide ] == 1 } { continue }
	    
	    spice_return_trace_vectors $window_clean.scope.g $trace_m
	    
	    #$window_clean.scope.g_$trace_m dup temp
	    #set data_list_length [$window_clean.scope.g_$trace_m length]
	    set data_list_length [temp_vector_Y length]
	    
	    for { set i 0 } { $i < $data_list_length } { incr i } {
		if { $i == 0 } { 
		    set trace_max_value [ temp_vector_Y index $i ]
		    set trace_min_value [ temp_vector_Y index $i ]
		}
		
		if { [ temp_vector_Y index $i ] > $trace_max_value } { set trace_max_value [ temp_vector_Y index $i ]  }
		if { [ temp_vector_Y index $i ] < $trace_min_value  } { set trace_min_value [ temp_vector_Y index $i ]  }
	    }
	    
	}

	#  $window_clean.scope.g_$trace dup temp
	#  set data_list_length [$window_clean.scope.g_$trace length]
	# needed ???????????????
	spice_return_trace_vectors $window_clean.scope.g $trace 
	set data_list_length [temp_vector_Y length]
	
	# slots start and finish position
	set dimensions [ TracePlace_slot_dimension $graph $slot_col $slot_row ]
	set slot_start_position [lindex $dimensions 0]
	set slot_finish_position [lindex $dimensions 1]	    
	
	# displays second axis
	$graph y2axis configure -hide 0  
	
	set yaxis_min [ $graph yaxis cget -min ]
	set yaxis_max [ $graph yaxis cget -max ]
	
	# calculates the axis scale
	#if { $trace_min_value < 0 } { set temp_min [ expr $trace_min_value * -1 ] } else { set temp_min $trace_min_value } 
	set trace_min_value $trace_min_value
	set scale_factor [ expr ( $trace_max_value - $trace_min_value) / ( $slot_finish_position - $slot_start_position )]
	if { $trace_min_value == 0 } { set trace_min_value 0.000001 }
	set scale_min [ expr $trace_min_value - ( $slot_start_position * $scale_factor)]
	set scale_max [ expr $trace_max_value + ( (100 - $slot_finish_position ) * $scale_factor) ]
	
	$graph y2axis configure -min $scale_min -max $scale_max 	
	
	# need to take into consideration also when zoomed in 
	set yaxis_min [ $graph yaxis cget -min ]
	set yaxis_max [ $graph yaxis cget -max ]
    
	# zoom level 1:1
	if { [ expr int ($yaxis_max - $yaxis_min) ] ==100 }  { return }
	
	set ::trace_place_y2axis_zoom($window_clean.scope.g) "$yaxis_min\_$yaxis_max"
	
	set y2axis_min [ $graph y2axis cget -min ] 
	set y2axis_max [ $graph y2axis cget -max ]
	set scale_factor [ expr 100 / ( $y2axis_max - $y2axis_min ) ] 
	set scale_min [ expr $y2axis_min + ( $yaxis_min / $scale_factor )]
	set scale_max [ expr $y2axis_min + ( $yaxis_max / $scale_factor ) ]
	
	$graph y2axis configure -min $scale_min -max $scale_max 
	
    }
    #-----------------------------------------------------------------------------------------------------
    # creates a widget to enter names 'rename graph' & 'name of postscript file'

    proc entry_selection_box {window_name mode {xreal "" } {yreal ""} } {
	
	scan [wm geometry $window_name ] "%dx%d+%d+%d" width height xpos ypos
	catch {destroy .markerEntry }
	toplevel .markerEntry 
	wm geometry .markerEntry  300x70+[expr $xpos + ($width / 2  ) - 150]+[expr $ypos + ($height /2) - 35] ;# position in centre
	
	set ::temp_window_name $window_name
	
	#-----
	if {$mode == "graph" } {
	    
	    wm title .markerEntry "Rename Graph"
	    
	    pack [ label .markerEntry.l -text "Enter text:" ] -fill x
	    pack [ entry .markerEntry.e -textvariable ::marker_entry_text -background white ] -fill x
	    set ::marker_entry_text [wm title $window_name]
	    
	    pack [ button .markerEntry.b -text "OK" -command  {wm title $::temp_window_name $marker_entry_text ; catch {destroy .markerEntry } } ]
	
	    bind .markerEntry.e <Return> {wm title $::temp_window_name $marker_entry_text ; catch {destroy .markerEntry } } 
	    
	    focus -force .markerEntry.e  
	} 
	
	#-----
	if {$mode == "save_to_postscript" } {
	    
	    wm title .markerEntry "Save to postscript"
	    
	    pack [ label .markerEntry.l -text "Enter file name:" ] -fill x
	    pack [ entry .markerEntry.e -textvariable ::marker_entry_text -background white ] -fill x
	    set ::marker_entry_text "temp.ps"
	    
	    pack [ button .markerEntry.b -text "OK" -command  { spicewish::postscript_bw $::temp_window_name.scope.g $marker_entry_text ; catch {destroy .markerEntry }   } ]
	    
	    bind .markerEntry.e <Return> { spicewish::postscript_bw $::temp_window_name.g $marker_entry_text ; catch {destroy .markerEntry }   } 
	    focus -force .markerEntry.e  
	} 
	
    }
    
    #-----------------------------------------------------------------------------------------------
    
    proc tclspice_motion_handler { widget x y } {
	
	#   puts $widget
	#   puts $x
	#   puts $y
	#   puts [$widget axis invtransform x $x]
	#   [%W axis invtransform x %x]  
    }
    
    #-----------------------------------------------------------------------------------------------------------
    #blt calls this back when doing the ticks --- replace the floating value with an engineering value
    proc graph_Y_axis_callback { widget value } {    
	return [ float_eng_spice $value]
    }
    
    #-------------------------------------------------------------------------------------------------------------
    
    
    ########################################################################
    # Postscript
    #
    ########################################################################
    
    #Changes to b/w, removes marker points etc
    proc postscript_bw { graph_name filename } {
	
	#make bw with dashes instead of colours
	postscript_make_bw    $graph_name
	postscript_add_dashes $graph_name
	
	#postscript
	$graph_name postscript output $filename
	
	foreach trace_bw [ $graph_name element names ] {
	    $graph_name line configure $trace_bw -symbol {}  ;#- turn off symbols
	    $graph_name line configure $trace_bw -color black   ;#- turn to black
	}
    }
    
    #----------------------------------------------------------------------------------------------
    #replaces colours with black
    
    proc postscript_make_bw { graph_name } {
	
	foreach trace_bw [ $graph_name element names ] {
	    $graph_name line configure $trace_bw -symbol {}  ;#- turn off symbols
	    $graph_name line configure $trace_bw -color black   ;#- turn to black
	}
    }
    
    #---------------------------------------------------------------------------------------------------
    #replaces colours with dashes

    proc postscript_add_dashes { graph_name } {
	
	set tracecnt 0 
	
	#scan through traces on the graph
	foreach trace_bw [ $graph_name element names ] {
	    
	    #-dashlist etc - either a specific one, or the incremental one
	    if { [info exists ::dashlist($trace_bw)] } {
		set dashes $::dashlist($trace_bw) ;#- if specific dash assigned to the trace 
	    } elseif { [info exists ::dashlist($tracecnt)] } {
		set dashes $::dashlist($tracecnt)  ;#- if within number of traces
	    } else { set dashes $::dashlist(default) }
	    
	    $graph_name line configure $trace_bw -dashes  $dashes
	    
	incr tracecnt
	}
    }
    
    

    
    
    #--------------------------------------------------------------------------------------------------------
    #Routine to clear out the graph ready for re-plotting
    proc spice_gr_cleargraph { graph_name } {
	
	global disp_zoom_level
	set ::trace_index_counter 0  ;#- clear the count
	
	# returns graph to zoom 1:1
	if {$disp_zoom_level >0} {
	    Zoom1:1 $graph_name
	}

	#remove old traces
	foreach trace_to_zap [ $graph_name element names ] {
	    $graph_name element delete $trace_to_zap
	}
	
	#remove old markers
	foreach trace_to_zap [ $graph_name marker names ] {
	    $graph_name marker delete $trace_to_zap
	}
	
	# remove vectors associated with traces
	
    }
    
    #-----------------------------------------------------------------------------------------------------
    
    # spice::bltplot callback handler --- comes here with each pair of vectors, can
    #
    # On entry:-
    #
    # ::graph_to_use                 - is the destination blt::graph - set before issuing the   spice::bltplot  command
    # ::linecolour("tracename")   - hash for colour lookup e.g  linecolour(A0) might be red  
    #
    #  ?name - name of trace
    #  ?type - type e.g. voltage  current  time
    #  ?units - e.g. amp second
    #
    # ::spice::X_data  - X axis data -  for this pair of values
    # ::spice::Y_data  - Y axis data 
    #
    # On return:-
    # 
    #   global blt vectors   "::${graph_to_use}_X0...?" has the trace number in for X,  similar for Y.
    #                          e.g. ::.g_Y0 etc   exist
    #   
    #   global list of spice vectors   "::${graph_to_use}_plotlist  gets  e.g. Q0 Q1 etc on it
    #                                  - used to do re-plot when gui restored   
    #
    #   blt graph  $::graph_to_use  will have elements of the names of the  Y  trace of spice 
    
    
    
    # not used
    proc spice_gr_Plot { Xname Xtype Xunits Yname Ytype Yunits } {
	
	puts "$Xname $Xtype $Xunits $Yname $Ytype $Yunits "
	
	#set vector names
	set xvect_name "::${::graph_to_use}_X$::trace_index_counter"
	set yvect_name "::${::graph_to_use}_Y$::trace_index_counter"
	
	
	#copy global to new vectors
	#- creates e.g. ::vect_time   for time
	blt::vector create   $xvect_name
	$xvect_name  set $::spice::X_Data(:) 
	
	#- creates e.g. ::vect_a0  for a0
	blt::vector create $yvect_name
	$yvect_name  set $::spice::Y_Data(:) 
	
	#create an element on the graph called $Yname using the X and Y vectors
	#-choose colour etc
	if { [info exists ::linecolour($Yname)] } {
	    set colour $::linecolour($Yname) ;#- if specific colour assigned to the trace
	} elseif { [info exists ::linecolour($::trace_index_counter)] } {
	    set colour $::linecolour($::trace_index_counter)  ;#- if within number of traces
	} else { 
	    # set colour $::linecolour(default) 
	    
	    # creates a random colour 
	    set randred [format "%03x" [expr {int (rand() * 4095)}]]
	    set randgreen [format "%03x" [expr {int (rand() * 4095)}]]
	    set randblue [format "%03x" [expr {int (rand() * 4095)}]]
	    set colour "#$randred$randgreen$randblue"
	}
	
	#-add line
	$::graph_to_use  element create $Yname -xdata "$xvect_name" -ydata "$yvect_name" \
	    -symbol "circle" \
	    -linewidth 2 \
	    -pixels 3
	
	$::graph_to_use  line configure $Yname -color  $colour
	
	#-move to next colour
	incr ::trace_index_counter
    }
    
    #------------------------------------------------------------------------------------------------------------
    #handler for   tclreadline - does command completion for finding the plot traces
    #          -see main code where this is set
    
    proc plot_command_readline_completer { word start end line } {
	
	set match {} ;#- no match found yet
	set shortest_string_len 1000 ;#- will always get shorter
	set matches 0 ;#- totaliser for matches

	#check for "plot" command line

	if { [ regexp {\s+spicewish\:\:plot} " $line " ] } {
	    #found plot near the start of the line
	    
	    #check if punter is asking for a variable
	    if { $start >= 5 } {

		#-find the last item typed so far
		set arglist [split $line " "]
		set lastarg [lindex $arglist end]
		
		#-search against the possible spice variables
		set possibility_list {}	   
		
		set varlist [spice::plot_variables 0]  ;#- get current spice traces
		
		foreach possibility $varlist {
		    #check for exact match
		    if {$lastarg == $possibility} { 
			set possibility_list $possibility
			break
		    }
		    
		    #check for close match
		    if { [string match "${lastarg}*" $possibility] } {
			lappend possibility_list $possibility ;#- add to list
			incr matches ;#-add another match
			#update shortest len
			if { [string length $possibility] < $shortest_string_len } {
			    set shortest_string_len  [string length $possibility]
			}
		    } 				
		}
		
		#check for exact match
		if { $lastarg == $possibility } { set match $lastarg } else { set match "" }
		
		#for multiple matches, find the longest common bit of string to return  readline style
		#-loop for each character
		set done 0
		for {set charindex 0} { $charindex < $shortest_string_len } { incr charindex } {
		    
		    #-get char from one string
		    set char [string index [lindex $possibility_list 0] $charindex]
		    
		    #check in each of other strings for same character
		    for {set cnt 1} {$cnt < $matches} {incr cnt} {
			
			set char_alt [string index [lindex $possibility_list $cnt] $charindex]
			
			if {$char != $char_alt } {
			    #found a mismatch, so exit now
			    set done 1
			    break
			}
			if { $done == 1} { break }
		    }
		    if { $done == 1} { break }
		}
		
		#return the longest common portion which matches 
		set common_bit [string range [lindex $possibility_list 0] 0 [expr $charindex-1] ]
		
		#sort the return values into alphabetic order
		set possibility_list [lsort -dictionary $possibility_list]
		
		#return parameters for the readline
		return [list $common_bit $possibility_list]  ;#
		
	    } ;#- end of if starting at the right place
	    
	} ;#- end of if got plot in the line
	
	::tclreadline::ScriptCompleter  $word $start $end $line    
    }
    
    #----------------------------------------------------------------------------------------------------
    
    #Eng units stuff
    set ::significant_digits 4   ;#- mininum signficant digits to show - might show more e.g.  125 will be shown no matter what
    
    #lookup hashes
    set ::table_eng_float_MSC(T) 1e+12
    set ::table_eng_float_MSC(G) 1e+9
    set ::table_eng_float_MSC(M) 1e+6
    set ::table_eng_float_MSC(K) 1e+3
    set ::table_eng_float_MSC(\n) 1; # Will need to change?
    set ::table_eng_float_MSC(m) 1e-3
    set ::table_eng_float_MSC(u) 1e-6
    set ::table_eng_float_MSC(\u03BC) 1e-6 
    set ::table_eng_float_MSC(n) 1e-9
    set ::table_eng_float_MSC(p) 1e-12
    set ::table_eng_float_MSC(f) 1e-15
    set ::table_eng_float_MSC(a) 1e-18
    
    #inverse hash  
    set ::table_float_eng_MSC(1e+12)" T"
    set ::table_float_eng_MSC(1e+9) " G"
    set ::table_float_eng_MSC(1e+6) " M"
    set ::table_float_eng_MSC(1e+3) " K"
    set ::table_float_eng_MSC(1)    " "
    set ::table_float_eng_MSC(1e-3) " m"
    set ::table_float_eng_MSC(1e-6) " \u03BC"
    set ::table_float_eng_MSC(1e-9) " n"
    set ::table_float_eng_MSC(1e-12) " p"
    set ::table_float_eng_MSC(1e-15) " f"
    set ::table_float_eng_MSC(1e-18) " a" 
    
    #-----------------------------------------------------------------------------------------------------------
    # Returns best abbreviated number from a real input
    proc float_eng_spice {num {forceunit ""} } {
   
	#On entry,  forceunit can be  u,p whatever as an option to force the result 
	#           into that unit rather than the best one
	#           Or, can be "1"
	
	
	#30/5/02  - force the unit and return no decimal places if force is on
	if { $forceunit != "" } {
	    
	    if { $forceunit == "1" } {	    
		
		return [format %.0f $num ] ;#- just return the number
	    } else {
		#-fixed suffix
		set multiplier $::table_eng_float_MSC($forceunit) ;#- look up number from the suffix
	    }
	    
	    if { $forceunit == "u" } { set forceunit "\u03BC" } ;#- use the nicer u figure
	    
	    #zero decimal places
	    set returnval "[format %.0f [expr $num / $multiplier]] $forceunit";	
	    return $returnval
	}
	#end 30/5/02
	
	#Normal operation...
	
	set indexes [lsort -real -decreasing "[array names ::table_float_eng_MSC]"]
	
	set out {}; # If no suffix found, return number as is
	
	if "$num != 0" {
	    foreach index $indexes {

		set newnum "[expr {$num / $index}]"
		set whole 0
		set fraction 0; # In case of integer input
		
		# regexp {^(\d+)} $newnum whole; # Messy!
		# Uses stupid variable to save having to do two regexp's
		regexp {^(\d+)\.*(\d*)} $newnum stupid whole fraction
		
		if {[expr {[string match {*e*} $newnum] == 0}] && \
			[expr {$whole >0 }] } {
		    set suf "$::table_float_eng_MSC($index)" 
		    
		    #work out how many decimal places to show - fixed to 4 significant digits
		    set decimal_length_to_show [ expr ( ($::significant_digits - 1 ) - [ string length $whole ] ) ]
		    if { $decimal_length_to_show >= 0 } {
			
			if { $fraction == "" } {
			    set newnm $whole
			} else {
			#need some decimal places to give the resolution required
			    set newnum "$whole.[string range $fraction 0 [ expr ($decimal_length_to_show)] ]"
			}
			
		    } else {
			#no decimal places
			set newnum $whole  ;#- just use the whole, no decimals
		    }
		    
		    set out "$newnum$suf"
		    return "$out"
		    break
		} else {
		    #puts "[expr {fmod($newnum,1)}] is not big enough"
		}
	    }
	}
	if {[string equal $out {}]} {
	    #puts {Appropriate suffix not found}
	    return $num
	}
    }
    
    
    #------------------------------------------------------------------------------------------------------------
    
    set ::spice_run 0  ;#- not yet run
    set ::spicefilename "" ;#- complete name of spice file

    #-------------------------------------------------------------------------------------------------------------
    #Initialises the gui
    proc init_gui { spicefile } {
	
	#load spice file if given
	if { $spicefile != "" } {
	    
	    # test if 'spicefile' is a project
	    if { [regexp {.swp} $spicefile] } { 
		
		# unpacks the project
		project_open $spicefile 
		
		# generates list of project files
		set file_list [ project_file_list $spicefile ]
	
		for { set i 0 } { $i < [ llength $file_list ] } { incr i } {		      
		    
		    set file_name [ lrange $file_list $i $i ]
		    
		    # searches for the circuit file
		    if { [ string range $file_name end-3 end] == ".cir" } {
			set ::spicefilename  $file_name  ;#- save name
		    }
		}
		
		# no spice file found 
		if { $::spicefilename == ""} { error "no spice file found in project"}
		
		
		
	    } else {
		
		set ::spicefilename  $spicefile  ;#- save name
	    }

	    spice::source $::spicefilename
	    wm title . "spicewish - $spicefile"
	}
	
	#pack the gui
	pack [ frame .control_butts] -side left -anchor n
	
	pack [ button .control_butts.b_stop -text "STOP " -command { spice::stop }] -fill x

	pack [ button .control_butts.b_go   -text "Run" -command { 

	    if {  $::spice::steps_completed < 1 } { 
		spice::bg run 
		set spice_run 1 ;#- has now run once, so next time resume
		.control_butts.b_go configure -text "Resume"
	    } else { 
		spice::bg resume
	    } 
	}] -fill x
	
	pack [ button .control_butts.b_plot -text "Plot" -command "spicewish::trace_selection_box"] -fill x
	
	#  pack [ button .control_butts.b_savegui -text "Savegui" -command { save_all_nutmeg_windows }] -fill x

	#  pack [ button .control_butts.b_restgui -text "Restorgui" -command { restore_all_nutmeg_windows } ] -fill x
	
	pack [ button .control_butts.b_notes -text "Edit" -command {spicewish::edit_window } ] -fill x
	
	pack [ button .control_butts.b_saveProject -text "Save Pro" -command { spicewish::project_save $::spicefilename  }] -fill x
	
	pack [ button .control_butts.b_quit -text "Quit" -command { exit }] -fill x
	
	# replots scopes if opening a project file
	if { [regexp {.swp} $spicefile] } {  restore_all_nutmeg_windows }
	
    }
    
    ######################################################################
    # editing  - spice file - project notes 
    #
    ######################################################################
    
    proc edit_window { } { 
	
	if { [ winfo exists .edit] } {
	    pack .edit
	} else {
	    
	    pack [ frame .edit ] -expand 1 -fill both
	    blt::tabnotebook .edit.tnb
	    
	    set count 0
	    foreach tab { "spice_file" "project_notes"} {
		
		.edit.tnb insert end -text  [ string totitle $tab ]
		.edit.tnb configure -tearoff 0
		
		pack [ frame .edit.tnb.$tab ] -expand 1 -fill both
		.edit.tnb tab configure $count  -window .edit.tnb.$tab -fill both
		
		pack [ frame .edit.tnb.$tab.buttons ] -side bottom 
		
		if { $tab == "spice_file" } {
		    set ::text_search 0
		    set ::text_string ""
		    pack [ entry .edit.tnb.$tab.buttons.search_entry -background white -textvariable ::text_string] -side left
		    pack [ checkbutton .edit.tnb.$tab.buttons.search_select -variable ::text_search -command spicewish::edit_text_search ] -side left
		}
		
		pack [ button .edit.tnb.$tab.buttons.b_cancel -text "Close" -command "pack forget .edit"] -side left
		pack [ button .edit.tnb.$tab.buttons.b_save -text "Save" -command "spicewish::save_file_from_text .edit.tnb.$tab.text $tab"] -side left 
		
		if { $tab == "spice_file" } {
		    pack [ button .edit.tnb.$tab.buttons.b_reRun -text "Re Run" -command spicewish::reRun ] -side left
		}
		
		#-----------------------------------------------
		proc reRun { } {
		    
		    save_all_nutmeg_windows reRun
		    spice::halt
		    spice::stop
		    spice::reset 
		    spice::source $::spicefilename
		    
		    after 100
		    
		    set ::spice_run 0 
		    restore_all_nutmeg_windows
		}
		#------------------------------------------------
		
		pack [ scrollbar .edit.tnb.$tab.scroll -command ".edit.tnb.$tab.text yview" ] -side right -fill y 
		pack [ text .edit.tnb.$tab.text -background white -yscrollcommand ".edit.tnb.$tab.scroll set"] -expand 1  -fill both ;# pack last due top resizing
		
		
		# load the text file
		if { $tab == "spice_file" } { 
		    load_file_to_text .edit.tnb.$tab.text $::spicefilename 
		    .edit.tnb.$tab.text configure -background LemonChiffon
		    edit_highlight_spicevariables .edit.tnb.$tab.text
		}
		
		if { $tab == "project_notes" } { 
		    load_file_to_text .edit.tnb.$tab.text $::spicefilename.project_notes.txt  
		}
		
		incr count
	    }
	    pack  .edit.tnb  -fill both -expand 1
	}
    }
    
    #------------------------------------------------------------------------------------------------------
    # saves text widget to file 
    proc save_file_from_text { w tab } {
	
	if {$tab == "project_notes" } {set filename "$::spicefilename.project_notes.txt" }
	if {$tab == "spice_file" } {set filename "$::spicefilename" }
	
	# saves text window to .txt file
	set data [$w get 1.0 {end -1c}]
	set fileid [open $filename w]
	puts -nonewline $fileid $data
	close $fileid
    }
    
    #-----------------------------------------------------------------------------------------------------------
    # loads files into a text widget
    proc load_file_to_text  {w file} {
	
	# test if file exsists
	if { [ file exists $file ] == 0 } { return  }
	
	set f [open $file]
	$w delete 1.0 end
	while {![eof $f]} { $w insert end [read $f 10000] }
	close $f
    }
    
    #------------------------------------------------------------------------------------
    # highlight text in entry field
    
    proc edit_text_search { } {
	
	set w ".edit.tnb.spice_file.text"
        
	if { $::text_search == 0 } { 
	    $w tag delete search 
	    return 
	}
	
	$w tag remove search 0.0 end
	if {$::text_string == ""} { return }
	set cur 1.0
	while 1 {
	    set cur [$w search -count length $::text_string $cur end]
	    if {$cur == ""} { break }
	    
	    $w tag add search $cur "$cur + $length char"
	    set cur [$w index "$cur + $length char"]
	    
	    $w tag configure search -foreground white
	    $w tag configure search -background red
	}
    }
    
    #-------------------------------------------------------------------------------------------
    # searches through the text highlighting 'strings'  with passed 'colour'
    
    proc text_search {w string colour} {
	
	# string passes the starting character eg "c" for capacitors 
	
	set tag $string
	$w tag remove search 0.0 end
	
	if {$string == ""} { return }
	
	set start 1.0
	while 1 {
	    set start [$w search -count length $string $start end]
	    if {$start != "" } {
		
		# returns the position of the next  " " 
		set finish [$w search -count length " " $start [expr $start + 1 ]] 
		
		if {( $start == "") || ($finish =="")} {
		    break
		
		} else {

		    # ad call 
		    # doesn't seem to work for the L becuase they go overf two lines this crashes this
		    # need to test if the start anf finish are on the same line
		    
		    regexp {([0-9]+).([0-9]+)} $finish finish_match finish_row finish_col 
		    
		    set valid 1
		    
		    # if start character not at start of line
		    
		    regexp {([0-9]+).([0-9]+)} $start start_match start_row start_col 
		    
		    if { $start_match == $start   } {
			if { $start_col != 0 } {
			    
			    if { [ $w get "$start_row.[ expr $start_col - 1]"  ] != " " } { set valid 0   }
			}
		    }
		    
		    # test that start and finish are on the same line
		    if { $start_row != $finish_row  } { set valid 0 }
		    
		    if { $valid == 1 } { 
			# set text passed colour between 
			$w tag add $tag $start   $finish
			$w tag configure $tag -foreground $colour 
		    }
		}
		
		
	    } else { break }
	    
	    
	    # error trap
	    # previous character must == "" //  beging of line f
	    
	    set start [$w index "$start + $length char"]
	    
	}
    }
    
    #--------------------------------------------------------------------------------------
    
    proc edit_highlight_spicevariables { w  } {
	text_search $w L blue
	text_search $w V red
	text_search $w R green
	
    }
    
    #--------------------------------------------------------------------------------------
    
    ###########################################################################
    # selecting traces
    #
    ###########################################################################
    
    #---------------------------------------------------------------------------------------------------------------------------------------
    # 10/3/03 -ad
    # return list of spice node types eg 'voltage current time'
    #
    proc spicevector_types {  } { 
	
	# run first step to get data
	if { $::spice::steps_completed < 1 } { spice::step 1 }
	
	# get list of vectors 
	set list [spice::spice_data]

	set typeList ""
	# loop foreach vector
	foreach type $list { 
	    set type [ lindex $type 1 ]
	    set typeL [ string tolower $type ] 
	 
	    if { ! [ lcontain $typeList $typeL  ] } { 
		if { $typeL == "time" } { continue }
		lappend typeList $typeL 
	    }  
	}
	
	# test for externally added nodes
	# - see spicewish::add_external_nodes
	set externalList [ blt::vector names ::spicewish::ext* ]
	if { [ llength $externalList ]  > 0  } { 
	    lappend typeList "external" 
	}

	# test for saved 
	if {  [ info exists ::OLD_plots] } { 
	    if { [ llength $::OLD_plots ]  > 0  } { 
		lappend typeList "saved"
	    }
	}

	return $typeList 
    }

    #-------------------------------------------------------------------------------------------------------------------
    # 10/3/03 -ad
    # returns a list of all the extrenal added nodes 
    # - see "spicewish::add_external_vector"
    #
    proc external_nodes {  { searchNode "" } } { 
	# no vale passed returns list of nodes
	set externalList [ blt::vector names ::spicewish::ext* ]
	if { [ llength $externalList ]  > 0  } { 
	    
	    set nodeList ""
	    foreach external $externalList  {
		
		set node [ string range $external 17 end ] ;#- strips "::spicewish::" from start of string
		if { [ string range $node end-4 end ] == "_time" } { continue } ;# time vector
		
		if { ! [ lcontain $nodeList $node ]  } { lappend nodeList $node } 
	    }
	    if { $searchNode == "" }  {
		return $nodeList 
	    } else { 
		# searching for '$searchNode'
		set nodeList [ string tolower $nodeList ]
		set searchNode [ string tolower $searchNode ]
		if { [ lcontain $nodeList $searchNode ]  } {  return 1 } 
	    }
	} else {
	     if { $searchNode == "" }  { return "" } 
	}
	return 0
    } 

    #------------------------------------------------------------------------------------------------------------------
    # 10/3/02 -ad
    # returns the names of the tabs in the node selection dialog
    #
    proc node_selection_tabnames { } { 
	
	if { ! [ winfo exists .trace_selection_box ] } { return }
	# gets tab names
	set tabNames ""
	set tabIds [ .trace_selection_box.tnb tab names ] 
	foreach tabId $tabIds {
	    set tabName [ .trace_selection_box.tnb tab cget $tabId -text ]
	    set tabName [ string tolower $tabName ]
	    lappend tabNames $tabName
	}
	return $tabNames
    }

    #-------------------------------------------------------------------------------------------------------------------
    # 10/3/03 -ad
    # refreshes the node selection dialog 
    #
    proc update_selection_box { { graph_name "" } } { 
	
	# load all spice vectors
	foreach trace [ spice::spice_data ] {
	    set node [ lindex $trace 0 ] 
	    set type  [ lindex $trace 1 ] 
	    if { [ string tolower $type ]  == "time" } { continue  } ;#- don't add the time vector
	    set node [ string tolower $node ]
	    .trace_selection_box.tnb.$type.hierbox insert -at 0 end $node -labelfont {times 10}     
	}

	# externally added nodes
	if { [ llength [ external_nodes ]]  > 0  } { 
	    foreach node [ external_nodes ] { 
		set type "external"  
		set node [ string tolower $node ]
		.trace_selection_box.tnb.$type.hierbox insert -at 0 end $node -labelfont {times 10}     
	    }
	}

	# saved (re run) vectors
	if { [ info exists ::OLD_plots] } {
	    foreach node $::OLD_plots  {
		set node [ string tolower $node ]
		set node "$node\_old"
		#puts "node : $node "
		.trace_selection_box.tnb.saved.hierbox insert -at 0 end $node -labelfont {times 10} 
	    }	    
	}
	
	# highlight node in 'graph_name'
	if { $graph_name == "" } { return } 

	# highlight selected traces
	set selected_nodes  [$graph_name element names ]
	foreach node $selected_nodes {
	    set node [ string tolower $node ]
	    
	    # externally added node
	    if  { [ external_nodes $node ] }  {
		# is an externally added node
		set nodePosition [ .trace_selection_box.tnb.external.hierbox find -name $node ] 
		.trace_selection_box.tnb.external.hierbox entry configure $nodePosition -labelfont {times 12 bold}

	    } elseif { [string range $node end-3 end ] == "_old"  } { 
		# saved plots
		set nodePosition [ .trace_selection_box.tnb.saved.hierbox find -name $node ] 
		.trace_selection_box.tnb.saved.hierbox entry configure $nodePosition -labelfont {times 12 bold}

	    } else { 
		# find the nodes type eg 'voltage' 'current' 
		set type ""
		foreach spiceString [ spice::spice_data ] { 
		    set tmpName [ lindex $spiceString 0 ] 
		    if { $tmpName == $node } { 
			set type [ lindex $spiceString 1 ]
			break 
		    }
		}
		set nodePosition [ .trace_selection_box.tnb.$type.hierbox find -name $node ] 
		.trace_selection_box.tnb.$type.hierbox entry configure $nodePosition -labelfont {times 12 bold}	
	    }
	}
    }

    #--------------------------------------------------------------------------------------------------------------------
    #
    #
    proc trace_selection_box { {args ""} {graph_name "" }  } {
	
	regexp  {(.[0-9A-z]+)} $graph_name window_name
	#set scope_name "$scope_name.scope.g"
	
	# error if spice not been stepped
	if { $::spice::steps_completed < 1 } {  spice::step 1  } 
	
	catch {destroy .trace_selection_box }
	toplevel .trace_selection_box
	wm title .trace_selection_box "Select Traces"
		
	pack [ blt::tabnotebook .trace_selection_box.tnb ]  -fill both -expand 1 

	set count 0 

	set tabList [ spicevector_types ]

	foreach tabs $tabList  {
	    
	    .trace_selection_box.tnb insert end -text [ string totitle $tabs] 
	    .trace_selection_box.tnb configure -tearoff 0
	    
	    frame .trace_selection_box.tnb.$tabs  ;#- frame for each tab 
	    
	    .trace_selection_box.tnb tab configure $count -window .trace_selection_box.tnb.$tabs -fill both
	    
	    # eval required due to use of '$tabs' in widgets names
	    eval  "blt::hierbox .trace_selection_box.tnb.$tabs.hierbox  -hideroot true -yscrollcommand { .trace_selection_box.tnb.$tabs.vert set } -xscrollcommand { .trace_selection_box.tnb.$tabs.horz set } -background white"
	    
	    eval "scrollbar .trace_selection_box.tnb.$tabs.vert   -orient vertical -command { .trace_selection_box.tnb.$tabs.hierbox yview } -width 10 "

	    eval  "scrollbar .trace_selection_box.tnb.$tabs.horz   -orient horizontal  -command { .trace_selection_box.tnb.$tabs.hierbox  xview } -width 10 "
	    

	    # control buttons
	    if { ( $args == "update" ) || ($graph_name != "" ) } {
		button .trace_selection_box.tnb.$tabs.b -text "Update" \
		    -command "spicewish::load_plots_from_selection_box update $graph_name "
	    } else {   
		button .trace_selection_box.tnb.$tabs.b -text "Plot" \
		    -command "spicewish::load_plots_from_selection_box normal"  
	    }

	    blt::table .trace_selection_box.tnb.$tabs   \
		0,0 .trace_selection_box.tnb.$tabs.hierbox  -fill both \
		0,1 .trace_selection_box.tnb.$tabs.vert  -fill y \
		1,0 .trace_selection_box.tnb.$tabs.horz  -fill x \
		2,0 .trace_selection_box.tnb.$tabs.b -fill x -cspan 2
	    
	
	    blt::table configure .trace_selection_box.tnb.$tabs   c1 r1 r2  -resize none  
	
	    
	    # bind button 1/2 to move through the tabs
	    .trace_selection_box.tnb.$tabs.hierbox bind all <Button-2> { .trace_selection_box.tnb select left }
	    .trace_selection_box.tnb.$tabs.hierbox bind all <Button-3> { .trace_selection_box.tnb select right }
	    
	    # bind button 1 to the select the traces from the list
	    .trace_selection_box.tnb.$tabs.hierbox bind all <Button-1> {
		set hierbox_path %W
		set _index [  $hierbox_path index current]
		
		if { [ $hierbox_path entry cget $_index -labelfont] == {times 10}} {
		    $hierbox_path entry configure $_index -labelfont {times 12 bold}
		} else {
		    $hierbox_path   entry configure $_index -labelfont {times 10}
		}   
	    }
	    incr count
	}
	# loads vector into hierbox's
	update_selection_box $graph_name
    }
    
    #-----------------------------------------------------------------------------------------------------------------
    # 10/3/3 -ad 
    # loads selected nodes in hierbox's into a new viewier
    # - mode "normal" creates a new viewier
    # - mode "update" loads nodes into "graph_name"
    #
    proc load_plots_from_selection_box {mode { graph_name "" } } {

	# gets tab names
	set tabNames ""
	set tabIds [ .trace_selection_box.tnb tab names ] 
	foreach tabId $tabIds {
	    set tabName [ .trace_selection_box.tnb tab cget $tabId -text ]
	    set tabName [ string tolower $tabName ]
	    lappend tabNames $tabName
	}

	# get selected nodes
	set list ""
	foreach tabs $tabNames {
	    for {set i 1} { $i <= [ .trace_selection_box.tnb.$tabs.hierbox index end ] } {incr i} {
		
		if {[ .trace_selection_box.tnb.$tabs.hierbox entry cget $i -labelfont] == {times 12 bold}} {
		    lappend list [.trace_selection_box.tnb.$tabs.hierbox  get $i ]
		}
	    }
	}

	# error no traces seleted
	if { [ llength $list ] == 0 } { 
	    set choice [tk_messageBox -message "No traces seleted"  -type okcancel -icon error -parent .trace_selection_box]
	    if {$choice == "cancel" } {  destroy .trace_selection_box  }
	    return	
	} 
	
	# stops spice if running
	if { [spice::running] } { spice::halt }
	
	if {$mode == "normal" } {
	    plot $list   ;# -   creates a new plot
	}

	if  {$mode == "update" } {
	    update_traces $graph_name $list ;#  updates the exsisting plots 
	}
	
	destroy .trace_selection_box 
    }
    
    #-----------------------------------------------------------------------------------------------------------------
    
    # window management routines
    
    proc save_all_nutmeg_windows { { mode ""} } {
	
	# mode  ??
	# - reRun - re runs the simulation saving the current traces vectors, and plotting them against the re run simulation
	# - save - simply saves all the current traces vectors to redisplay later
	
	
	#open file ???.cir.gui_settings.tcl
	set fh_settings [open "${::spicefilename}.gui_settings.tcl" w]
	puts $fh_settings "\# tclspice gui settings file - evaluated by tcl to restore the previous 'nutmeg' session"
	
	# simulation steps
	puts $fh_settings "\# saved_plots_sim_steps  $spice::steps_completed "
	
	puts $fh_settings "\# spicewish version : $::spicewishversion"

	#---------
	# lists all the vector saved
	set allSavedVectors ""
	foreach winname [all_nutmeg_toplevels] {
	    #get toplevelnum
	    regexp {.tclspice([0-9]+)} $winname match toplevelnum
	    set nodes [ .tclspice$toplevelnum\.scope.g element names ]
	    
	    if { ! [ lcontain $allSavedVectors $nodes ] } { lappend allSavedVectors $nodes }
	    
	}
	puts $fh_settings "set ::OLD_plots $allSavedVectors"

	#---------
	#save all window positions as tcl statements
	foreach winname [all_nutmeg_toplevels] {
	    
	    puts $fh_settings "\n\n\#DATA FOR WINDOW $winname"
	    
	    #get toplevelnum
	    regexp {.tclspice([0-9]+)} $winname match toplevelnum
	    
	    #save to restore the toplevel counter
	    puts $fh_settings "set ::toplevel_count \$::toplevel_count "

	    # don't save traces with "_OLD" 
	    
	    # at moment saving the curent none _OLD traces, and making _OLD plot for that trace
	    # this re work if to save graph with out the re plots
	    set trace_list [ .tclspice$toplevelnum\.scope.g element names ]
	    set clean_trace_list {}
	    
	    foreach trace $trace_list { 
		puts " trace : $trace"
		
		if { $mode == "reRun" } {
		    if { [ regexp {_OLD} $trace ] != 1 } { 
			lappend clean_trace_list $trace  
			lappend clean_trace_list $trace\_OLD
		    }
		}
		
		if {$mode == "save" } {
		    lappend clean_trace_list $trace
		}
		
	    }
	    puts $fh_settings "plot { $clean_trace_list  }"
	    
	    # save the old plot list to a global variable, so that it can be read when the trace selection box is loaded
	    set OLD_plotList { } 
	    foreach trace $clean_trace_list {
		if { [ regexp {_OLD} $trace ]  } { 
		    lappend OLD_plotList $trace
		}
	    }
	    
	    puts $fh_settings "set ::OLD_plotList(.tclspice\[expr \$::toplevel_count - 1\]) { $OLD_plotList } "
	    
	    # save title of graph
	    set graph_name [wm title $winname]
	    
	    if { $mode == "reRun" } {
		if { [regexp {rerun([0-9]+)} $graph_name match rerun_value] == 1 } { 
		    set reRun_number [ expr $rerun_value + 1]
		    set start [ string first " - " $graph_name ]
		    set graph_name [ string range $graph_name [ expr $start + 3] end ]
		    set graph_name "rerun$reRun_number - $graph_name  "	
		} else {
		    set reRun_number 1
		    set graph_name "rerun$reRun_number -  $graph_name "
		} 
	    }
	    
	    # use [expr \$::toplevel_count - 1\]  because procedure plot increments the toplevel_count at the end
	    
	    puts $fh_settings "wm title .tclspice\[expr \$::toplevel_count - 1\] \" $graph_name\""
	    
	    # save the measurment
	    puts $fh_settings "set ::graph_dx(.tclspice\[expr \$::toplevel_count - 1\]) $::graph_dx(.tclspice$toplevelnum)" 
	    puts $fh_settings "set ::graph_dy(.tclspice\[expr \$::toplevel_count - 1\]) $::graph_dy(.tclspice$toplevelnum)" 
	    puts $fh_settings "set ::graph_x1(.tclspice\[expr \$::toplevel_count - 1\]) $::graph_x1(.tclspice$toplevelnum)" 
	    puts $fh_settings "set ::graph_y1(.tclspice\[expr \$::toplevel_count - 1\]) $::graph_y1(.tclspice$toplevelnum)" 
	    puts $fh_settings "set ::graph_x2(.tclspice\[expr \$::toplevel_count - 1\]) $::graph_x2(.tclspice$toplevelnum)" 
	    puts $fh_settings "set ::graph_y2(.tclspice\[expr \$::toplevel_count - 1\]) $::graph_y2(.tclspice$toplevelnum)" 
	    
	    # save trace place suff	
	    puts $fh_settings ""
	    puts $fh_settings "set ::trace_place_selected(.tclspice\[expr \$::toplevel_count - 1\]\.scope.g)  $::trace_place_selected(.tclspice$toplevelnum\.scope.g) "
	    
	    # not quite right because if trace place turned on then off again values not saved to file 
	    
	    # if trace place been used 
	    if { $::trace_place_selected(.tclspice$toplevelnum\.scope.g) } {
		
		puts $fh_settings "TracePlace .tclspice\[expr \$::toplevel_count - 1\]"

		# save the list of traces for each slot
		for {set col_cnt 0 } {$col_cnt <= $::columns} {incr col_cnt } {
		    for {set row_cnt 0} { $row_cnt <= [ expr (pow(2, $col_cnt) -1)  ] } {incr row_cnt } {
			if { $::slot_trace_list(.tclspice$toplevelnum\.scope.tp.ft.tracePlaceGrid.f_$col_cnt\_$row_cnt.b) != "" } {
			    puts $fh_settings "set ::slot_trace_list(.tclspice\[expr \$::toplevel_count - 1\]\.scope.tp.ft.tracePlaceGrid.f_$col_cnt\_$row_cnt\.b)  \"$::slot_trace_list(.tclspice$toplevelnum\.scope.tp.ft.tracePlaceGrid.f_$col_cnt\_$row_cnt.b)\" "	 
			} 
		    }
		}
		
	    
		# saves the dimensions of each slot
		for {set row_cnt 0} { $row_cnt <= [ expr (pow(2, $col_cnt) -1)  ] } {incr row_cnt } {
		    puts $fh_settings "\grid rowconfigure .tclspice\[expr \$::toplevel_count - 1\]\.scope.tp.ft.tracePlaceGrid $row_cnt -minsize  [grid rowconfigure  .tclspice$toplevelnum\.scope.tp.ft.tracePlaceGrid $row_cnt -minsize ] "
	    }
		
		# enables the selected slot
		set slot_location [ TracePlace_active_slot  .tclspice$toplevelnum\.scope.tp.ft.tracePlaceGrid ]
		if { $slot_location != "" } { 
		    puts $fh_settings "\TracePlace_selected_slot .tclspice\[expr \$::toplevel_count - 1\]\.scope.tp.ft.tracePlaceGrid.f_[lindex $slot_location 0]\_[lindex $slot_location 1].b " 
		}
	    }
	    
	    # saves the geometry of the window
	    set geom [winfo geometry $winname]
	    puts $fh_settings "wm geometry .tclspice\[expr \$::toplevel_count - 1\]  $geom"
	    
	    # save all the markers
	    set markerlist [$winname.scope.g marker names]
	    foreach marker $markerlist {
		puts $fh_settings ".tclspice\[expr \$::toplevel_count - 1\].scope.g marker create text -name $marker \
                                                    -coords \{ [$winname.scope.g marker cget $marker -coords]\} \
                                                    -text  \"[$winname.scope.g marker cget $marker -text]\" \
                                                    -anchor [$winname.scope.g marker cget $marker -anchor] \
                                                    -background [$winname.scope.g marker cget $marker -background]"	    
	}
	    
	    # set up a list of traces append here - rest of routine needs to be after
	    set index 0
	    set tracelist [$winname.scope.g element names]
	    foreach trace $tracelist {
		
		if { [regexp {_OLD} $trace ] } { continue }  ;# - first time simulation re run
		
		spice_return_trace_vectors .tclspice$toplevelnum\.scope.g $trace
		
		blt::vector create saved_plot_X$index
		blt::vector create saved_plot_Y$index
		
		saved_plot_X$index set temp_vector_X
		saved_plot_Y$index set temp_vector_Y
		
		incr index
	    }
	    
	    # need this to be after loop for all graphs
	    # writing same things opening the file twice
	    
	    set fh_oldplot   [open "${::spicefilename}.gui_plots.tcl" w]
	    
	    #save all the current traces from graph  to _OLD
	    set tracelist [$winname.scope.g element names]
	    set index 0
	    foreach trace $tracelist {
		
		if { [regexp {_OLD} $trace ] } { continue }  ;# - first time simulation re run		
		
		puts $fh_oldplot " "
		
		blt::vector create tempSaveX
		blt::vector create tempSaveY
		
		tempSaveX set saved_plot_X$index
		tempSaveY set saved_plot_Y$index
		
		puts $fh_oldplot "#$trace\_OLD_X : $tempSaveX(:) "
		puts $fh_oldplot "#$trace\_OLD_Y : $tempSaveY(:) "
		
		blt::vector destroy tempSaveX
		blt::vector destroy tempSaveY
		
		blt::vector destroy saved_plot_X$index
		blt::vector destroy saved_plot_Y$index
		
		incr index
	    }	
	}
	close $fh_settings
	close $fh_oldplot    
    }
    
    #--------------------------------------------------------------------------------------------------
    
    
    #------------------------------------------------------------------------------------------------------
    # creates a progress bar 
    
    proc progress_bar { w {value "" } } {
	
	if {$value == ""} {
	    pack [canvas $w  -width 100 -height 15 -relief sunken]
	    $w create rectangle 1 1 5 15 -fill green -tags {bar} 
	} else {
	    $w coords bar 1 1 $value 15
	}
    }
    
    #------------------------------------------------------------------------------------------------
    # proc passed number of setps to run before halting
    
    proc spice_run_steps {pre_run_steps { progressBar "" } } {

	# starts spice
	if {$::spice_run == 1} {
	    if { [$spice::steps_completed] > $pre_run_steps } { return }	
	    spice::bg resume
	} else {	
	    set ::spice_run 1
	    spice::bg run
	}
	
	# progress bar
	if {$progressBar != "" } {
	    
	    # check if already packed
	    if {[ winfo exists .control_butts.progressBar] } {
		pack .control_butts.progressBar 
		progress_bar .control_butts.progressBar.bar 5
		
	    } else {
		pack [frame .control_butts.progressBar ]
		pack [label .control_butts.progressBar.label -text "re simulating"]
		progress_bar .control_butts.progressBar.bar
		update
	    }
	}
    
	set time 0 
	
	while { $time < $pre_run_steps } {
	    sleep 1
	    set time $spice::steps_completed
	    if {$progressBar != "" } { progress_bar .control_butts.progressBar.bar [ expr (($time + 0.001) / $pre_run_steps) * 100 ] }
	    update
	}	
	spice::halt
	pack forget .control_butts.progressBar
	
    }
    
    #--------------------------------------------------------------------------------------------------------
    # loads all the scopes that are saved to file
    
    proc restore_all_nutmeg_windows { } {
    
	# previous simulations run time
	set sim_time [open "${::spicefilename}.gui_settings.tcl" r]
	gets $sim_time re_simulation_time
	gets $sim_time re_simulation_time
	close $sim_time
	regexp  { ([0-9\.\-e]+)}  $re_simulation_time re_simulation_time   
	
	# kills all exsisting scope windows
	foreach window [ all_nutmeg_toplevels ] {
	    destroy $window

	    # need to kill vectors as well 
	}
	
	spice_run_steps $re_simulation_time progress

	# spice_run_untill $re_simulation_time progress
	
	source "${::spicefilename}.gui_settings.tcl"
	source "${::spicefilename}.gui_plots.tcl"
	
}
    
    #-------------------------------------------------------------------------------------------
    #- returns all the "tclspice??" toplevel window names
    
    proc all_nutmeg_toplevels { } {
	
	set returnlist ""

	foreach winname [winfo children .] {
	    
	    if {  [ regexp {.tclspice[0-9]+} $winname ] } {
		#found nutmeg type toplevel
		lappend returnlist $winname
	} 	
	}
	
	return $returnlist
    }

    #---------------------------------------------------------------------------------------------------------------
    
    ##########################################################################
    # zoom controls
    #
    # Filched from the BLT Demos. May re-write for speed
    ##########################################################################
    
    proc y_axis_control { start finish window } {
	global zoomInfo
	
	regexp {.tclspice([0-9]+)} $window match toplevelnum
	set graph  ".tclspice$toplevelnum\.scope.g"
	
	Zoom1:1 $graph no_label
	
	# saves current settings
	set cmd {}
	foreach margin { xaxis yaxis x2axis y2axis } {	
	    foreach axis [$graph $margin use] {
		set min [$graph axis cget $axis -min] 
		set max [$graph axis cget $axis -max]
		set c [list $graph axis configure $axis -min $min -max $max]
		append cmd "$c\n"
	    }
	}
	set zoomInfo($graph,stack) [linsert $zoomInfo($graph,stack) 0 $cmd]
	
	set Y_limits [ $graph axis limits y ]
	set Y_limits_bot [lindex $Y_limits 0]
	set Y_limits_top [lindex $Y_limits 1]
	
	if { $Y_limits_bot < 0 } { 
	    set Y_limits_bot_t    [ expr ( $Y_limits_bot * -1) ]
	} else { 
	    set Y_limits_bot_t   $Y_limits_bot 	
	}   

	set scale [ expr ( $Y_limits_top + $Y_limits_bot_t ) /100.0]
	
	$graph yaxis configure -min [ expr $Y_limits_bot + ($start * $scale) ]
	$graph yaxis configure -max [ expr $Y_limits_bot + ($finish * $scale) ]
    }
    
    #---------------------
    
    proc InitStack { graph } {
	
	global zoomInfo
	set zoomInfo($graph,interval) 100
	set zoomInfo($graph,afterId) 0
	set zoomInfo($graph,A,x) {}
	set zoomInfo($graph,A,y) {}
	set zoomInfo($graph,B,x) {}
	set zoomInfo($graph,B,y) {}
	set zoomInfo($graph,stack) {}
	set zoomInfo($graph,corner) A
    }
    
    #--------------------
    proc ZoomStack { graph {start "ButtonPress-1"} {reset "ButtonRelease-3"} } {
	
	global zoomInfo zoomMod

	InitStack $graph
	
	if { [info exists zoomMod] } {
	    set modifier $zoomMod
	} else {
	    set modifier ""
	}
	bind bltZoomGraph <${modifier}${start}> { 
	    spicewish::SetZoomPoint %W %x %y 
	}
	
	bind bltZoomGraph <${modifier}${reset}> {  
	    if { [%W inside %x %y] } { 
		spicewish::ResetZoom %W 
	    }
	}
	AddBindTag $graph bltZoomGraph 
    }
    
    #--------------------
    proc DestroyZoomTitle { graph } {
	global zoomInfo
	
	if { $zoomInfo($graph,corner) == "A" } {
	    catch { $graph marker delete "zoomTitle" }
	}
    }
    
    #--------------------
    proc Zoom1:1 { graph {noTitle ""}} {
	global zoomInfo disp_zoom_level
	
	$graph axis configure x -min {} -max {}
	$graph axis configure y -min {} -max {}
	$graph axis configure x2 -min {} -max {}
	$graph axis configure x2 -min {} -max {}
	InitStack $graph
	set disp_zoom_level 0
	if { $noTitle == "" } {ZoomTitleLast $graph }
	update
	if { $noTitle == "" } { after 2000 "spicewish::DestroyZoomTitle $graph" }
    }
    
    #--------------------
    proc PopZoom { graph } {
	global zoomInfo disp_zoom_level
	
	set zoomStack $zoomInfo($graph,stack)
	
	if { [llength $zoomStack] > 0 } {
	    set cmd [lindex $zoomStack 0]
	    set zoomInfo($graph,stack) [lrange $zoomStack 1 end]
	    eval $cmd
	    ZoomTitleLast $graph
	    #	busy hold $graph
	    update
	    after 2000 "spicewish::DestroyZoomTitle $graph"
	    #	busy release $graph
	} else {
	    catch { $graph marker delete "zoomTitle" }
	    
	}
	set disp_zoom_level [expr [llength $zoomInfo($graph,stack)] ]
    }
    
    # Push the old axis limits on the stack and set the new ones
    
    #-----------------------------------------------------------------------
    
    proc PushZoom { graph } {
	global zoomInfo disp_zoom_level
	
	eval $graph marker delete [$graph marker names "zoom*"]
	if { [info exists zoomInfo($graph,afterId)] } {
	    after cancel $zoomInfo($graph,afterId)
	}
	
	set x1 $zoomInfo($graph,A,x)
	set y1 $zoomInfo($graph,A,y)
	set x2 $zoomInfo($graph,B,x)
	set y2 $zoomInfo($graph,B,y)
	
	if { ($x1 == $x2) || ($y1 == $y2) } { 
	    # No delta, revert to start
	    return
	}
	
	# saves current settings
	set cmd {}
	foreach margin { xaxis yaxis x2axis y2axis } {
	    
	    foreach axis [$graph $margin use] {
		set min [$graph axis cget $axis -min] 
		set max [$graph axis cget $axis -max]
		set c [list $graph axis configure $axis -min $min -max $max]
		append cmd "$c\n"
	    }
	}
	set zoomInfo($graph,stack) [linsert $zoomInfo($graph,stack) 0 $cmd]
	
	#   busy hold $graph 
	# This update lets the busy cursor take effect.
	update

	foreach margin { xaxis x2axis } {
	    foreach axis [$graph $margin use] {
		set min [$graph axis invtransform $axis $x1]   
		set max [$graph axis invtransform $axis $x2]
		if { $min > $max } { 
		    $graph axis configure $axis -min $max -max $min
		} else {
		    $graph axis configure $axis -min $min -max $max
		}
	    }
	}
	foreach margin { yaxis y2axis } {
	    foreach axis [$graph $margin use] {
		set min [$graph axis invtransform $axis $y1]
		set max [$graph axis invtransform $axis $y2]
		if { $min > $max } { 
		    $graph axis configure $axis -min $max -max $min
		} else {
		    $graph axis configure $axis -min $min -max $max
		}
	    }
	}
	# This "update" forces the graph to be redrawn
	set disp_zoom_level [expr [llength $zoomInfo($graph,stack)] ]
	update
	
	#   busy release $graph
    }
    
    #--------------------
    
    #
    # This routine terminates either an existing zoom, or pops back to
    # the previous zoom level (if no zoom is in progress).
    #

    #--------------------
    proc ResetZoom { graph } {
	global zoomInfo 

	if { ![info exists zoomInfo($graph,corner)] } {
	    InitStack $graph 
	}
	eval $graph marker delete [$graph marker names "zoom*"]
	
	if { $zoomInfo($graph,corner) == "A" } {
	    # Reset the whole axis
	    PopZoom $graph
	    
	
	} else {
	    global zoomMod
	    
	    if { [info exists zoomMod] } {
		set modifier $zoomMod
	    } else {
		set modifier "Any-"
	}
	    set zoomInfo($graph,corner) A
	    bind $graph <${modifier}Motion> { }
	}
    }

    #--------------------
    
    #option add *zoomTitle.font	  -*-helvetica-medium-R-*-*-18-*-*-*-*-*-*-* 
    #option add *zoomTitle.shadow	  yellow4
    #option add *zoomTitle.foreground  yellow1
    #option add *zoomTitle.coords	  "-Inf Inf"
    
    #--------------------
    proc ZoomTitleNext { graph } {
	global zoomInfo disp_zoom_level
	set level [expr [llength $zoomInfo($graph,stack)] + 1]
	
	if { [$graph cget -invertxy] } {
	    set coords "-Inf -Inf"
	} else {
	    set coords "-Inf Inf"
	}
	$graph marker create text -name "zoomTitle" -text "Zoom #$level" \
	    -coords $coords -bindtags "" -anchor nw
    }
    
    #--------------------
    proc ZoomTitleLast { graph } {
	global zoomInfo
	
	set level [llength $zoomInfo($graph,stack)]
	if { $level > 0 } {
	    $graph marker create text -name "zoomTitle" -anchor nw \
		-text "Zoom #$level" 
	}
	if { $level == 0 } {
	    $graph marker create text -name "zoomTitle" -anchor nw \
		-text "Zoom 1:1" 
	}
    }
    
    #--------------------
    proc SetZoomPoint { graph x y } {
	global zoomInfo zoomMod
	if { ![info exists zoomInfo($graph,corner)] } {
	    InitStack $graph
	}
	GetCoords $graph $x $y $zoomInfo($graph,corner)
	if { [info exists zoomMod] } {
	    set modifier $zoomMod
	} else {
	    set modifier "Any-"
	}
	if { $zoomInfo($graph,corner) == "A" } {
	    if { ![$graph inside $x $y] } {
		return
	    }
	    # First corner selected, start watching motion events
	    
	    #MarkPoint $graph A
	    ZoomTitleNext $graph 
	    
	    bind $graph <${modifier}Motion> { 
		spicewish::GetCoords %W %x %y B
		#MarkPoint $graph B
		spicewish::Box %W
	    }
	    set zoomInfo($graph,corner) B
	} else {
	    # Delete the modal binding
	    bind $graph <${modifier}Motion> { }
	    spicewish::PushZoom $graph 
	    set zoomInfo($graph,corner) A
	}
    }
    
    #--------------------
    
    #option add *zoomTitle.anchor		nw
    #option add *zoomOutline.dashes		4	
    #option add *zoomOutline.lineWidth	2
    #option add *zoomOutline.xor		yes
    
    #--------------------
    proc MarchingAnts { graph offset } {
	global zoomInfo
	
	incr offset
	if { [$graph marker exists zoomOutline] } {
	    $graph marker configure zoomOutline -dashoffset $offset    -dashes 4 -linewidth 2 -xor yes
	    set interval $zoomInfo($graph,interval)
	    set id [after $interval [list spicewish::MarchingAnts $graph $offset]]
	    set zoomInfo($graph,afterId) $id
	}
    }
    
    #--------------------
    proc GetCoords { graph x y index } {
	global zoomInfo
	if { [$graph cget -invertxy] } {
	    set zoomInfo($graph,$index,x) $y
	    set zoomInfo($graph,$index,y) $x
	    
	} else {
	    set zoomInfo($graph,$index,x) $x
	    set zoomInfo($graph,$index,y) $y
	}
    }
    
    #--------------------
    proc AddBindTag { graph name } {
	set oldtags [bindtags $graph]
	if { [lsearch $oldtags $name] < 0 } {
	    bindtags $graph [concat $name $oldtags]
	}
    }
    
    #--------------------
    proc Box { graph } {
	global zoomInfo 
	
	# select which yaxis to take the measurments
	# !!!!!!!!!!!!!! need a global variable for when the trace place is selected but returned to normal graph
	if {  $::trace_place_selected($graph) } {
	    # trace place grid active
	    set m_yaxis "y2axis" 
	} else {
	    set m_yaxis "yaxis"
	}
	
	
	if { $zoomInfo($graph,A,x) > $zoomInfo($graph,B,x) } { 
	    set x1 [$graph xaxis invtransform $zoomInfo($graph,B,x)]
	    set y1 [$graph yaxis invtransform $zoomInfo($graph,B,y)]
	    set x2 [$graph xaxis invtransform $zoomInfo($graph,A,x)]
	    set y2 [$graph yaxis invtransform $zoomInfo($graph,A,y)]
	    
	    set my1 [$graph $m_yaxis invtransform $zoomInfo($graph,B,y)]
	    set my2 [$graph $m_yaxis invtransform $zoomInfo($graph,A,y)]
	
	} else {
	    set x1 [$graph xaxis invtransform $zoomInfo($graph,A,x)]
	    set y1 [$graph yaxis invtransform $zoomInfo($graph,A,y)]
	    set x2 [$graph xaxis invtransform $zoomInfo($graph,B,x)]
	    set y2 [$graph yaxis invtransform $zoomInfo($graph,B,y)]
	    
	    set my1 [$graph $m_yaxis invtransform $zoomInfo($graph,A,y)]
	    set my2 [$graph $m_yaxis invtransform $zoomInfo($graph,B,y)]
	}
	set coords { $x1 $y1 $x2 $y1 $x2 $y2 $x1 $y2 $x1 $y1 }
	if { [$graph marker exists "zoomOutline"] } {
	    $graph marker configure "zoomOutline" -coords $coords        -dashes 4 -linewidth 2 -xor yes
	} else {
	    set X [lindex [$graph xaxis use] 0]
	    set Y [lindex [$graph yaxis use] 0]
	    $graph marker create line -coords $coords -name "zoomOutline" \
		-mapx $X -mapy $Y
	    set interval $zoomInfo($graph,interval)
	    set id [after $interval [list spicewish::MarchingAnts $graph 0]]
	    set zoomInfo($graph,afterId) $id
	}
        
	regexp  {(.[0-9A-z]+)} $graph window_name
	set ::graph_dx($window_name) [expr ($x2 - $x1)]
	set ::graph_dy($window_name) [expr ($my2 - $my1)]
	set ::graph_x1($window_name) $x1
	set ::graph_y1($window_name) $my1
	set ::graph_x2($window_name) $x2
	set ::graph_y2($window_name) $my2
    }
    
    ### End of software theft
    

    
    ##########################################################################
    # trace and place
    #
    #
    ##########################################################################

    
    # procedure that calls traceplace form menu pass the %w 
    # then calls procedure active button if this is passed a value then this one will become active
    
    #------------------------------------------------------------------------------------------
    # returns to normal graph from trace place grid 
    
    proc NormalGraph { window } {
	
	# un packs the trace and place widget
	pack forget $window.scope.tp.l
	pack forget $window.scope.tp.ft
	$window.scope.tp configure -width 1  
	
	# un packs the trace and place information bar at bottom
	pack forget $window.tracePlaceInfoBar.fakeGraph 
	pack forget $window.tracePlaceInfoBar.legends 
	$window.tracePlaceInfoBar configure -height 1 
	
	# turns off all the legenfs relief
	foreach trace [ $window.scope.g element names ] {
	    $window.scope.g element configure $trace -labelrelief flat 
	    $window.scope.g element configure $trace -hide 0 
	}

	$window.scope.g yaxis configure -min "" -max "" -hide 0
	$window.scope.g y2axis configure -hide 1
	
	# turn off the 
	spice_update_traces $window.scope.g
	
    }
    
    #-----------------------------------------------------------------------------------------------------------------
    # creates the trace and place grid 
    # re packs if already created
    
    proc TracePlace { window } {
	global columns rows max_traces_per_slot total_hei  desired_width desired_height
	
	# unpacks the trace place grid
	if {$::trace_place_selected($window.scope.g) != 1} {
	    NormalGraph $window
	    $window.scope.g y2axis configure -hide 1
	    $window.scope.g yaxis configure -hide 0 
	    return 
	}
	
	set window_clean $window
	set window "$window\.scope.tp" 
	$window_clean.scope.g yaxis configure -hide 1
	$window_clean.scope.g y2axis configure -hide 0
	#trace place info bar , bottom. if already created once, then just re pack 
	if { [ winfo exists $window\.l ] == 1 } {
	    
	    # re packs the trace and place slots widget 
	    pack $window\.l  -side bottom -fill both
	    pack $window\.ft -side top  -expand 1 -fill y
	    
	    # re packs the trace and place information bar at bottom
	    pack $window_clean.tracePlaceInfoBar.fakeGraph -side left
	    pack $window_clean.tracePlaceInfoBar.legends -side left
	    
	    # refreshes tarce and place grid
	    TracePlace_update $window_clean
	    
	    return
	}  
	
	
	#----
	#--------
	# construction in progress
	
	# creates a fake graph that is never seen, so that its legend can be used for the trace and place information bar
	set fakeGraph_w [ blt::graph $window_clean.tracePlaceInfoBar.fakeGraph ]    
	$fakeGraph_w configure -height 20 -width 20 -plotrelief flat  
	$fakeGraph_w xaxis configure -hide 1
	$fakeGraph_w yaxis configure -hide 1
	$fakeGraph_w legend configure -position $window_clean.tracePlaceInfoBar.legends -columns 1 
	
	pack  $fakeGraph_w -side left
	pack  $window_clean.tracePlaceInfoBar.legends -side left
	
	# graph legend active on button 3
	$fakeGraph_w legend bind all <Button-1> { %W legend activate [%W legend get current] }
	$fakeGraph_w legend bind all <ButtonRelease-1> {  %W legend deactivate [%W legend get current]}
	
	# creates the drag and drop packet for each of the plots in the trace place info bar
	blt::drag&drop source   $window_clean.tracePlaceInfoBar.legends  -packagecmd {spicewish::make_package %t %W } -button 1
	set token [blt::drag&drop token  $window_clean.tracePlaceInfoBar.legends  -activebackground blue ]
	pack [ label $token.label -text "" ]
	
	$window_clean.tracePlaceInfoBar.fakeGraph element create "" -symbol ""
	
	#----------
	#-------
	
	set columns 3  ;#- will give 2^rows of total choices for trace positons.
	set rows [expr pow(2, $columns) ] ;# -this many rows (see above) 
	set min_row_hei  1           ; #- cant click a single element smaller than this  (but still can get smaller than this is squashed)
	set max_traces_per_slot 8 
	
	
	#- call procedure to get the wm height of the graph
	#- wm geometry .tclspice 1
	#- perform scan to get height - minus 24 for title plus fotter included padding of graph??
	#- set desired height to this 
	
	#    global columns rows
	pack [ label $window.l -text "" -borderwidth 4 ] -side bottom -fill both    
	pack [ frame $window.ft -width 50  ]   -side top  -expand 1 -fill y
	pack [ frame $window.ft.tracePlaceGrid -borderwidth 4 ]   -side left  -expand 1 -fill y
	
	
	# set desired_height 70
	# set desired_width 20           ; #-initial width of the panel - can still dynamically resize the width
	
	scan [winfo geometry $window.ft.tracePlaceGrid ] "%dx%d+%d+%d" desired_width desired_height xpos ypos
	set total_hei [expr  int( ( $desired_height / $rows)* $rows )]
	
	set window "$window.ft.tracePlaceGrid"
	set ::window $window
	
	for {set columns_cnt 0 } {$columns_cnt <= $columns} {incr columns_cnt } {
	    
	    set  row_span_holder  [ expr  pow(2, $columns) / pow(2, $columns_cnt) ]
	    set row_span_holder [ expr int($row_span_holder) ]
	    
	    
	    for {set row_cnt 0} { $row_cnt <= [ expr (pow(2, $columns_cnt) - 1)   ] } {incr row_cnt } {
		
		#  set slotnum [ slotnum_FROM_column_gridrow $columns_cnt $row_cnt $row_span_holder]
		set slotnum [ expr int (int (  [expr  $row_cnt* $row_span_holder] / [expr  pow(2, ($columns - $columns_cnt)) ])   + [expr  int (pow(2, $columns_cnt))]) ] 
		
		# create a frame for each slot to hold the button and the canvas
		set slot_frame [ frame $window.f_$columns_cnt\_$row_cnt ]
		
		
		# creates button/slot
		set button_path [button $window.f_$columns_cnt\_$row_cnt.b -padx 3 -pady 0  -activebackground lightgrey -command "spicewish::TracePlace_selected_slot  $window.f_$columns_cnt\_$row_cnt.b "]
		
		# creates a clean trace list, for all the traces associated with that slot 
		set ::slot_trace_list($button_path) {}
		
		# sets button to be a target for drag and drop packet 
		# - when active adds trace to slots list
		blt::drag&drop target $button_path handler string { 
		    append ::slot_trace_list(%W) "%v "
		    spicewish::TracePlace_selected_slot %W update 
		}
		
		
	    # creates a drag drop packet so that all the slots traces can be moved
		blt::drag&drop source   $button_path  -packagecmd {  spicewish::make_package %t %W tracePlaceGrid } -button 1
		set token2 [blt::drag&drop token   $button_path  -activebackground blue ]
		pack [ label $token2.label -text "" ]
		
		
		# button bindings
		bind $button_path <ButtonPress-4> { regexp  {(.[0-9A-z]+)} %W temp; spicewish::TracePlace_wheel_move up $temp.scope.tp.ft.tracePlaceGrid}
		bind $button_path <Control-ButtonPress-1> { regexp  {(.[0-9A-z]+)} %W temp; spicewish::TracePlace_wheel_move up $temp.scope.tp.ft.tracePlaceGrid }
		bind $button_path <ButtonPress-5> { regexp  {(.[0-9A-z]+)} %W temp; spicewish::TracePlace_wheel_move "down" $temp.scope.tp.ft.tracePlaceGrid }
		bind $button_path <Control-ButtonPress-3> { regexp  {(.[0-9A-z]+)} %W temp; spicewish::TracePlace_wheel_move "down" $temp.scope.tp.ft.tracePlaceGrid }
		
		
		# create a canvas in slot to display included traces
		set canvas_path [ canvas $window.f_$columns_cnt\_$row_cnt.c -background grey -width 2 -height 10 ]
		
		grid configure $window.f_$columns_cnt\_$row_cnt -row [ expr $row_cnt * $row_span_holder  ]   -column [ expr ($columns - $columns_cnt) * $max_traces_per_slot ] -sticky "nsew" -rowspan $row_span_holder
		
		# packs the button into the slots frame on
		pack $button_path -side right -fill both -expand 1
		
		# packs the canvas into the slot 
		pack $canvas_path -side left -fill y 
		
		grid columnconfigure $window [expr $columns_cnt * $max_traces_per_slot] -weight 1
		grid rowconfigure $window $row_cnt -weight 1
	    }
	}
	
	# can not set the default size here because winfo can not detect the size of gid widget because of delay on creation
	
	
	# Fill in all row sizes to the default
	for {set rows_cnt  0 } {  $rows_cnt < $rows } {  incr rows_cnt} {
	    set row_heights($rows_cnt) 10 ;#[expr  $total_hei / $rows]					
	    grid rowconfigure $window $rows_cnt -minsize $row_heights($rows_cnt)
	}
	
	# error when the trace is first made scales out of the window size
	# but if resize window stays within limits
	scan [wm geometry $window_clean ] "%dx%d+%d+%d" width total_hei xpos ypos
	wm geometry $window_clean "[expr $width+1]x$total_hei\+$xpos\+$ypos"
	
    }
    
    #------------------------------------------------------------------------------------------------------------------
    # refereshes the trace and place grid 
    
    proc TracePlace_update { window } {
	
	# updates all the traces
	# called when the traces on screen are updated added / removed
	
	# retrieve the name of the fake graph
	regexp  {(.[0-9A-z]+)} $window window_clean
	set graph_w "$window_clean.scope.g"
	set tracePlace_w "$window_clean.scope.tp.ft.tracePlaceGrid"
	
	# returns if trace place grid not active 
	if { $::trace_place_selected($graph_w) == 0 } { return } 
	
	set slot [TracePlace_active_slot $tracePlace_w ]
	if { $slot == "" } { return }
	
	TracePlace_selected_slot $tracePlace_w\.f_[lindex $slot 0]\_[lindex $slot 1]\.b
	
    }
    
    
    #----------------------------------------------------------------------------------------------------------
    # 
    
    proc TracePlace_selected_slot { window {args ""} } { 
	
	# retrieve the name of the fake graph
	regexp  {(.[0-9A-z]+)} $window window_clean
	set fakeGraph_w "$window_clean.tracePlaceInfoBar.fakeGraph"
	set tracePlace_w "$window_clean.scope.tp.ft.tracePlaceGrid"
    
	regexp {Grid.f_([0-9]+)_([0-9]+)} $window match active_col active_row 
	
	set dropped_slot_row $active_row
	set dropped_slot_col $active_col
	
	set startTime [ clock seconds ]

	# highlight the selected button green turn the previously selected button back to grey
	for {set columns_cnt 0 } {$columns_cnt <= $::columns} {incr columns_cnt } {
	    for {set row_cnt 0} { $row_cnt <= [ expr (pow(2, $columns_cnt) -1)  ] } {incr row_cnt } {
		
		if { [$tracePlace_w.f_$columns_cnt\_$row_cnt.b cget -background] == "green" } { 
		    
		    # case where a packet is been dropped on a slot that is not active, so exits not displaying list
		    if { ($args == "update") && 
			 ( ($active_col != $columns_cnt) || ($active_row != $row_cnt))   } { 
			
			# case where packet is moved from current slot to another, need to redisplay new slot list 
			set active_col $columns_cnt
			set active_row $row_cnt
			continue 
		    }
		    
		    # turns off the highlight 'green' colour
		    $tracePlace_w.f_$columns_cnt\_$row_cnt.b configure -background \#dcdcdc -activebackground lightgrey
		    continue
		}
		
	    }
	}
	
	
	# search through all the other slot lists to make sure that the traces are not duplicated 
	# - error trapping when a trace is moved from one slot to another
	# - restores the slot to its default colour
	for {set columns_cnt 0 } {$columns_cnt <= $::columns} {incr columns_cnt } {
	    for {set row_cnt 0} { $row_cnt <= [ expr (pow(2, $columns_cnt) -1)  ] } {incr row_cnt } {
		
		# returns all the slots to there default grey colours
		$tracePlace_w.f_$columns_cnt\_$row_cnt.b configure -background \#dcdcdc -activebackground lightgrey
		
		# continues if current slot 
		if { ($dropped_slot_row == $row_cnt) && ($dropped_slot_col == $columns_cnt) } {  continue }
		foreach trace   $::slot_trace_list($tracePlace_w.f_$dropped_slot_col\_$dropped_slot_row.b) {
		    
		    if {  [ lcontain $::slot_trace_list($tracePlace_w.f_$columns_cnt\_$row_cnt.b) $trace ] } {
			
			# -- nasty hack just need command that delete element form a string---
			set cleanList {}
			foreach list $::slot_trace_list($tracePlace_w.f_$columns_cnt\_$row_cnt.b) {
			    if { $trace != $list } { append cleanList "$list "}
			}
			set ::slot_trace_list($tracePlace_w.f_$columns_cnt\_$row_cnt.b) {}
			set ::slot_trace_list($tracePlace_w.f_$columns_cnt\_$row_cnt.b) $cleanList
		    #------------------------------------------------------------------------------------------
		    }
		}
		
	    }
	}
	
	# highlights all the decendants of the selected slot blue, produces list of slots   
	set activated_slots_list { } 
	set tr $active_row  
	for {set col_cnt 0  } {$col_cnt <= [ expr $::columns - $active_col] } {incr col_cnt } {
	    for {set row_cnt 0} { $row_cnt <= [ expr (pow(2, $col_cnt) -1)  ] } {incr row_cnt } {
		
		append activated_slots_list "[ expr $col_cnt + $active_col]\_[ expr $tr + $row_cnt ] "
		$tracePlace_w.f_[ expr $col_cnt + $active_col]\_[ expr $tr + $row_cnt ].b configure -background lightblue  -activebackground lightgrey
	    }
	    set tr [ expr $tr * 2 ]
	}
  
	# highlights the selected slot green 
	$tracePlace_w.f_$active_col\_$active_row.b configure -background green -activebackground lightgreen
	
	# re packs the trace and place information bar at bottom, just incase previously forget
	pack $window_clean.tracePlaceInfoBar.fakeGraph -side left
	pack $window_clean.tracePlaceInfoBar.legends -side left
	
	# clears the trace and place list at bottom of screen
	foreach trace_to_zap  [ $fakeGraph_w element names ]  { $fakeGraph_w element delete $trace_to_zap }
	
	# makes sure that all the real legend labels reliefs are flat
	# hides all the traces on the scope
	foreach trace [ $window_clean.scope.g element names ] { 
	    $window_clean.scope.g element configure $trace -labelrelief flat 
	    $window_clean.scope.g element configure $trace -hide 1
	}

	
	# display the slots list of selected traces at the bottom of screen, and in the real graphs legend
	set clean_trace_list {}
	foreach trace $::slot_trace_list($tracePlace_w.f_$active_col\_$active_row.b) {
	
	    # makes sure that the trace has not been removed from the real graph
	    if { [$window_clean.scope.g element exists  $trace] == 0 } { continue }  
	    
	    # makes sure that there is no dupliaction of traces in the list
	    if { [$fakeGraph_w element exists  $trace] } { continue }  
	    
	    # add the trace to the list at the bottom of the screen
	    $fakeGraph_w element create $trace -color [$window_clean.scope.g element cget $trace -color ]
	    
	    # highlight by relief in real legend
	    $window_clean.scope.g element configure $trace -labelrelief raised

	    append clean_trace_list "$trace "
	}
	
	# saves the cleaned up plot list
	set ::slot_trace_list($tracePlace_w.f_$active_col\_$active_row.b) {}
	set ::slot_trace_list($tracePlace_w.f_$active_col\_$active_row.b) $clean_trace_list 
	
	
	# if no traces in the slot list, puts a blank plot due to packing/update problems with fake graph legend
	if { [ llength $::slot_trace_list($tracePlace_w.f_$active_col\_$active_row.b)] == 0 }  {$fakeGraph_w  element create "" -symbol ""}
	
	
	
	# hides all the traces on the scope
	#   foreach scope_trace  [ $window_clean.scope.g element names ]  {  $window_clean.scope.g element configure $scope_trace -hide 1}
	
	
	# loops through all the activated slots and displays there traces
	# resizes the traces so that they are relative to there slots size and position
	foreach  activated_slot $activated_slots_list {
	    
	    regexp {([0-9]+)_([0-9]+)} $activated_slot match activated_slot_col activated_slot_row
	    set  active_row $activated_slot_row
	    set active_col $activated_slot_col
    
	    # resets the y axis to 0 -100 and hides the scale
	    $window_clean.scope.g axis configure y -min 0 -max 100 ;#-hide 1 ;# - set up the y axis
	    # should only call above if list length > 1
	    
	    # displays traces within slots plot list on scope, and rasies it legend
	    set max 0 
	    set min 0
	    foreach scope_trace  [ $window_clean.scope.g element names ]  { 
		if { [ lcontain $::slot_trace_list($tracePlace_w.f_$active_col\_$active_row.b) "$scope_trace" ]} {
		
		    $window_clean.scope.g element configure $scope_trace -labelrelief raised
		    $window_clean.scope.g element configure $scope_trace -hide 0  
		    
		    spice_return_trace_vectors $window_clean.scope.g $scope_trace 
		    
		    set data_list_length [ temp_vector_Y length ]
		    for { set i 0 } { $i < $data_list_length } { incr i } {
			if { [ temp_vector_Y index $i ] > $max } { set max [ temp_vector_Y index $i ]  }
			if { [ temp_vector_Y index $i ] < $min  } { set min [ temp_vector_Y index $i ]  }
		    }
		}
	    }
	
	    
	    foreach scope_trace  [ $window_clean.scope.g element names ]  { 
		if { [ lcontain $::slot_trace_list($tracePlace_w.f_$active_col\_$active_row.b) "$scope_trace" ]} {
		    
		    spice_return_trace_vectors $window_clean.scope.g $scope_trace 	
		    set data_list_length [ temp_vector_Y length ]
		    set scale_factor [ expr 100 / ($max - $min ) ]
		    
		    if { $min < 0 } { 
			set offset [ expr $min * -1   ]
		    } else {
			set offset 0 
		    }
		    
		    # retrives the size of the selected slot 
		    set dimensions [ TracePlace_slot_dimension $window $active_col $active_row ]
		    set slot_start_position [lindex $dimensions 0]
		    set slot_finish_position [lindex $dimensions 1]	    
		    set slot_scale_factor [ expr 100 / (($slot_finish_position) - ( $slot_start_position))  ]
		  
		    # -------------------
		    # ad 18/3/03 
		
		    if { 1 } {  
			temp_vector_Y expr { temp_vector_Y * $scale_factor }
			temp_vector_Y expr { temp_vector_Y + ( $offset  * $scale_factor ) }
			temp_vector_Y expr { ( temp_vector_Y / $slot_scale_factor ) + $slot_start_position }
		    } else { 
			for { set i 0 } { $i < $data_list_length } { incr i } {
			    
			    #scales against 0 -100
			    temp_vector_Y index $i [ expr ( [ temp_vector_Y index $i ] * $scale_factor)   ]
			    
			    # offset  traces < 0 
			    temp_vector_Y index $i [ expr  [ temp_vector_Y index $i ] + ( $offset  * $scale_factor )] 
			    
			    # scales against the slot dimensions
			    temp_vector_Y index $i [ expr ( [temp_vector_Y index $i] / $slot_scale_factor ) + $slot_start_position ]
			}
		    }
		   # puts " taken [ expr [ clock seconds ] - $startTime ] - $startTime - [ clock seconds ]  $scope_trace  "
		    #--------------
		    
		    temp_vector_Y dup temp2 
		    $window_clean.scope.g element configure $scope_trace -ydata $temp2(:)
		}
	    }
	}
	
	# runs through all the slots and draws  markers into the canvases
	for {set col_cnt 0 } {$col_cnt <= $::columns} {incr col_cnt } {
	    for {set row_cnt 0} { $row_cnt <= [ expr (pow(2, $col_cnt) -1)  ] } {incr row_cnt } {	    
		TracePlace_update_slot_canvas_markers $tracePlace_w $col_cnt $row_cnt
	    } 
	}
	
    }

    #--------------------------------------------------------------------------------------------------------------------------------------
    
    proc TracePlace_update_slot_canvas_markers { tracePlace_w  col_cnt row_cnt } {
	
	regexp  {(.[0-9A-z]+)} $tracePlace_w  window_clean
	
	# clean old markers
	$tracePlace_w.f_$col_cnt\_$row_cnt.c delete tracePlaceMarker
	
	# length of list 
	set list_length [ llength $::slot_trace_list($tracePlace_w.f_$col_cnt\_$row_cnt.b)]
	
	# the height of the column
	set slot_height [ winfo height $tracePlace_w.f_$col_cnt\_$row_cnt.c ]
	
	if { $list_length == 0 } { 
	    set rectangle_height $slot_height 
	} else {  
	    set rectangle_height [expr $slot_height / $list_length ] 
	}
    
	# run through the list display ing rectanlgles
	set rect_start_y 0
	set rect_finish_y 0
    
	foreach scope_trace $::slot_trace_list($tracePlace_w.f_$col_cnt\_$row_cnt.b) {
	    set rect_finish_y [expr $rect_finish_y + $rectangle_height ]
	    # places retcangle on canvas
	    $tracePlace_w.f_$col_cnt\_$row_cnt.c create rectangle 0 $rect_start_y 10 $rect_finish_y -tags tracePlaceMarker -fill [ $window_clean.scope.g element cget $scope_trace -color  ] 
	    set rect_start_y [expr $rect_start_y + $rectangle_height ]
	}
    }
    
    
    #----------------------------------------------------------------------------------------------------------------------------------
    # returns the start and finish dimensions for a given slot on trace and place
    
    proc TracePlace_slot_dimension { window active_col active_row } { 
	
	regexp  {(.[0-9A-z]+)} $window window_clean
	set fakeGraph_w "$window_clean.tracePlaceInfoBar.fakeGraph"
	set tracePlace_w "$window_clean.scope.tp.ft.tracePlaceGrid"
	
	set grid_info [grid info $tracePlace_w.f_$active_col\_0] 
	
	set count 0   
	set temp_row 0 
	set calc_height 0
	set row_span_value 0
	
	# loops down the row calculating the size of each slot
	for {set rows_cnt  [expr ( int ($::rows) / [lindex $grid_info 9]) - 1 ]  } {  $rows_cnt >= 0 } {  set rows_cnt [expr  $rows_cnt - 1]} {	
	    # retrieves the configs of the slot
	    set rows_cnt [ expr int($rows_cnt) ]
	    set grid_info [grid info $tracePlace_w.f_$active_col\_$rows_cnt] 
	    
	    # save the start height of the selected slot
	    if  { $count == $active_row } { set temp_finish $row_span_value} ;# start
	    
	    # calculates the size of the slot 
	    for {set row_span_cnt $temp_row } {$row_span_cnt < ( [lindex $grid_info 9]  + $temp_row )} {incr row_span_cnt } {	    
		set row_span_value [expr $row_span_value + [grid rowconfigure  $tracePlace_w  $row_span_cnt -minsize ] ] 
	    }
	    set temp_row  $row_span_cnt 
	    set calc_height $row_span_value
	    incr count
	    
	    # save the finish height of the selected slot
	    if  { $count == [ expr $active_row + 1 ]} { set temp_start $row_span_value} ;# finish 
	}
        
	return "[expr 100 - ( $temp_start /  [expr $calc_height /100.0] ) ] [expr 100 - ( $temp_finish / [expr $calc_height /100.0] )  ]"
    }


    #--------------------------------------------------------------------------------------------------------------------------------
    # 18/3/02 -ad
    # - 
    #
    proc sw_tracePlace_slotDimensions { } {

	set w ".tclspice1.scope.tp.ft.tracePlaceGrid"
	
	# saves the size of each row
	set rowsHeight 0
	for { set i 0 } { $i < 8 } { incr i } {
	    set rowSpan($i) [ lindex [ grid rowconfigure $w $i ] 1 ]
	    set rowsHeight [ expr $rowsHeight + $rowSpan($i) ]
	  #  puts " row : $i span : [ lindex [ grid rowconfigure $w $i ] 1 ] "
	}
	set rowsHeightScaleFactor [ expr $rowsHeight / 100.0 ]
	#puts " factor $rowsHeightScaleFactor"
	#----------
	set columns 3  ;#- will give 2^rows of total choices for trace positons.
	set rows [expr pow(2, $columns) ] ;# -this many rows (see above) 

	for {set columns_cnt 0 } {$columns_cnt  <= $columns } {incr columns_cnt  } {
	    set  row_span_holder  [ expr int( pow(2, $columns) / pow(2, $columns_cnt) ) ]
	    
	    set slotStartRow 0
	    set slotHeight 100
	    for {set row_cnt 0} { $row_cnt <= [ expr (pow(2, $columns_cnt) - 1)   ] } {incr row_cnt } {
		#
		# .tclspice1.scope.tp.ft.tracePlaceGrid.f_0_0 
		set slotsRowSpan [ lindex [ grid info $w.f_$columns_cnt\_$row_cnt ] 9 ] 
		
		#loop throught spanned rows to get total height
		set arrh $slotHeight
		for { set t $slotStartRow } { $t < ( $slotStartRow +$slotsRowSpan)  } { incr t } { 
		    set slotHeight [expr $slotHeight  - ( $rowSpan($t) / $rowsHeightScaleFactor)   ] 
		}
		#puts "$row_cnt $slotsRowSpan $slotStartRow -- $arrh $slotHeight "
		set slotStartRow [ expr $slotStartRow + $slotsRowSpan ]
		
	    }
	}
	#-----------



	
    } 


    #---------------------------------------------------------------------------------------------------------------------------------
    proc TracePlace_active_button {window } {
	global columns
	
	# detects which button is active, and returns its grid position
	for {set columns_cnt 0 } {$columns_cnt <= $columns} {incr columns_cnt } {
	    for {set row_cnt 0} { $row_cnt <= [ expr (pow(2, $columns_cnt) -1)  ] } {incr row_cnt } {
		
		if { [$window.f_$columns_cnt\_$row_cnt.b cget -state] == "active" } {
		    return "$columns_cnt $row_cnt"
		} 
	    }
	}
    }
    
    #----------------------------------------------------------------------------------------------------------------------------------
    proc TracePlace_active_slot {window } {
	global columns
	
	# detects which button is active, and returns its grid position
	for {set columns_cnt 0 } {$columns_cnt <= $columns} {incr columns_cnt } {
	    for {set row_cnt 0} { $row_cnt <= [ expr (pow(2, $columns_cnt) -1)  ] } {incr row_cnt } {
		
		if { [$window.f_$columns_cnt\_$row_cnt.b cget -background] == "green" } {
		    return "$columns_cnt $row_cnt"
		} 
	    }
	}
    }
    
    #----------------------------------------------------------------------------------------------------------------------------------
    
    set ::trace_place_update_time 500

    #----------------------------------------------------------------------------------------------------------------------------------
    # resizes the slot on the the trace and place grid
    
    proc TracePlace_wheel_move { direction window } {
	global columns min_row_hei total_hei rows
	
	# update the scope traces after "trace_place_update_delay" , the delay is reset each time this proc is called
	foreach after_script [ after info ] {after cancel $after_script } ; # kills all the afters that are active
	
	set ::delayed_update_widget $window
	
	after $::trace_place_update_time {
	    set slot_location [ spicewish::TracePlace_active_slot $::delayed_update_widget ]
	    if { $slot_location != "" } { spicewish::TracePlace_selected_slot $::delayed_update_widget.f_[lindex $slot_location 0]\_[lindex $slot_location 1].b update } ;# update if there is an active (green) slot 
	} 
	
	scan [winfo geometry $window ] "%dx%d+%d+%d" width total_hei xpos ypos
	
	# detects which button is active 
	set button_location [ TracePlace_active_button $window]
	set col_cnt [lindex $button_location 0]
	set row_cnt [lindex $button_location 1]
	
	set grid_info [grid info $window.f_$col_cnt\_$row_cnt] 
	set col_info [lindex $grid_info 3]
	set row_span_info  [lindex $grid_info 9]
	set row_info [lindex $grid_info 5]
	
	# stores current slot sizes
	for {set rows_cnt  0 } {  $rows_cnt < $rows } {  incr rows_cnt} {	
	    set row_heights($rows_cnt) [	grid rowconfigure $window $rows_cnt -minsize ]
	    if {$row_heights($rows_cnt) < 10} {set row_heights($rows_cnt) 10}
	}
	
	set allocated_height 0
	
	# increases / decreases selected slots
	for { set rows_cnt $row_info} {$rows_cnt < [expr ($row_info + $row_span_info)  ] } {incr rows_cnt } {	
	    
	    set valholder $row_heights($rows_cnt) 
	    
	    if {$direction == "up" } {
		set valholder [expr  $valholder * 1.1]   ;#- scale up
	    } else {
		set valholder [expr $valholder / 1.1]	 ;#- scale down  
	    }
	    
	    set row_heights_holder($rows_cnt)  $valholder                        ;  #- store back in working holder
	    set allocated_height [expr $allocated_height +  $valholder]      ;  #- add the height
	}	
	
	# Return if this would exceed the screen size limit by itself (even without makeing all the other rows 0 height)
	if {$allocated_height >= $total_hei } {puts "hit limit $allocated_height";  return }
    
	# recalculates the slots sizes
	for {set rows_cnt_outer 0 } { $rows_cnt_outer < $rows} {incr rows_cnt_outer } {
	    
	    if { [catch {set temp $row_heights_holder($rows_cnt_outer)} ] }  {
		
		# Find unallocated heights total (i.e. the total of the elements not yet decided)
		set unallocated_height 0
		set allocated_height 0
		
		for { set rows_cnt 0 } { $rows_cnt < $rows } { incr rows_cnt} {
		    if { [catch {set temp $row_heights_holder($rows_cnt)} ] }  {
			set unallocated_height [ expr $unallocated_height + $row_heights($rows_cnt) ]     
		    } else {
			set allocated_height [ expr $allocated_height +  $row_heights_holder($rows_cnt) ]	    
			# case where a slot has been given a value above
		    }
	    }	   
		set scale_to_apply [ expr ($total_hei - $allocated_height) / $unallocated_height ] 
		set row_heights_holder($rows_cnt_outer)  [expr  ( $row_heights($rows_cnt_outer) * $scale_to_apply) ]
	    }
	}
	
	
	# if the first row 
	# need to be if all the rows are less than the miniumum allowed then set to minimum
	if { ( $row_info == 0 ) } {
	    # loop through all the rows checking if they have all dropped below the minumum
	    set temp 0 
	    for { set temp_cnt 0 } { $temp_cnt < $rows } { incr temp_cnt } {
		if { $row_heights_holder($temp_cnt) <  [expr $total_hei / $rows ] } { incr temp } 
	    }
	    if { $temp == $rows } {
		for { set temp_cnt 0 } { $temp_cnt < $rows } { incr temp_cnt } {
		    set row_heights_holder($temp_cnt)  [expr $total_hei / $rows ]
		}
	    }
	}

	# reapply's the new slot sizes
	for {set rows_cnt_outer 0 } { $rows_cnt_outer < $rows} {incr rows_cnt_outer } {
	    grid rowconfigure $window $rows_cnt_outer -minsize $row_heights_holder($rows_cnt_outer)
	}
	
    }

    
  
    

    ###################################################################
    # saving project
    #
    ###################################################################
    
    set ::saved_projects_extension "swp"
    
    proc project_save { project_name } { 
	
	save_all_nutmeg_windows save
	
	# creates list of project files
	set file_list [ glob $project_name* ] 
	
	set clean_file_list {}
	
	# run's through the list to clean up un needed files
	for { set i 0 } { $i < [ llength $file_list ] } { incr i } {
	
	    set file [ lrange $file_list $i $i ]
	    
	    # removes any tar balls
	    if { [ regexp {.tar.gz} $file ] == 1 } { continue }  ;
	    
	    # removes any project extension 
	    if { [ regexp {.swp} $file ] == 1 } {  continue }  ;

	    # removes any saved files
	    if { [ regexp {~} $file ] == 1 } { continue  }  ;
	    
	    append clean_file_list "$file "
	} 
	
	# delete's if project  already exsists    
	if { [ file exists $project_name.$::saved_projects_extension ]   } {puts ""; puts "deleted old project";  file delete -force $project_name.$::saved_projects_extension } 

	# saving file
	if { [ system tar -zcf $project_name.$::saved_projects_extension $clean_file_list] == 0 } { 
	    puts " "
	    puts "project \" $project_name.$::saved_projects_extension \" saved "
	    foreach file $file_list {
		puts "-- $file" 
	    }
	    puts ""
	}
    }
    
    #---------------------------------------------------------------------------------------------------------------
    # untars the project 
    proc project_open { project_name } {
	
	if { [ system tar -zxf $project_name ] == 0 } { puts "project '$project_name' opened ok " }    
    }
    
    #--------------------------------------------------------------------------------------------
    # returns contents list of the project file
    
    proc project_file_list { project_name } { 
	
	return [ exec tar tzf $project_name ] 
    }

    ::tclreadline::readline customcompleter  "spicewish::plot_command_readline_completer" ;#- see routine above

    namespace export plot

}
