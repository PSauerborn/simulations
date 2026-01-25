import json
import subprocess
from datetime import datetime
from enum import Enum
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import polars as pl
import structlog
from pydantic import BaseModel, Field, StringConstraints
from typing_extensions import Annotated

LOGGER = structlog.get_logger()


class SimulationOutputTypeEnum(Enum):
    TRAJECTORY = "trajectory"


class Simulation(BaseModel):
    simulation_id: Annotated[str, StringConstraints(min_length=1), Field(alias="id")]
    name: Annotated[str, StringConstraints(min_length=1)]
    entrypoint: Annotated[str, StringConstraints(min_length=1)]
    output_type: SimulationOutputTypeEnum
    output_path: Annotated[str, StringConstraints(min_length=1)]
    dimensions: int
    description: str


class SimulationIndex(BaseModel):
    simulations: list[Simulation]

    def get_simulation(self, simulation_id: str) -> Simulation | None:
        """Get a simulation by its ID."""

        for simulation in self.simulations:
            if simulation.simulation_id == simulation_id:
                return simulation


def load_index() -> SimulationIndex:
    """Load the simulation index from the index.json file."""

    with open("index.json", "r") as f:
        index_data = json.load(f)
    return SimulationIndex(**index_data)


def load_output_data(simulation: Simulation) -> pl.DataFrame:
    """Load the output data from the output directory."""

    df = pl.read_csv(simulation.output_path, has_header=False)
    match simulation.output_type:
        case SimulationOutputTypeEnum.TRAJECTORY:
            df = df.rename({"column_1": "x", "column_2": "y", "column_3": "z"})

    return df


def run_simulation(simulation: Simulation, binary_path: str, output_path: Path):
    """Run the simulation."""

    with open(output_path, "w") as f:
        subprocess.run(
            [binary_path, "run", "--target", simulation.entrypoint],
            check=True,
            stdout=f,
        )


def plot_trajectory(df: pl.DataFrame, output_path: Path):
    """Plot the trajectory."""

    fig = plt.figure(figsize=(10, 8))
    # create 3d plot
    ax = fig.add_subplot(111, projection="3d")

    xs = df["x"].to_numpy()
    ys = df["y"].to_numpy()
    zs = df["z"].to_numpy()

    # plot trajectory and markers for start and end
    ax.plot(xs, ys, zs, label="Trajectory", color="b", lw=2)
    ax.scatter([xs[0]], [ys[0]], [zs[0]], color="g", s=100, label="Start")
    ax.scatter([xs[-1]], [ys[-1]], [zs[-1]], color="r", s=100, label="End")

    ax.set_xlabel("X Position (m)")
    ax.set_ylabel("Y Position (m)")
    ax.set_zlabel("Z Position (m)")
    ax.legend()

    max_range = (
        np.array([xs.max() - xs.min(), ys.max() - ys.min(), zs.max() - zs.min()]).max()
        / 2.0
    )
    mid_x = (xs.max() + xs.min()) * 0.5
    mid_y = (ys.max() + ys.min()) * 0.5
    mid_z = (zs.max() + zs.min()) * 0.5
    ax.set_xlim(mid_x - max_range, mid_x + max_range)
    ax.set_ylim(mid_y - max_range, mid_y + max_range)
    ax.set_zlim(mid_z - max_range, mid_z + max_range)

    plt.savefig(output_path)
    plt.close()


def main(args):

    log = LOGGER.bind(simulation_id=args.simulation_id)

    index = load_index()
    # get simulation by id
    simulation = index.get_simulation(args.simulation_id)
    if simulation is None:
        log.error("Simulation with provided id not found.")
        raise ValueError(f"Simulation '{args.simulation_id}' not found.")

    output_path = Path(args.output_dir)
    # current timestamp. used for log and plot file names
    start_ts = datetime.now().timestamp()

    # construct log and plot file paths to save output
    log_file_path = output_path / f"{args.simulation_id}_{int(start_ts)}.log"
    plot_path = output_path / f"{args.simulation_id}_{int(start_ts)}.png"

    log.info("Running simulation.")
    # run simulation. log files are saved to log_file_path
    run_simulation(simulation, args.fpm_binary_path, log_file_path)

    end_ts = datetime.now().timestamp()
    log.info(
        "Simulation finished.",
        duration_seconds=round(end_ts - start_ts, 2),
        log_file=log_file_path.name,
    )

    # load output data and plot
    df = load_output_data(simulation)
    match simulation.output_type:
        case SimulationOutputTypeEnum.TRAJECTORY:
            plot_trajectory(df, plot_path)
            log.info("Plot saved.", path=plot_path.name)


if __name__ == "__main__":

    from argparse import ArgumentParser

    parser = ArgumentParser()

    parser.add_argument("--simulation_id", type=str, required=True)
    parser.add_argument("--fpm-binary-path", type=str, required=False, default="fpm")
    parser.add_argument("--output-dir", type=str, required=False, default="output")

    args = parser.parse_args()

    main(args)
