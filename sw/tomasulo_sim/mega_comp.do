#Author: Sabyasachi Ghosh
#File: mega.do
#compiles tomasulo with different instruction stream every time.
#simulates mega_tb for 2us
#mega_tb checks for correctness and reports in mega_out.txt

# 1. compile new inst stream

# 2. simulate mega_tb

set outfile [open mega_log.txt w]
foreach item {i_fetch_test_stream_add.vhd i_fetch_test_stream_div.vhd i_fetch_test_stream_jal_jr.vhd i_fetch_test_stream_jal_jr_factorial.vhd i_fetch_test_stream_jal_jr_factorial_simple.vhd i_fetch_test_stream_lws.vhd i_fetch_test_stream_lws_sws.vhd i_fetch_test_stream_memory_disambiguation.vhd i_fetch_test_stream_memory_disambiguation_RAW.vhd i_fetch_test_stream_memory_disambiguation_add_buff_test.vhd i_fetch_test_stream_min_finder.vhd i_fetch_test_stream_mul.vhd i_fetch_test_stream_selective_flushing.vhd i_fetch_test_stream_selective_flushing_memory_disambiguation.vhd i_fetch_test_stream_sort.vhd i_fetch_test_stream_sort_selection_only.vhd i_fetch_test_stream_summation.vhd i_fetch_test_stream_summation_with_jumps.vhd i_fetch_test_stream_sws.vhd} {
	puts $item
	puts $outfile $item
	puts $outfile " "
	vcom -work ee560 $item 
	vcom -work ee560 inst_cache_dpram_r2_sim.vhd
	vcom -work ee560 mega_tb.vhd 	
	vsim ee560.mega_tb 
	run 35us
	
	mem save -o ${item}_dram.mem -f hex -noaddress -wordsperline 1 /mega_tb/uut/datacache_inst/memory/ram
	mem save -o ${item}_prf.mem -f hex -noaddress -wordsperline 1 /mega_tb/uut/phyregfile/physical_register_r
	mem save -o ${item}_crat.mem -f mti -noaddress -data unsigned -addr hex -wordsperline 1 /mega_tb/uut/cfc_inst/committed_rslist
	
	#compare data ram here 
	set f1 [open ${item}_dram.mem r]
	set f2 [open ${item}_dram_gold.mem r]

	#get data into a string
	set dram_str [read $f1]
	set dram_gold_str [read $f2]
	
	close $f1
	close $f2
	#convert into an array
	set dram [split $dram_str "\n"]
	set dram_gold [split $dram_gold_str "\n"]

	set i 1
	foreach dram_item $dram dram_gold_item $dram_gold {
		if {$i > 3 && $dram_item!=$dram_gold_item} {
			puts -nonewline $outfile "DRAM comparison failed for Line number" 
			#set j [expr $i - 3]
			puts $outfile $i
		}
		incr i
	}
	
	#compare registers here
	
	set f1 [open ${item}_prf.mem r]
	set f2 [open ${item}_prf_gold.mem r]

	#get data into a string
	set prf_str [read $f1]
	set prf_gold_str [read $f2]
	
	close $f1
	close $f2
	#convert into an array
	set prf [split $prf_str "\n"]
	set prf_gold [split $prf_gold_str "\n"]

	
	set f3 [open ${item}_crat.mem r]
	set f4 [open ${item}_crat_gold.mem r]

	#get data into a string
	set crat_str [read $f3]
	set crat_gold_str [read $f4]
	
	close $f3
	close $f4
	
	#convert into an array
	set crat [split $crat_str "\n"]
	set crat_gold [split $crat_gold_str "\n"]

	set i 1
	foreach crat_item $crat crat_gold_item $crat_gold {
		if {$i > 3 && $i < 36} {
			#extract the correct prf item
			
			set i1 [expr $crat_item + 3]
			set i2 [expr $crat_gold_item + 3]
			
			set val1 [lindex $prf $i1]
			set val2 [lindex $prf_gold $i2]
			if { $val1 != $val2} {
				puts -nonewline $outfile "REGISTER comparison failed for Line number " 
				#set j [expr $i - 3]
				puts $outfile $i
			}
		}
		incr i
	}
	puts $outfile " "
	quit -sim
}

close $outfile