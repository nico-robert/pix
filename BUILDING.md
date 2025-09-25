Compilation :
-------------------------

### Installing Nim
If you don't have 👑 `Nim` installed yet (which is likely if you're coming from the `Tcl/Tk` world), here's how to get it:

**Option 1: Using choosenim (Recommended)**
```bash
# Install choosenim (Nim version manager)
curl https://nim-lang.org/choosenim/init.sh -sSf | sh

# Install latest stable Nim
choosenim stable
```

**Option 2: Direct download**
- Visit [nim-lang.org](https://nim-lang.org/install.html)
- Download the installer for your platform
- Follow the installation instructions

**Option 3: Package managers**
```bash
# macOS with Homebrew
brew install nim

# Ubuntu/Debian
apt-get install nim

# Windows with Chocolatey
choco install nim
```

After installation, verify Nim is working:
```bash
nim --version
nimble --version
```

### Prerequisites
To compile the `pix` library, you will need:
- [Nim](https://nim-lang.org) >= 2.0.6 (see installation above)
- [Pixie](https://github.com/treeform/pixie) >= 5.0.7
- `Tcl/Tk` 8.6 or 9.0 installed on your system
- GCC (or compatible C compiler)

### Path Configuration
Before compilation, **you must adapt** the `pix.nim.cfg` file according to your `Tcl/Tk` installation:

```nim
# Example for macOS with Homebrew:
--cincludes:"/usr/local/Cellar/tcl-tk/9.0.1/include/tcl-tk"
--clibdir:"/usr/local/Cellar/tcl-tk/9.0.1/lib"

# Example for Windows:
--cincludes:"C:/dev/Tcl90/include" 
--clibdir:"C:/dev/Tcl90/lib"

# Example for Linux:
--cincludes:"/opt/tcl90/include"
--clibdir:"/opt/tcl90/lib"
```

> [!IMPORTANT]
> Modify the paths in `pix.nim.cfg` file to match your `Tcl/Tk` installation.

### Automatic Compilation
The project includes a Nimble task to automatically compile the `Tcl/Tk` bindings.
Dependencies (Pixie) will be installed automatically:

```bash
# Compile libraries for both Tcl/Tk 8.6 and 9.0
cd path/to/pix
nimble pixTclTkBindings
```

This command automatically generates libraries in the appropriate folders according to your architecture:

**Windows:**
- `win32-x86_64/pix8-X.X.dll` (for Tcl/Tk 8.6)  
- `win32-x86_64/pix9-X.X.dll` (for Tcl/Tk 9.0)

**macOS:**
- `macosx-x86_64/lib8pixX.X.dylib` (Intel, for Tcl/Tk 8.6)
- `macosx-x86_64/lib9pixX.X.dylib` (Intel, for Tcl/Tk 9.0)
- `macosx-arm/lib8pixX.X.dylib` (Apple Silicon, for Tcl/Tk 8.6)
- `macosx-arm/lib9pixX.X.dylib` (Apple Silicon, for Tcl/Tk 9.0)

**Linux:**
- `linux-x86_64/lib8pixX.X.so` (for Tcl/Tk 8.6)
- `linux-x86_64/lib9pixX.X.so` (for Tcl/Tk 9.0)

### Manual Compilation
If you prefer to compile manually, you can use the following command:

```bash
# For Tcl/Tk 8.6 by example
nim c -d:tcl8 -d:useMalloc -d:release --out:win32-x86_64/pix8-X.X.dll src/pix.nim
```

> [!TIP]
> Pre-compiled binaries are available in the [Releases](https://github.com/nico-robert/pix/releases) section if you prefer to avoid compilation.