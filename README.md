gnuplot-pingscript
==================

This is a small script which utilizes the ping command and gnuplot to
generate a graph.

Usage
-----

	./gnuplot-pingscript.sh

Enter the needed values when you are prompted to do so.

Another way to use the script is with arguments:

	./gnuplot-pingscript.sh SERVER INTERVAL PING_COUNT PLOT_Y_START IMAGE_OUTPUT_HEIGHT IMAGE_OUTPUT_WIDTH

If you just want to generate the graph for a specific directory which
has a ping.txt file in it.

	./gnuplot-pingscript.sh DIRECTORY PLOT_Y_START IMAGE_OUTPUT_HEIGHT IMAGE_OUTPUT_WIDTH
