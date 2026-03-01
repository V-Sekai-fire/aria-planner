/* SPDX-License-Identifier: MIT
 * Interactivity runner: load GLB and run KHR_interactivity default graph.
 * Parses JSON chunk with JSMN, runs flow/sequence and math/add nodes; entry = roots.
 */
#include "graph.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int glb_read_json_chunk(const char *path, char **json_out, size_t *json_len);

int main(int argc, char **argv) {
	if (argc < 2) {
		fprintf(stderr, "Usage: %s <path.glb>\n", argv[0]);
		return 1;
	}

	char *json = NULL;
	size_t json_len = 0;
	if (glb_read_json_chunk(argv[1], &json, &json_len) != 0) {
		fprintf(stderr, "Failed to read GLB or extract JSON chunk\n");
		return 1;
	}

	if (strstr(json, "KHR_interactivity") == NULL) {
		fprintf(stderr, "KHR_interactivity not found in GLB\n");
		free(json);
		return 1;
	}

	graph_t g;
	if (graph_parse(json, &g) != 0) {
		fprintf(stderr, "Failed to parse KHR_interactivity graph\n");
		free(json);
		return 1;
	}
	free(json);

	if (graph_run(&g) != 0) {
		fprintf(stderr, "Graph run failed\n");
		return 1;
	}
	return 0;
}
