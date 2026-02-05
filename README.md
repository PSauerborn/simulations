# Simulations

Source code for Fortran simulations served by the simulation catalogue. This project contains physics-based simulations implemented in Fortran, managed with the [Fortran Package Manager (fpm)](https://fpm.fortran-lang.org/). All the simulations in this repository can be explored online using the Simulation Catalogue web app (link [here](https://simulation-catalogue.s31-software.com)).

## Table of Contents

- [Project Overview](#project-overview)
  - [Current Simulations](#current-simulations)
- [Framework Architecture](#framework-architecture)
  - [How Simulations Work](#how-simulations-work)
  - [Integrators](#integrators)
  - [Forces](#forces)
- [Project Structure](#project-structure)
- [Configuration (TOML)](#configuration-toml)
- [Simulation Index](#simulation-index)
- [Make Commands](#make-commands)
- [Building Executables](#building-executables)
- [CI/CD Pipelines](#cicd-pipelines)
  - [Pre-Merge Checks](#pre-merge-checks)
  - [Release Workflow](#release-workflow)
- [Running Simulations](#running-simulations)
  - [Using Docker (Recommended)](#using-docker-recommended)
  - [Running Locally (via fpm)](#running-locally-via-fpm)
- [Requirements](#requirements)
- [License](#license)

## Project Overview

This repository contains Fortran-based simulations for modeling physical phenomena. The simulations are designed to be:

- **Configurable**: Simulation parameters are externalized through TOML configuration files (`.toml`) for easy tuning without recompilation
- **Modular**: Core physics modules are separated from simulation entry points for reusability
- **Visualizable**: A Python utility script (`run_and_plot.py`) enables running simulations and visualizing output data

All of the simulations in this repository can be explored interactively via the [Simulation Catalogue](https://github.com/psauerborn/simulation-catalogue).

### Current Simulations

| Simulation | Description |
|------------|-------------|
| **Helical Motion** | Models a charged particle moving in crossed electric and magnetic fields, including gravitational effects |

## Framework Architecture

All simulations in this repository are designed to be ran using the online simulation catalogue. This requires that all simulations adhere to the same underlying framework for configuration, execution and output of results.

Broadly speaking, all simulations run the following execution sequencer:

1. **Configuration**: A TOML file is passed as the only command-line argument, containing all simulation parameters (initial conditions, field strengths, time step, etc.). Critically, an `output_dir` parameter is provided in __all__ TOML files, which specifies the output location for any simulation outputs.

2. **Initialization**: The simulation reads the config, and initializes all required parameters.

3. **Time Loop**: The actual simulation is ran.

4. **Output**: Results are written to CSV files in the configured output directory

### Integrators

Integrators implement the `integrator_t` abstract type and provide a time-stepping algorithm via the `integrate_step` method.

#### Interface

```fortran
type, abstract :: integrator_t
   real :: delta_t  ! Time step (s)
contains
   procedure(step_proto), deferred :: integrate_step
end type

! All integrators must implement:
subroutine integrate_step(this, particle, force)
   class(integrator_t), intent(in) :: this
   type(PointParticle), intent(inout) :: particle
   class(force_t) :: force
end subroutine
```

#### Available Integrators

| Integrator | Type | Description |
|------------|------|-------------|
| **Velocity Verlet** | `verlet_t` | Symplectic integrator, second-order accurate. Good for Hamiltonian systems. |
| **Boris Push** | `boris_t` | Specialized for charged particles in magnetic fields. Exactly conserves phase space volume and handles velocity-dependent Lorentz force correctly. |

#### Creating a New Integrator

To add a new integrator, extend `integrator_t` and implement `integrate_step`:

```fortran
type, extends(integrator_t) :: my_integrator_t
contains
   procedure, pass(this) :: integrate_step => my_step
end type

subroutine my_step(this, particle, force)
   class(my_integrator_t), intent(in) :: this
   type(PointParticle), intent(inout) :: particle
   class(force_t) :: force

   ! Your integration algorithm here
end subroutine
```

### Forces

Forces implement the `force_t` abstract type and compute the force acting on a particle via the `get_force` method.

#### Interface

```fortran
type, abstract :: force_t
contains
   procedure(force_proto), deferred :: get_force
end type

! All forces must implement:
function get_force(this, particle) result(force)
   class(force_t), intent(in) :: this
   type(PointParticle), intent(in) :: particle
   real :: force(3)
end function
```

#### Available Forces

| Force | Type | Description |
|-------|------|-------------|
| **Lorentz Force** | `lorentz_force_t` | Electromagnetic force: F = q(E + v × B) |
| **Earth Gravity** | `earth_gravity_force_t` | Surface gravity: F = [0, 0, -mg] |
| **Helical Motion** | `helical_motion_force_t` | Composite force combining Lorentz and gravity for helical trajectory simulations |

#### Creating a New Force

To add a new force, extend `force_t` and implement `get_force`:

```fortran
type, extends(force_t) :: my_force_t
   real :: some_parameter
contains
   procedure, pass(this) :: get_force => compute_my_force
end type

function compute_my_force(this, particle) result(force)
   class(my_force_t), intent(in) :: this
   type(PointParticle), intent(in) :: particle
   real :: force(3)

   ! Your force calculation here
   force = [0.0, 0.0, -9.81 * particle%mass]
end function
```

#### Composite Forces

Forces can be combined by creating a composite force type that calls multiple underlying forces:

```fortran
function get_helical_motion_force(this, particle) result(force)
   ! ...
   lorentz_force = new_lorentz_force_t(this%electric_field, this%magnetic_field)
   gravity_force = new_earth_gravity_force_t()

   force = lorentz_force%get_force(particle) + gravity_force%get_force(particle)
end function
```

## Project Structure

```
simulations/
├── app/                # Simulation entry points (executables)
│   └── helical_motion_simulation.f90
├── bin/                # Compiled binaries (generated)
├── build/              # Build artifacts (generated)
├── etc/                # Configuration files (TOML)
│   └── helical_motion.toml
├── output/             # Simulation output artifacts
│   ├── *.csv           # Generated trajectory data
│   ├── *.log           # Simulation run logs
│   └── *.png           # Generated plot images
├── src/                # Core Fortran modules
│   ├── constants.f90   # Physical constants
│   ├── forces.f90      # Force implementations and interface
│   ├── integrators.f90 # Integrator implementations and interface
│   ├── helical_motion.f90  # Helical motion composite force
│   ├── types.f90       # Custom data types (PointParticle, etc.)
│   └── utils.f90       # Utility functions (CSV output, etc.)
├── scripts/            # Build and utility scripts
│   └── build_executables.sh  # Builds executables with arch suffix
├── .dockerignore       # Files excluded from Docker build
├── Dockerfile          # Runtime Docker image
├── Dockerfile.build    # Build Docker image for compiling executables
├── fpm.toml            # Fortran Package Manager configuration
├── index.json          # Simulation catalogue index
├── Makefile            # Development and run commands
├── requirements.txt    # Python dependencies
├── run_and_plot.py     # Python runner and visualization script
└── README.md
```

### Key Directories

- **`etc/`** — Contains TOML (`.toml`) configuration files used to configure simulations. These files define parameters such as initial conditions, physical constants, and output settings without requiring code changes.

- **`output/`** — Stores simulation output artifacts, typically CSV files containing trajectory data or other computed results. This directory is populated when simulations are executed.

## Configuration (TOML)

Simulations are configured using TOML files stored in `etc/`. For example, `etc/helical_motion.toml`:

```toml
[parameters]
initial_velocity = [2.0, 0.0, 5.0]
initial_position = [0.0, 0.0, 0.0]
magnetic_field = [0.5, 0.0, 0.0]
mass = 1.0
charge = 1.0
delta_t = 0.01
num_steps = 5000

[config]
output_dir = "output"
```

The configuration is organized into sections:

| Section | Description |
|---------|-------------|
| `[parameters]` | Physical simulation parameters (initial conditions, particle properties, simulation settings) |
| `[config]` | Output and runtime configuration |

Modify these files to adjust simulation parameters without rebuilding the code.

### Command-Line Override

Each simulation accepts an optional command-line argument specifying the path to the TOML configuration file. If no argument is provided, the simulation uses its default config path (e.g., `etc/helical_motion.toml` for the helical motion simulation).

```bash
# Run with default config
fpm run --target helical_motion_simulation

# Run with custom config path
fpm run --target helical_motion_simulation -- /path/to/custom_config.toml
```

## Simulation Index

The project uses an `index.json` file to define available simulations. This acts as a catalogue that maps simulation IDs to their metadata and configuration:

```json
{
    "simulations": [
        {
            "id": "helical_motion_simulation",
            "name": "Charged Particle in a constant magnetic field",
            "entrypoint": "helical_motion_simulation",
            "output_type": "trajectory",
            "output_path": "helical_motion_trajectory.csv",
            "dimensions": 3,
            "description": "Model to simulate a charged particle moving in a magnetic field."
        }
    ]
}
```

Each simulation entry contains:

| Field | Description |
|-------|-------------|
| `id` | Unique identifier used to reference the simulation |
| `name` | Human-readable name for the simulation |
| `entrypoint` | The fpm target name (executable) to run |
| `output_type` | Type of output data (e.g., `trajectory` for 3D path data) |
| `output_path` | Path where the simulation writes its output CSV |
| `dimensions` | Dimensionality of the output data |
| `description` | Brief description of what the simulation models |

The `run_and_plot.py` script uses this index to locate and run simulations by their ID.

## Make Commands

The project includes the following Make commands:

| Command | Description |
|---------|-------------|
| `make lint` | Runs code formatting tools: `fprettify` for Fortran source files and `black` for Python files |
| `make build` | Compiles simulation executables inside Docker for the host architecture and outputs them to `bin/` |
| `make build cpu_arch=arm64` | Cross-compiles executables for ARM64 architecture |
| `make build cpu_arch=amd64` | Cross-compiles executables for x86-64 architecture |
| `make run-simulation simulation_id=<id>` | Builds and runs a simulation inside Docker, outputting results to `output/` |
| `make scan-secrets` | Scans for secrets using detect-secrets |

## Building Executables

The project includes a Docker-based build system for compiling standalone executables, useful for deployment or distribution.

### Build Command

```bash
# Build for current host architecture
make build

# Cross-compile for specific architecture
make build cpu_arch=arm64   # For ARM64 (Apple Silicon, AWS Graviton, etc.)
make build cpu_arch=amd64   # For x86-64 (Intel/AMD)
```

This command:
1. Builds a Docker image with all compilation dependencies (gfortran, fpm)
2. Uses QEMU emulation for cross-compilation when targeting a different architecture
3. Compiles all simulation executables inside the container
4. Copies the resulting binaries to the local `bin/` directory with an architecture suffix

### Output

Executables are placed in `bin/` with the CPU architecture appended:

```
bin/
├── helical_motion_simulation_arm64     # ARM64 (Apple Silicon, etc.)
└── helical_motion_simulation_amd64     # x86-64 (Intel/AMD)
```

The architecture suffix is determined by the `cpu_arch` parameter (or auto-detected from the host using `uname -m`).

### Build Script

The build process is handled by `scripts/build_executables.sh`, which:
1. Creates necessary directories (`bin/`, `temp/`)
2. Runs `fpm install` to compile executables into a temp directory
3. Copies each executable to `bin/` with the CPU architecture suffix

## CI/CD Pipelines

The project uses GitHub Actions for continuous integration and release automation.

### Pre-Merge Checks

**Workflow:** `.github/workflows/pre-merge.yaml`

Runs automatically on pull requests to `master`. Validates that the code compiles successfully for both architectures.

| Step | Description |
|------|-------------|
| Build Matrix | Compiles for both `arm64` and `amd64` using Docker + QEMU |
| Validation | Ensures all simulation executables build without errors |

### Release Workflow

**Workflow:** `.github/workflows/release.yaml`

Manually triggered workflow to create a new release with compiled binaries.

```bash
# Trigger via GitHub Actions UI with version input (e.g., "1.2.3")
```

| Step | Description |
|------|-------------|
| Build Matrix | Compiles for both `arm64` and `amd64` architectures |
| Upload Artifacts | Stores binaries as workflow artifacts |
| Commit Binaries | Commits compiled binaries to `bin/` directory on `master` |
| Create Tag | Creates a git tag with the specified version |

#### Release Process

1. Navigate to **Actions** → **Prepare Release** in GitHub
2. Click **Run workflow**
3. Enter the version number (e.g., `1.0.0`)
4. The workflow will:
   - Build binaries for ARM64 and AMD64
   - Commit them to the `bin/` directory
   - Create and push a git tag

## Running Simulations

### Using Docker (Recommended)

The easiest way to run simulations is via Docker using the Makefile. This ensures a consistent environment with all dependencies pre-installed:

```bash
# Run a simulation by its ID
make run-simulation simulation_id=helical_motion_simulation
```

This command:
1. Builds the Docker image with all required dependencies (gfortran, fpm, Python packages)
2. Runs the simulation inside the container
3. Mounts the local `output/` directory so results are saved to your host machine

#### Output Structure

Simulation outputs are organized in a hierarchical, partitioned directory structure under `output/`:

```
output/
└── id={simulation_id}/
    └── ts={unix_timestamp}/
        ├── {output_filename}.csv    # Raw simulation data
        ├── simulation.log           # Simulation run log
        └── trajectory_*.png         # Generated plot images (multiple views)
```

For example, running `helical_motion_simulation` produces:

```
output/
└── id=helical_motion_simulation/
    └── ts=1737817200/
        ├── helical_motion_trajectory.csv
        ├── simulation.log
        ├── trajectory_isometric.png
        ├── trajectory_front_xz.png
        ├── trajectory_side_yz.png
        └── trajectory_top_xy.png
```

Each run creates a new timestamped directory, preserving outputs from previous runs for comparison.

**Output artifacts include:**

| File | Description |
|------|-------------|
| `*.csv` | Raw simulation output data (e.g., trajectory coordinates) |
| `simulation.log` | Captured stdout from the Fortran simulation execution |
| `trajectory_*.png` | 3D trajectory visualizations from multiple viewing angles |

### Running Locally (via fpm)

If you have the required dependencies installed locally, you can use `fpm` directly:

```bash
# Build all simulations
fpm build

# Run a specific simulation (uses default config)
fpm run --target helical_motion_simulation

# Run with a custom config file
fpm run --target helical_motion_simulation -- etc/helical_motion.toml

# Run with the Python visualization wrapper
python run_and_plot.py --simulation_id helical_motion_simulation
```

## Requirements

### For Docker-based execution (recommended)
- **Docker**: [Install Docker](https://docs.docker.com/get-docker/)

### For local execution
- **Fortran Compiler**: A modern Fortran compiler (e.g., gfortran)
- **fpm**: [Fortran Package Manager](https://fpm.fortran-lang.org/)
- **Python 3**: With packages listed in `requirements.txt` (`matplotlib`, `polars`, `pydantic`, `structlog`, `fpm`)
- **fprettify**: For Fortran code formatting (`pip install fprettify`)
- **black**: For Python code formatting (`pip install black`)

## License

See [LICENSE](LICENSE) for details.
