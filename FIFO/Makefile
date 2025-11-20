########################################
LIST	?=	compile
TB	?=	fifo_tb
build:
	@echo "Compile the list of files"
	vlog	-sv	-f	$(LIST).f

run:
	@echo "Simulation"
	vsim	-c	work.$(TB)
