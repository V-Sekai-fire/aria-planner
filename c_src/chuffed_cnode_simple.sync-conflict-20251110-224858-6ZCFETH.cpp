// SPDX-License-Identifier: MIT
// Copyright (c) 2025-present K. S. Ernest (iFire) Lee
//
// Chuffed C Node - Simple port-based version
// Reads FlatZinc from stdin, writes solution to stdout

#include <string>
#include <sstream>
#include <iostream>
#include <cstdlib>

// Chuffed includes
#include "chuffed/core/engine.h"
#include "chuffed/core/options.h"
#include "chuffed/core/sat-types.h"
#include "chuffed/core/sat.h"
#include "chuffed/flatzinc/flatzinc.h"
#include "chuffed/support/vec.h"

int main(int argc, char** argv) {
    try {
        // Read FlatZinc content from stdin
        // Read all input until EOF
        std::string flatzinc_content;
        std::string line;
        while (std::getline(std::cin, line)) {
            flatzinc_content += line + "\n";
        }
        
        // Also try reading any remaining data
        if (!flatzinc_content.empty() && flatzinc_content.back() != '\n') {
            flatzinc_content += "\n";
        }
        
        if (flatzinc_content.empty()) {
            std::cerr << "error\nNo FlatZinc content provided" << std::endl;
            return 1;
        }
        
        // Parse options
        int argc_dummy = 1;
        char* argv_dummy[] = {const_cast<char*>("chuffed"), nullptr};
        char** argv_ptr = argv_dummy;
        parseOptions(argc_dummy, argv_ptr);
        
        // Parse and solve
        std::istringstream flatzinc_stream(flatzinc_content);
        std::ostringstream error_stream;
        std::ostringstream output_stream;
        
        FlatZinc::solve(flatzinc_stream, error_stream);
        
        if (FlatZinc::s == nullptr) {
            std::cerr << "error\nFailed to parse FlatZinc problem" << std::endl;
            return 1;
        }
        
        // Set up output stream
        engine.setOutputStream(output_stream);
        engine.set_assumptions(FlatZinc::s->assumptions);
        
        // Solve
        std::string command_line = "chuffed";
        engine.solve(FlatZinc::s, command_line);
        
        // Get result
        std::string solution = output_stream.str();
        std::string errors = error_stream.str();
        
        // Output result
        if (engine.status == RES_SAT) {
            std::cout << "ok\n" << solution << std::flush;
        } else if (engine.status == RES_LUN || engine.status == RES_GUN) {
            std::cerr << "error\nUNSATISFIABLE" << std::endl;
            return 1;
        } else {
            if (solution.empty()) {
                std::cerr << "error\nNo solution found" << std::endl;
                return 1;
            } else {
                std::cout << "ok\n" << solution << std::flush;
            }
        }
        
        return 0;
        
    } catch (const std::exception& e) {
        std::cerr << "error\n" << e.what() << std::endl;
        return 1;
    } catch (...) {
        std::cerr << "error\nUnknown exception" << std::endl;
        return 1;
    }
}

