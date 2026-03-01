/* SPDX-License-Identifier: MIT
 * Parse KHR_interactivity from JSON (JSMN) and run flow/sequence + math/add.
 */
#include "graph.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "jsmn.h"

/* Number of tokens a token and its descendants occupy. */
static int token_skip(const jsmntok_t *tokens, int idx) {
	const jsmntok_t *t = &tokens[idx];
	if (t->type == JSMN_PRIMITIVE || t->type == JSMN_STRING)
		return 1;
	if (t->type == JSMN_OBJECT) {
		int n = 1;
		int at = idx + 1;
		for (int i = 0; i < t->size; i++) {
			n += token_skip(tokens, at);
			at += token_skip(tokens, at);
			n += token_skip(tokens, at);
			at += token_skip(tokens, at);
		}
		return n;
	}
	if (t->type == JSMN_ARRAY) {
		int n = 1;
		int at = idx + 1;
		for (int i = 0; i < t->size; i++) {
			n += token_skip(tokens, at);
			at += token_skip(tokens, at);
		}
		return n;
	}
	return 1;
}

/* In object at obj_idx, find key and return token index of its value, or -1. */
static int object_get_key(const char *json, const jsmntok_t *tokens, int obj_idx, const char *key) {
	const jsmntok_t *obj = &tokens[obj_idx];
	if (obj->type != JSMN_OBJECT)
		return -1;
	size_t key_len = strlen(key);
	int at = obj_idx + 1;
	for (int i = 0; i < obj->size; i++) {
		int key_tok = at;
		int val_tok = at + 1;
		const jsmntok_t *kt = &tokens[key_tok];
		if (kt->type == JSMN_STRING && (size_t)(kt->end - kt->start) == key_len &&
		    strncmp(json + kt->start, key, key_len) == 0)
			return val_tok;
		at = val_tok + token_skip(tokens, val_tok);
	}
	return -1;
}

/* Array element at index. Returns token index or -1. */
static int array_get(const jsmntok_t *tokens, int arr_idx, int index) {
	const jsmntok_t *arr = &tokens[arr_idx];
	if (arr->type != JSMN_ARRAY || index < 0 || index >= arr->size)
		return -1;
	int at = arr_idx + 1;
	for (int i = 0; i < index; i++) {
		at += token_skip(tokens, at);
	}
	return at;
}

static double token_to_double(const char *json, const jsmntok_t *tokens, int idx) {
	const jsmntok_t *t = &tokens[idx];
	if (t->type != JSMN_PRIMITIVE)
		return 0.0;
	int len = t->end - t->start;
	char buf[64];
	if (len >= (int)sizeof(buf)) len = (int)sizeof(buf) - 1;
	memcpy(buf, json + t->start, (size_t)len);
	buf[len] = '\0';
	return atof(buf);
}

static int token_to_int(const char *json, const jsmntok_t *tokens, int idx) {
	return (int)token_to_double(json, tokens, idx);
}

/* Compare string token with literal. */
/* Parse declarations array into g->declarations. */
static void parse_declarations(const char *json, const jsmntok_t *tokens, int decl_arr_idx, graph_t *g) {
	const jsmntok_t *arr = &tokens[decl_arr_idx];
	if (arr->type != JSMN_ARRAY)
		return;
	g->num_declarations = arr->size;
	if (g->num_declarations > MAX_DECLS)
		g->num_declarations = MAX_DECLS;
	for (int i = 0; i < g->num_declarations; i++) {
		int decl_obj = array_get(tokens, decl_arr_idx, i);
		if (decl_obj < 0) continue;
		int op_tok = object_get_key(json, tokens, decl_obj, "op");
		if (op_tok >= 0 && tokens[op_tok].type == JSMN_STRING) {
			int start = tokens[op_tok].start;
			int end = tokens[op_tok].end;
			int len = end - start;
			if (len >= (int)sizeof(g->declarations[i].op)) len = (int)sizeof(g->declarations[i].op) - 1;
			memcpy(g->declarations[i].op, json + start, (size_t)len);
			g->declarations[i].op[len] = '\0';
		}
	}
}

/* Parse one node: declaration index, flows (for flow/sequence), values (for math/add). */
static void parse_node(const char *json, const jsmntok_t *tokens, int node_obj_idx, node_t *out) {
	memset(out, 0, sizeof(*out));
	out->decl_index = -1;
	int decl_tok = object_get_key(json, tokens, node_obj_idx, "declaration");
	if (decl_tok >= 0)
		out->decl_index = token_to_int(json, tokens, decl_tok);

	int flows_tok = object_get_key(json, tokens, node_obj_idx, "flows");
	if (flows_tok >= 0 && tokens[flows_tok].type == JSMN_OBJECT) {
		const jsmntok_t *fo = &tokens[flows_tok];
		out->flow_count = fo->size;
		if (out->flow_count > MAX_FLOW_OUT)
			out->flow_count = MAX_FLOW_OUT;
		int at = flows_tok + 1;
		for (int i = 0; i < out->flow_count; i++) {
			/* key (flow slot), value (object with "node", "socket") */
			int val_tok = at + 1;
			int node_tok = object_get_key(json, tokens, val_tok, "node");
			if (node_tok >= 0)
				out->flows[i].target_node = token_to_int(json, tokens, node_tok);
			at = val_tok + token_skip(tokens, val_tok);
		}
	}

	int values_tok = object_get_key(json, tokens, node_obj_idx, "values");
	if (values_tok >= 0 && tokens[values_tok].type == JSMN_OBJECT) {
		out->has_values = 1;
		int a_tok = object_get_key(json, tokens, values_tok, "a");
		int b_tok = object_get_key(json, tokens, values_tok, "b");
		if (a_tok >= 0) {
			int aval_arr = object_get_key(json, tokens, a_tok, "value");
			if (aval_arr >= 0) {
				int first = array_get(tokens, aval_arr, 0);
				if (first >= 0)
					out->value_a = token_to_double(json, tokens, first);
			}
		}
		if (b_tok >= 0) {
			int bval_arr = object_get_key(json, tokens, b_tok, "value");
			if (bval_arr >= 0) {
				int first = array_get(tokens, bval_arr, 0);
				if (first >= 0)
					out->value_b = token_to_double(json, tokens, first);
			}
		}
	}
}

