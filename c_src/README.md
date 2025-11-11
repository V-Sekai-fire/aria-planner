# Chuffed Solver C++ Integration

This directory contains the C++ NIF (Native Implemented Function) bindings for the Chuffed constraint solver.

## Requirements

### System Dependencies

1. **Chuffed**: Constraint programming solver (REQUIRED)
   - Download from: https://github.com/chuffed/chuffed
   - Build and install Chuffed
   - Ensure Chuffed executable is in your PATH
   - Chuffed works directly with FlatZinc (.fzn) files
   - **Note: This solver only supports FlatZinc format - no MiniZinc support**

3. **C++ Compiler**: 
   - **Windows**: MSVC (cl.exe) or MinGW-w64 (g++.exe) with C++17 support
   - **Unix/Linux/Mac**: GCC or Clang with C++17 support

4. **Erlang/OTP**: For NIF development headers

## Building

### Automatic Build (via Mix)

The NIF is automatically built when you compile the project:

```bash
mix compile
```

### Manual Build

**On Unix/Linux/Mac:**

```bash
cd c_src
make
```

**On Windows (using native prompt - cmd.exe):**

Option 1: Use the Windows build script (recommended):
```cmd
cd c_src
build_windows.bat
```

Option 2: Use Makefile (if make is available):
```cmd
cd c_src
make
```

Option 3: Manual compilation with MSVC:
```cmd
cd c_src
cl.exe /std:c++17 /O2 /W3 /D_WIN32 /EHsc /LD /I"%ERLANG_ERTS_DIR%\include" chuffed_solver.cpp /Fe:..\priv\chuffed_solver_nif.dll
```

Option 4: Manual compilation with MinGW:
```cmd
cd c_src
g++.exe -std=c++17 -fPIC -O2 -Wall -Wextra -D_WIN32 -I"%ERLANG_ERTS_DIR%\include" -shared -o ..\priv\chuffed_solver_nif.dll chuffed_solver.cpp
```

This will create `priv/chuffed_solver_nif.so` (or `.dll` on Windows).

### Configuration

Edit `c_src/Makefile` to adjust paths:

- `CHUFFED_INCLUDE`: Path to Chuffed header files
- `CHUFFED_LIB`: Path to Chuffed library files
- `CHUFFED_LIBS`: Link flags for Chuffed libraries

Example:

```makefile
CHUFFED_INCLUDE := -I/usr/local/include/chuffed -I/opt/chuffed/include
CHUFFED_LIB := -L/usr/local/lib -L/opt/chuffed/lib
CHUFFED_LIBS := -lchuffed
```

## Installation Steps

### Unix/Linux/Mac

1. **Install Chuffed**:

   ```bash
   git clone https://github.com/chuffed/chuffed.git
   cd chuffed
   mkdir build && cd build
   cmake ..
   make
   sudo make install
   ```

2. **Build the NIF**:

   ```bash
   mix compile
   ```

### Windows

1. **Install Chuffed**:

   Using MinGW/MSYS2:
   ```cmd
   git clone https://github.com/chuffed/chuffed.git
   cd chuffed
   mkdir build && cd build
   cmake -G "MinGW Makefiles" ..
   mingw32-make
   mingw32-make install
   ```

   Or build with Visual Studio:
   ```cmd
   git clone https://github.com/chuffed/chuffed.git
   cd chuffed
   mkdir build && cd build
   cmake -G "Visual Studio 17 2022" ..
   cmake --build . --config Release
   ```

2. **Add Chuffed to PATH**:
   - Ensure `chuffed.exe` is in your system PATH
   - Or add Chuffed installation directory to PATH

3. **Build the NIF**:

   Using native Windows build script (recommended):
   ```cmd
   cd c_src
   build_windows.bat
   ```

   Or via Mix (will use build script automatically):
   ```cmd
   mix compile
   ```

4. **Verify installation**:

   ```elixir
   # In IEx
   {:ok, result} = AriaPlanner.Solvers.ChuffedSolverNif.solve_flatzinc("solve satisfy;", "{}")
   ```

## Usage

### From Elixir

**FlatZinc solving (only format supported):**

```elixir
# Solve a FlatZinc problem directly - Chuffed works natively with FlatZinc
flatzinc = """
var 1..10: x;
var 1..10: y;
constraint x + y = 10;
solve satisfy;
"""

{:ok, solution} = AriaPlanner.Solvers.AriaChuffedSolver.solve_flatzinc(flatzinc)

# Or solve from a FlatZinc file
{:ok, solution} = AriaPlanner.Solvers.AriaChuffedSolver.solve_flatzinc_file(
  "path/to/problem.fzn"
)
```

