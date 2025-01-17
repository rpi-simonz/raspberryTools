#!/bin/bash
#
#######################################################################################################################
#
# Retrieve throttling bits of Raspberry and report their semantic
#
# Throttle bit semantic according https://www.raspberrypi.com/documentation/computers/os.html and check for undervoltage
#
#######################################################################################################################
#
#    Copyright (c) 2019-2023 framp at linux-tips-and-tricks dot de
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#######################################################################################################################

# Bits         0                       1                     2                       3
m=( "Under-voltage detected" "Arm frequency capped" "Currently throttled" "Soft temperature limit active" \
""  ""  ""  ""  ""  ""  ""  ""  ""  ""  ""  "" \
"Under-voltage has occurred" "Arm frequency capped has occurred" "Throttling has occurred" "Soft temperature limit has occurred" )
# Bits      16                            17                              18                              19

function analyze() {

   local b=$(perl -e "printf \"%08b\\n\", $1" 2>/dev/null)           # convert hex number into binary number
   local i=0                                                         # start with bit 0 (LSb)
   local t
   while [[ -n $b ]]; do                                             # there are still bits to process
      t=${b:${#b}-1:1}                                               # extract LSb
      if (( $t != 0 )); then                                         # bit set
         if (( $i <= ${#m[@]} - 1 )) && [[ -n ${m[$i]} ]]; then      # bit meaning is defined
            echo "Bit $i set: ${m[$i]}"
         else                                                        # bit meaning unknown
            echo "Bit $i set: meaning unknown"
         fi
      fi
      b=${b::-1}                                                     # remove LSb from throttle bits
      (( i++ ))                                                      # inc bit counter
   done
}

if (( $UID != 0 )); then
   echo "Call script as root or use sudo"
   exit 42
fi

if ! $which vcgencmd &>/dev/null; then
   echo "No vcgencmd detected."
   exit 42
fi

options=("" 0xf)
for o in "${options[@]}"; do
   t=$(vcgencmd get_throttled $o | cut -f 2 -d "=" )
   if [[ $t != "0x0" ]]; then
      echo ":-( Throttling bits in hex: $t"
      analyze $t
   else
      echo ":-) Neither undervoltage nor throttling detected"
   fi
   if [[ $t != "0x0" ]]; then
		echo -n "NOTE: "
		if [[ -z $o ]]; then
			echo "Bits reset on boot only"
		else
			echo "Bits reset after call of this script"
		fi
	fi
done
