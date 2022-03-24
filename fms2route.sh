#!/bin/bash
script_name=$(basename "$0")
if [ $# -eq 0 ]; then
    echo "Usage: $script_name [-x|-1] FILE..."
    echo "Print the .fms FILE's flight plan as a single line (not including departure and arrival airports)."
    echo "The format of the line depends on the option:"
    echo "    -x    X-Plane 11 ATC"
    echo "    -1    124thATCv2 plugin (default)"
    exit 1
fi
if [ "$1" = "-x" -o "$1" = "-X" ]; then
    x_plane_format=true
    shift
else
    if [ "$1" = "-1" ]; then
        shift
    fi
    x_plane_format=false
fi

if [ "$x_plane_format" = "true" ]; then
    grep_options="-o2 -o1"
else
    grep_options="-o1"
fi
while [ ! $# -eq 0 ]; do
    file_name=$(basename "$1")
    if [ ! -f "$1" ]; then
        echo "${file_name}: file does not exist"
    else
        dep_airport=$(pcregrep -n -o1 "^1 ([A-Z]{4}) ADEP .+$" "$1")
        des_airport=$(pcregrep -n -o1 "^1 ([A-Z]{4}) ADES .+$" "$1")
        if [ -z "$dep_airport" -o -z "$des_airport" ]; then
            echo "${file_name}: incorrect content"
        else
            dep_line_number="${dep_airport%:*}"
            des_line_number="${des_airport%:*}"
            route_line=$(tail -n +$(( $dep_line_number + 1 )) "$1" | head -n $(( $des_line_number - $dep_line_number - 1 )) | pcregrep ${grep_options} --om-separator=" " "^\d+ ([A-Z]+) ([A-Z0-9]+) .*$" | tr '\n' ' ' | xargs)
            route_line="${route_line//DRCT /}"
            echo "${dep_airport#*:}-${des_airport#*:}: ${route_line}"
        fi
    fi
    shift
done