### From Planning Domains

```elixir
# Solve constraints for a planning domain
constraints = %{
  variables: [
    {:start_time, :int, 0, 100},
    {:duration, :int, 1, 20}
  ],
  constraints: [
    {:int_le, :start_time, 50},
    {:int_ge, :duration, 5}
  ],
  objective: {:minimize, :start_time}
}

{:ok, solution} = AriaPlanner.Solvers.AriaChuffedSolver.solve(
  constraints,
  domain_type: "aircraft_disassembly"
)
```

## Troubleshooting

### NIF Not Loading

If you see `:nif_not_loaded` errors:

**Unix/Linux/Mac:**
1. Check that the NIF was built: `ls priv/chuffed_solver_nif.so`
2. Verify Erlang can find the library: `:code.priv_dir(:aria_planner)`
3. Check library dependencies: `ldd priv/chuffed_solver_nif.so` (Linux) or `otool -L priv/chuffed_solver_nif.so` (macOS)

**Windows:**
1. Check that the NIF was built: `dir priv\chuffed_solver_nif.dll`
2. Verify Erlang can find the library: `:code.priv_dir(:aria_planner)`
3. Check for missing DLL dependencies: Use Dependency Walker or `dumpbin /dependents priv\chuffed_solver_nif.dll`

### Chuffed Not Found

If Chuffed executable is not found:

**Unix/Linux/Mac:**
1. Verify Chuffed is installed: `which chuffed` or `pkg-config --modversion chuffed` (if available)
2. Add Chuffed to PATH: `export PATH=$PATH:/path/to/chuffed/bin`

**Windows:**
1. Verify Chuffed is installed: `where chuffed` (in cmd.exe)
2. Add Chuffed to PATH:
   - Open System Properties > Environment Variables
   - Add Chuffed installation directory to PATH
   - Or use: `set PATH=%PATH%;C:\path\to\chuffed\bin`

### Compilation Errors

If you get compilation errors:

**Unix/Linux/Mac:**
1. Ensure C++17 compiler is available: `g++ --version` or `clang++ --version`
2. Check Erlang headers are accessible
3. Verify Chuffed headers are in the include path

**Windows:**
1. **MSVC**: Ensure Visual Studio Build Tools are installed and Developer Command Prompt is used
   ```cmd
   cl.exe /?
   ```
2. **MinGW**: Ensure MinGW-w64 is installed and in PATH
   ```cmd
   g++.exe --version
   ```
3. Check Erlang headers are accessible: Verify `%ERLANG_ERTS_DIR%\include` exists
4. If using MSVC, ensure you're in a Developer Command Prompt (runs `vcvarsall.bat`)

### Windows-Specific Issues

**Command Execution:**
- The NIF uses `cmd.exe /c` for Windows native prompt execution
- Ensure Chuffed can be found via `where chuffed` in cmd.exe
- PowerShell may have different PATH - use cmd.exe for testing

**Temp Files:**
- Windows uses `GetTempPath()` and `GetTempFileName()` for temp file creation
- Temp files are created in the system temp directory (usually `%TEMP%` or `%TMP%`)

**Path Separators:**
- Windows uses backslashes (`\`) in paths
- The code handles both forward and backward slashes automatically

## Architecture

- `chuffed_solver.cpp`: C++ NIF implementation (cross-platform with Windows support)
- `Makefile`: Build configuration (supports Unix/Linux/Mac and Windows with make)
- `build_windows.bat`: Windows native build script (uses MSVC or MinGW)
- `lib/solvers/chuffed_solver_nif.ex`: Low-level NIF bindings
- `lib/solvers/aria_chuffed_solver.ex`: High-level Elixir interface

## Windows Native Compiler Support

The build system supports Windows native compilers:

- **MSVC (cl.exe)**: Microsoft Visual C++ compiler
  - Automatically detected if available
  - Use Developer Command Prompt for Visual Studio
  - Compiles directly to DLL

- **MinGW-w64 (g++.exe)**: GNU Compiler Collection for Windows
  - Automatically detected if available
  - Works in standard cmd.exe or PowerShell
  - Produces Windows DLL compatible with Erlang/OTP

The `build_windows.bat` script automatically detects and uses the available compiler.

## License

MIT License - See LICENSE.md in project root

