.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/main$(BIN_DIR)/tests

$(BIN_DIR)/main: src/main.adb src/semi_space_collector.ads src/semi_space_collector.adb
	mkdir -p $(OBJ_DIR)$(BIN_DIR)
	$(GNAT) -P semi_space_gc.gpr -o$(BIN_DIR)/main src/main.adb

$(BIN_DIR)/tests: tests.adb src/semi_space_collector.ads src/semi_space_collector.adb
	mkdir -p $(OBJ_DIR)$(BIN_DIR)
	$(GNAT) -P semi_space_gc.gpr -o$(BIN_DIR)/tests tests.adb

test: $(BIN_DIR)/tests
	@echo "Running V&V test suite..."
	@./$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/*$(BIN_DIR)/*
