// SPDX-License-Identifier: MIT
// Copyright (c) 2025-present K. S. Ernest (iFire) Lee
//
// C++ wrapper for Chuffed constraint solver
// This module provides NIF bindings to use Chuffed directly from Elixir

#include <erl_nif.h>
#include <string>
#include <vector>
#include <memory>
#include <iostream>
#include <fstream>
#include <sstream>
#include <cstdlib>
#include <cstring>

#ifdef _WIN32
#include <windows.h>
#include <io.h>
#include <process.h>
#else
#include <unistd.h>
#include <sys/wait.h>
#include <errno.h>
#endif

// Chuffed includes - adjust paths as needed based on your Chuffed installation
// Uncomment and adjust paths when Chuffed is installed:
// #include "chuffed/flatzinc/flatzinc.h"
// #include "chuffed/support/vec.h"
// #include "chuffed/core/engine.h"

// NIF resource type for Chuffed solver instance
typedef struct {
    void* solver;  // Chuffed solver instance
    bool initialized;
} ChuffedSolver;

// Forward declarations
static ERL_NIF_TERM solve_flatzinc_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
static ERL_NIF_TERM create_solver_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
static ERL_NIF_TERM destroy_solver_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);

// NIF function table
static ErlNifFunc nif_funcs[] = {
    {"solve_flatzinc", 2, solve_flatzinc_nif},
    {"create_solver", 0, create_solver_nif},
    {"destroy_solver", 1, destroy_solver_nif}
};

// Resource type for Chuffed solver
static ErlNifResourceType* chuffed_solver_type = NULL;

// Resource destructor
static void chuffed_solver_destructor(ErlNifEnv* env, void* obj) {
    ChuffedSolver* solver = (ChuffedSolver*)obj;
    if (solver && solver->initialized) {
        // Clean up Chuffed solver if needed
        solver->initialized = false;
    }
}

// NIF module load callback
static int load(ErlNifEnv* env, void** priv_data, ERL_NIF_TERM load_info) {
    // Create resource type for Chuffed solver
    chuffed_solver_type = enif_open_resource_type(
        env,
        NULL,
        "ChuffedSolver",
        chuffed_solver_destructor,
        ERL_NIF_RT_CREATE,
        NULL
    );
    
    if (chuffed_solver_type == NULL) {
        return 1;
    }
    
    return 0;
}

// Helper: Convert Erlang binary to C++ string
static bool get_binary(ErlNifEnv* env, ERL_NIF_TERM term, std::string& result) {
    ErlNifBinary bin;
    if (!enif_inspect_binary(env, term, &bin)) {
        return false;
    }
    result.assign((const char*)bin.data, bin.size);
    return true;
}

// Helper: Convert C++ string to Erlang binary
static ERL_NIF_TERM make_binary(ErlNifEnv* env, const std::string& str) {
    ErlNifBinary bin;
    if (!enif_alloc_binary(str.size(), &bin)) {
        return enif_make_atom(env, "error");
    }
    memcpy(bin.data, str.c_str(), str.size());
    return enif_make_binary(env, &bin);
}

// Helper: Convert Erlang list to C++ vector of strings
static bool get_string_list(ErlNifEnv* env, ERL_NIF_TERM list, std::vector<std::string>& result) {
    ERL_NIF_TERM head, tail = list;
    result.clear();
    
    while (enif_get_list_cell(env, tail, &head, &tail)) {
        std::string str;
        if (!get_binary(env, head, str)) {
            return false;
        }
        result.push_back(str);
    }
    
    return true;
}

// Helper: Create temporary file (cross-platform)
static bool create_temp_file(const std::string& prefix, const std::string& suffix, std::string& temp_path) {
#ifdef _WIN32
    char temp_dir[MAX_PATH];
    if (GetTempPathA(MAX_PATH, temp_dir) == 0) {
        return false;
    }
    
    // Create a unique temp file name
    char temp_file[MAX_PATH];
    char unique_prefix[4] = "CHF";  // Prefix for GetTempFileName
    
    if (GetTempFileNameA(temp_dir, unique_prefix, 0, temp_file) == 0) {
        return false;
    }
    
    // GetTempFileName creates the file, delete it and use the name with our suffix
    DeleteFileA(temp_file);
    
    // Replace the extension with our suffix
    std::string base_name(temp_file);
    size_t last_dot = base_name.find_last_of('.');
    if (last_dot != std::string::npos) {
        base_name = base_name.substr(0, last_dot);
    }
    temp_path = base_name + suffix;
#else
    std::string temp_template = "/tmp/" + prefix + "XXXXXX" + suffix;
    char* temp_template_c = new char[temp_template.length() + 1];
    strcpy(temp_template_c, temp_template.c_str());
    
    int fd = mkstemp(temp_template_c);
    if (fd == -1) {
        delete[] temp_template_c;
        return false;
    }
    close(fd);
    
    temp_path = std::string(temp_template_c);
    delete[] temp_template_c;
#endif
    return true;
}

