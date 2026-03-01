/* SPDX-License-Identifier: MIT
 * In-memory graph and runner for KHR_interactivity.
 */
#ifndef GRAPH_H
#define GRAPH_H

#include <stddef.h>

#define MAX_NODES 32
#define MAX_DECLS 16
#define MAX_FLOW_OUT 16
#define MAX_TOKEN 4096

typedef struct {
	int target_node;
	/* socket name not needed for rope: we only activate "in" */
} flow_out_t;

typedef struct {
	int decl_index;
	int flow_count;
	flow_out_t flows[MAX_FLOW_OUT];
	double value_a;
	double value_b;
	int has_values; /* 1 if math/add-style values */
} node_t;

typedef struct {
	char op[32]; /* "flow/sequence", "math/add" */
} decl_t;

typedef struct {
	int num_nodes;
	int num_declarations;
	node_t nodes[MAX_NODES];
	decl_t declarations[MAX_DECLS];
} graph_t;

/* Parse JSON chunk (null-terminated), fill *g. Returns 0 on success. */
int graph_parse(const char *json, graph_t *g);

/* Run graph: activate roots, execute flow/sequence and math/add. Prints step results. Returns 0 on success. */
int graph_run(graph_t *g);

#endif
