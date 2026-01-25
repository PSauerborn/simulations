# Simulations

Source code for Fortran simulations served by the simulation catalogue. This project contains physics-based simulations implemented in Fortran, managed with the [Fortran Package Manager (fpm)](https://fpm.fortran-lang.org/).

## Table of Contents

- [Project Overview](#project-overview)
  - [Current Simulations](#current-simulations)
- [Project Structure](#project-structure)
- [Configuration (Namelists)](#configuration-namelists)
- [Simulation Index](#simulation-index)
- [Make Commands](#make-commands)
- [Running Simulations](#running-simulations)
  - [Using Docker (Recommended)](#using-docker-recommended)
  - [Running Locally (via fpm)](#running-locally-via-fpm)
- [Requirements](#requirements)
- [License](#license)

## Project Overview

This repository contains Fortran-based simulations for modeling physical phenomena. The simulations are designed to be:

- **Configurable**: Simulation parameters are externalized through namelist files (`.nml`) for easy tuning without recompilation
- **Modular**: Core physics modules are separated from simulation entry points for reusability
- **Visualizable**: A Python utility script (`run_and_plot.py`) enables running simulations and visualizing output data

### Current Simulations

| Simulation | Description |
|------------|-------------|
| **Helical Motion** | Models a charged particle moving in a constant magnetic field, including gravitational effects to simulate horizontal drift |

## Project Structure

```
simulations/
├── app/                # Simulation entry points (executables)
│   └── helical_motion_simulation.f90
├── bin/                # Compiled binaries (generated)
├── build/              # Build artifacts (generated)
├── etc/                # Configuration files (namelists)
│   └── helical_motion.nml
├── output/             # Simulation output artifacts
│   ├── *.csv           # Generated trajectory data
│   ├── *.log           # Simulation run logs
│   └── *.png           # Generated plot images
├── src/                # Core Fortran modules
│   ├── constants.f90   # Physical constants
│   ├── forces.f90      # Force calculation routines
│   ├── helical_motion.f90  # Helical motion physics
│   ├── types.f90       # Custom data types
│   └── utils.f90       # Utility functions
├── .dockerignore       # Files excluded from Docker build
├── Dockerfile          # Docker image definition
├── fpm.toml            # Fortran Package Manager configuration
├── index.json          # Simulation catalogue index
├── Makefile            # Development and run commands
├── requirements.txt    # Python dependencies
├── run_and_plot.py     # Python runner and visualization script
└── README.md
```

### Key Directories

- **`etc/`** — Contains namelist (`.nml`) files used to configure simulations. These files define parameters such as initial conditions, physical constants, and output settings without requiring code changes.

- **`output/`** — Stores simulation output artifacts, typically CSV files containing trajectory data or other computed results. This directory is populated when simulations are executed.

## Configuration (Namelists)

Simulations are configured using Fortran namelist files stored in `etc/`. For example, `etc/helical_motion.nml`:

```fortran
&params
initial_velocity = 2.0, 0.0, 5.0
initial_position = 0.0, 0.0, 0.0
magnetic_field = 0.5, 0.0, 0.0
mass = 1.0
charge = 1.0
delta_t = 0.01
num_steps = 5000
output_dir = "output"
/
```

Modify these files to adjust simulation parameters without rebuilding the code.

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
| `make run-simulation simulation_id=<id>` | Builds and runs a simulation inside Docker, outputting results to `output/` |

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

# Run a specific simulation
fpm run --target helical_motion_simulation

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