// Helper: Execute command and capture output (cross-platform)
static bool execute_command(const std::string& command, std::string& output, int& exit_code) {
#ifdef _WIN32
    // Use cmd.exe /c for Windows native prompt
    std::string win_command = "cmd.exe /c \"" + command + " 2>&1\"";
    FILE* pipe = _popen(win_command.c_str(), "r");
#else
    FILE* pipe = popen((command + " 2>&1").c_str(), "r");
#endif
    if (!pipe) {
        return false;
    }
    
    char buffer[4096];
    output.clear();
    while (fgets(buffer, sizeof(buffer), pipe) != NULL) {
        output += buffer;
    }
    
#ifdef _WIN32
    exit_code = _pclose(pipe);
    if (exit_code == -1) {
        return false;
    }
#else
    exit_code = pclose(pipe);
    if (exit_code == -1) {
        return false;
    }
    // pclose returns exit status in upper 8 bits on Unix
    exit_code = WEXITSTATUS(exit_code);
#endif
    return true;
}

// Solve FlatZinc problem using Chuffed
static ERL_NIF_TERM solve_flatzinc_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    if (argc != 2) {
        return enif_make_badarg(env);
    }
    
    std::string flatzinc_content;
    std::string options_json;
    
    if (!get_binary(env, argv[0], flatzinc_content)) {
        return enif_make_tuple2(env,
            enif_make_atom(env, "error"),
            enif_make_atom(env, "invalid_flatzinc")
        );
    }
    
    if (!get_binary(env, argv[1], options_json)) {
        options_json = "{}";  // Default empty options
    }
    
    // Create temporary file with unique name (cross-platform)
    std::string temp_file;
    if (!create_temp_file("chuffed_", ".fzn", temp_file)) {
        return enif_make_tuple2(env,
            enif_make_atom(env, "error"),
            enif_make_string(env, "failed_to_create_temp_file", ERL_NIF_LATIN1)
        );
    }
    
    // Write FlatZinc content to temp file
    std::ofstream fout(temp_file, std::ios::binary);
    if (!fout.is_open()) {
        remove(temp_file.c_str());
        return enif_make_tuple2(env,
            enif_make_atom(env, "error"),
            enif_make_string(env, "failed_to_open_temp_file", ERL_NIF_LATIN1)
        );
    }
    
    fout.write(flatzinc_content.c_str(), flatzinc_content.length());
    fout.close();
    
    if (!fout.good()) {
        remove(temp_file.c_str());
        return enif_make_tuple2(env,
            enif_make_atom(env, "error"),
            enif_make_string(env, "failed_to_write_temp_file", ERL_NIF_LATIN1)
        );
    }
    
    // Execute Chuffed solver (use native Windows prompt if on Windows)
#ifdef _WIN32
    // On Windows, ensure paths with spaces are handled correctly
    std::string command = "chuffed \"" + temp_file + "\"";
#else
    std::string command = "chuffed " + temp_file;
#endif
    std::string output;
    int exit_code;
    
    if (!execute_command(command, output, exit_code)) {
        remove(temp_file.c_str());
        return enif_make_tuple2(env,
            enif_make_atom(env, "error"),
            enif_make_string(env, "failed_to_execute_chuffed", ERL_NIF_LATIN1)
        );
    }
    
    // Clean up temp file
    remove(temp_file.c_str());
    
    // Return result
    if (exit_code == 0 || output.find("==========") != std::string::npos) {
        // Success or solution found
        return enif_make_tuple2(env,
            enif_make_atom(env, "ok"),
            make_binary(env, output)
        );
    } else {
        // Error or unsatisfiable
        return enif_make_tuple2(env,
            enif_make_atom(env, "error"),
            make_binary(env, output)
        );
    }
}


// Create a Chuffed solver instance
static ERL_NIF_TERM create_solver_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    if (argc != 0) {
        return enif_make_badarg(env);
    }
    
    ChuffedSolver* solver = (ChuffedSolver*)enif_alloc_resource(chuffed_solver_type, sizeof(ChuffedSolver));
    if (solver == NULL) {
        return enif_make_tuple2(env,
            enif_make_atom(env, "error"),
            enif_make_atom(env, "allocation_failed")
        );
    }
    
    solver->solver = NULL;  // Initialize Chuffed solver here if using API directly
    solver->initialized = false;
    
    ERL_NIF_TERM resource_term = enif_make_resource(env, solver);
    enif_release_resource(solver);
    
    return enif_make_tuple2(env,
        enif_make_atom(env, "ok"),
        resource_term
    );
}

// Destroy a Chuffed solver instance
static ERL_NIF_TERM destroy_solver_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    if (argc != 1) {
        return enif_make_badarg(env);
    }
    
    ChuffedSolver* solver;
    if (!enif_get_resource(env, argv[0], chuffed_solver_type, (void**)&solver)) {
        return enif_make_tuple2(env,
            enif_make_atom(env, "error"),
            enif_make_atom(env, "invalid_resource")
        );
    }
    
    // Cleanup is handled by the destructor
    return enif_make_atom(env, "ok");
}

// NIF module entry point
ERL_NIF_INIT(Elixir.AriaPlanner.Solvers.ChuffedSolverNif, nif_funcs, load, NULL, NULL, NULL)

