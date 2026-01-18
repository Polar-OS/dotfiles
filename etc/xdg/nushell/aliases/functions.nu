# redefine cd to cd-builtin
alias cd-builtin = cd

def --env cd [path?: string] {
    if $path != null { cd-builtin $path } else { cd-builtin }
    ls 
}
# set up cpu governor to powersave
def powersave [] {
  'power' | ^sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference | ignore
}
