DASM_PATH=$$HOME/dasm
DASM=$(DASM_PATH)/bin/dasm
DASM_INCLUDE=$(DASM_PATH)/machines/atari2600

hyena.rom: hyena.asm
	$(DASM) hyena.asm -I$(DASM_INCLUDE) -f3 -ohyena.rom
