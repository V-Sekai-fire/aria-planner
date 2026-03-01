# Build interactivity_runner (GLB reader, JSON chunk extractor).
# Optional: make CGLTF=1 to build with cgltf (requires cgltf/ or cgltf.c + cgltf.h).
CC ?= gcc
CFLAGS ?= -Wall -Wextra -std=c99
BIN = interactivity_runner
SRC = main.c glb_read.c

.PHONY: all clean

all: $(BIN)

$(BIN): $(SRC)
	$(CC) $(CFLAGS) -o $@ $(SRC)

clean:
	rm -f $(BIN)