int graph_parse(const char *json, graph_t *g) {
	memset(g, 0, sizeof(*g));
	jsmn_parser p;
	jsmn_init(&p);
	jsmntok_t *tokens = (jsmntok_t *)malloc(MAX_TOKEN * sizeof(jsmntok_t));
	if (!tokens) return -1;
	size_t len = strlen(json);
	int n = jsmn_parse(&p, json, len, tokens, MAX_TOKEN);
	if (n < 0) {
		free(tokens);
		return -1;
	}
	if (n == 0 || tokens[0].type != JSMN_OBJECT) {
		free(tokens);
		return -1;
	}
	if (n >= MAX_TOKEN) {
		free(tokens);
		return -1;
	}
	int ext = object_get_key(json, tokens, 0, "extensions");
	if (ext < 0) { free(tokens); return -1; }
	int khr = object_get_key(json, tokens, ext, "KHR_interactivity");
	if (khr < 0) { free(tokens); return -1; }
	int graphs = object_get_key(json, tokens, khr, "graphs");
	if (graphs < 0 || tokens[graphs].type != JSMN_ARRAY) { free(tokens); return -1; }
	int graph0 = array_get(tokens, graphs, 0);
	if (graph0 < 0) { free(tokens); return -1; }

	int decl_arr = object_get_key(json, tokens, graph0, "declarations");
	if (decl_arr >= 0)
		parse_declarations(json, tokens, decl_arr, g);

	int nodes_arr = object_get_key(json, tokens, graph0, "nodes");
	if (nodes_arr < 0 || tokens[nodes_arr].type != JSMN_ARRAY) {
		free(tokens);
		return -1;
	}
	const jsmntok_t *na = &tokens[nodes_arr];
	g->num_nodes = na->size;
	if (g->num_nodes > MAX_NODES)
		g->num_nodes = MAX_NODES;
	int at = nodes_arr + 1;
	for (int i = 0; i < g->num_nodes; i++) {
		parse_node(json, tokens, at, &g->nodes[i]);
		at += token_skip(tokens, at);
	}

	free(tokens);
	return 0;
}

/* Find roots: nodes with no incoming flow. */
static void find_roots(const graph_t *g, int *roots, int *num_roots) {
	int has_incoming[MAX_NODES];
	memset(has_incoming, 0, sizeof(has_incoming));
	for (int i = 0; i < g->num_nodes; i++) {
		for (int j = 0; j < g->nodes[i].flow_count; j++) {
			int t = g->nodes[i].flows[j].target_node;
			if (t >= 0 && t < g->num_nodes)
				has_incoming[t] = 1;
		}
	}
	*num_roots = 0;
	for (int i = 0; i < g->num_nodes && *num_roots < MAX_NODES; i++) {
		if (!has_incoming[i])
			roots[(*num_roots)++] = i;
	}
}

/* Run one node: flow/sequence -> activate targets in order; math/add -> print result. */
static void run_node(const graph_t *g, int node_id, int *queue, int *qback, int *qlen) {
	const node_t *n = &g->nodes[node_id];
	if (n->decl_index < 0 || n->decl_index >= g->num_declarations)
		return;
	const char *op = g->declarations[n->decl_index].op;

	if (strcmp(op, "flow/sequence") == 0) {
		for (int i = 0; i < n->flow_count; i++) {
			int t = n->flows[i].target_node;
			if (t >= 0 && t < g->num_nodes && *qlen < MAX_NODES) {
				queue[(*qback)++ % MAX_NODES] = t;
				(*qlen)++;
			}
		}
	} else if (strcmp(op, "math/add") == 0 && n->has_values) {
		double r = n->value_a + n->value_b;
		printf("math/add node %d: %.1f + %.1f = %.1f\n", node_id, n->value_a, n->value_b, r);
	}
}

int graph_run(graph_t *g) {
	int roots[MAX_NODES];
	int num_roots;
	find_roots(g, roots, &num_roots);
	if (num_roots == 0) {
		fprintf(stderr, "No root nodes\n");
		return -1;
	}
	int queue[MAX_NODES];
	int qfront = 0, qback = 0, qlen = 0;
	for (int i = 0; i < num_roots; i++) {
		queue[qback++ % MAX_NODES] = roots[i];
		qlen++;
	}
	printf("Running graph: %d nodes, %d roots\n", g->num_nodes, num_roots);
	while (qlen > 0) {
		int nid = queue[qfront % MAX_NODES];
		qfront++;
		qlen--;
		run_node(g, nid, queue, &qback, &qlen);
	}
	return 0;
}
