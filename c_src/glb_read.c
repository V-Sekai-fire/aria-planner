/* SPDX-License-Identifier: MIT
 * Minimal GLB chunk reader: read file, validate header, extract JSON chunk.
 * Used by interactivity_runner. No cgltf dependency for rope build.
 */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define GLB_MAGIC 0x46546C67
#define GLB_CHUNK_JSON 0x4E4F534A

typedef struct {
	uint32_t magic;
	uint32_t version;
	uint32_t length;
} glb_header_t;

typedef struct {
	uint32_t chunk_length;
	uint32_t chunk_type;
} glb_chunk_t;

/* Read file into buffer. Caller frees *out. Returns 0 on success. */
static int read_file(const char *path, uint8_t **out, size_t *size) {
	FILE *f = fopen(path, "rb");
	if (!f) return -1;
	fseek(f, 0, SEEK_END);
	long n = ftell(f);
	if (n <= 0) { fclose(f); return -1; }
	fseek(f, 0, SEEK_SET);
	*size = (size_t)n;
	*out = (uint8_t *)malloc(*size);
	if (!*out) { fclose(f); return -1; }
	size_t nr = fread(*out, 1, *size, f);
	fclose(f);
	return (nr == *size) ? 0 : -1;
}

/* Validate GLB header and first chunk (JSON). Returns 0 on success. */
int glb_read_json_chunk(const char *path, char **json_out, size_t *json_len) {
	uint8_t *buf = NULL;
	size_t file_size = 0;
	if (read_file(path, &buf, &file_size) != 0)
		return -1;

	if (file_size < 12 + 8) {
		free(buf);
		return -1;
	}

	glb_header_t *h = (glb_header_t *)buf;
	if (h->magic != GLB_MAGIC || h->version != 2) {
		free(buf);
		return -1;
	}

	glb_chunk_t *c = (glb_chunk_t *)(buf + 12);
	if (c->chunk_type != GLB_CHUNK_JSON) {
		free(buf);
		return -1;
	}

	size_t chunk_len = c->chunk_length;
	if (12 + 8 + chunk_len > file_size) {
		free(buf);
		return -1;
	}

	*json_len = chunk_len;
	*json_out = (char *)malloc(chunk_len + 1);
	if (!*json_out) {
		free(buf);
		return -1;
	}
	memcpy(*json_out, buf + 12 + 8, chunk_len);
	(*json_out)[chunk_len] = '\0';
	free(buf);
	return 0;
}
