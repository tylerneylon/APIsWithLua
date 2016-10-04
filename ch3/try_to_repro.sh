#!/bin/bash
for i in $(seq 100); do
    ./eatyguy4 > "t_$i"
    num_lines=$(cat "t_$i" | wc -l)
    echo $num_lines num lines
    for k in $(seq $num_lines); do
        head -$k t_$i | tail -5
    done
    sleep 0.5
    echo "^^^^ Last run written to t_$i ^^^^"
    sleep 0.5
    #read j
    #if [ $j = "q" ]; then
    #    break
    #fi
done
