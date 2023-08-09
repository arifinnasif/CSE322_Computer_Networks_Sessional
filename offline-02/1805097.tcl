set dim  [lindex $argv 0]
set number_of_nodes [lindex $argv 1]
set number_of_flows [lindex $argv 2]



# simulator
set ns [new Simulator]

expr srand(5097)

# ======================================================================
# Define options


set val(chan)         Channel/WirelessChannel  ;# channel type
set val(prop)         Propagation/TwoRayGround ;# radio-propagation model
set val(ant)          Antenna/OmniAntenna      ;# Antenna type
set val(ll)           LL                       ;# Link layer type
set val(ifq)          Queue/DropTail/PriQueue  ;# Interface queue type
set val(ifqlen)       50                       ;# max packet in ifq
set val(netif)        Phy/WirelessPhy          ;# network interface type
set val(mac)          Mac             ;# MAC type
set val(rp)           AODV                     ;# ad-hoc routing protocol 
set val(nn)           $number_of_nodes                       ;# number of mobilenodes
# set val(src)          [expr {floor([$r2 uniform 0 $val(nn)])}]
set val(src)          [expr int(rand()*$val(nn))]
# =======================================================================

# trace file
set trace_file [open trace.tr w]
$ns trace-all $trace_file

# set dim 500

# nam file
set nam_file [open animation.nam w]
$ns namtrace-all-wireless $nam_file $dim $dim

# from in built example
# $ns puts-nam-traceall {# nam4wpan #}
# Mac/802_15_4 wpanNam namStatus on

# topology: to keep track of node movements
set topo [new Topography]
$topo load_flatgrid $dim $dim ;# 500m x 500m area


# general operation director for mobilenodes
create-god $val(nn)


# node configs
# ======================================================================

# $ns node-config -addressingType flat or hierarchical or expanded
#                  -adhocRouting   DSDV or DSR or TORA
#                  -llType	   LL
#                  -macType	   Mac/802_11
#                  -propType	   "Propagation/TwoRayGround"
#                  -ifqType	   "Queue/DropTail/PriQueue"
#                  -ifqLen	   50
#                  -phyType	   "Phy/WirelessPhy"
#                  -antType	   "Antenna/OmniAntenna"
#                  -channelType    "Channel/WirelessChannel"
#                  -topoInstance   $topo
#                  -energyModel    "EnergyModel"
#                  -initialEnergy  (in Joules)
#                  -rxPower        (in W)
#                  -txPower        (in W)
#                  -agentTrace     ON or OFF
#                  -routerTrace    ON or OFF
#                  -macTrace       ON or OFF
#                  -movementTrace  ON or OFF

# ======================================================================

$ns node-config -adhocRouting $val(rp) \
                -llType $val(ll) \
                -macType $val(mac) \
                -ifqType $val(ifq) \
                -ifqLen $val(ifqlen) \
                -antType $val(ant) \
                -propType $val(prop) \
                -phyType $val(netif) \
                -topoInstance $topo \
                -channelType $val(chan) \
                -agentTrace ON \
                -routerTrace ON \
                -macTrace OFF \
                -movementTrace OFF

# create nodes
for {set i 0} {$i < $val(nn) } {incr i} {

    set node($i) [$ns node]
    $node($i) random-motion 0       ;# disable random motion
    # puts [expr (50 * $i) % 10]

    set row_width 10

    if {$val(nn) >= 60} {
        set row_width 10
    } elseif {$val(nn) >= 40} {
        set row_width 8
    } else {
        set row_width 5
    }

    $node($i) set X_ [expr ($dim * ($i % $row_width))/$row_width]
    set temp [expr {floor($i/$row_width)}]
    set row_count [expr {ceil($val(nn)/$row_width)}]
    $node($i) set Y_ [expr ($dim * $temp)/$row_count]
    $node($i) set Z_ 0

    set dest_x [expr {rand()*$dim}]
    set dest_y [expr {rand()*$dim}]
    set speed [expr {rand()*4+1}]

    $ns initial_node_pos $node($i) 20

    $ns at 1.0 "$node($i) setdest $dest_x $dest_y $speed" 
} 

# from in built example
# Mac/802_15_4 wpanNam PlaybackRate 3ms





# Traffic
set val(nf)         $number_of_flows                ;# number of flows

# set tcp [new Agent/TCP/Reno]
# $ns attach-agent $node($val(src)) $tcp
# set ftp [new Application/FTP]
# $ftp attach-agent $tcp
# $ns at 1.0 "$ftp start"

for {set i 0} {$i < $val(nf)} {incr i} {
    # set r [new RNG]
    # puts [expr {floor([$r uniform 2 6])}]
    while 1 {
        # set dest [expr {floor([$r uniform 0 $val(nn)])}]
        set dest [expr int(rand()*$val(nn))]
        if {$dest ne $val(src)} break
    }
    # set src $i
    # set dest [expr $i + 10]

    # Traffic config
    # create agent
    set tcp [new Agent/TCP/Reno]
    set tcp_sink [new Agent/TCPSink]
    # attach to nodes
    $ns attach-agent $node($val(src)) $tcp
    $ns attach-agent $node($dest) $tcp_sink
    # connect agents
    $ns connect $tcp $tcp_sink
    $tcp set fid_ $i

    # Traffic generator
    set ftp [new Application/FTP]
    # $ftp set packet_size_ 40
    # attach to agent
    $ftp attach-agent $tcp
    
    # start traffic generation
    $ns at 1.0 "$ftp start"
}



# End Simulation

# Stop nodes
for {set i 0} {$i < $val(nn)} {incr i} {
    $ns at 50.0 "$node($i) reset"
}

# call final function
proc finish {} {
    global ns trace_file nam_file
    $ns flush-trace
    close $trace_file
    close $nam_file
}

proc halt_simulation {} {
    global ns
    puts "Simulation ending"
    $ns halt
}

$ns at 50.0001 "finish"
$ns at 50.0002 "halt_simulation"



# Run simulation
puts "Simulation starting"
$ns run


