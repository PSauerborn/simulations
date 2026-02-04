module types
   implicit none
   private ! hide all variables

   public :: MechanicalState, PointParticle, CSVOutput, new_point_particle, new_csv_output

   !> @brief Represents the mechanical state of a particle.
   !>
   !> Contains the kinematic properties (position and velocity) of a
   !> particle in 3D Cartesian coordinates.
   type :: MechanicalState
      real :: position(3)  !< 3D position vector (m)
      real :: velocity(3)  !< 3D velocity vector (m/s)
   end type MechanicalState

   !> @brief Represents a point particle in 3D space.
   !>
   !> A particle with mechanical state (position, velocity), mass, and
   !> optional electric charge for use in physics simulations.
   type :: PointParticle
      type(MechanicalState) :: state  !< Current position and velocity
      real :: mass                     !< Particle mass (kg)
      real :: charge = 0.0             !< Electric charge (C), default 0
   end type PointParticle

   !> @brief Container for CSV file output data.
   !>
   !> Holds the filename, header row, and 2D array of values to be
   !> written to a CSV file.
   type :: CSVOutput
      character(len=:), allocatable :: filename   !< Output file path
      character(len=:), allocatable :: header(:)  !< Column header strings
      real, allocatable :: values(:, :)           !< Data values (rows x columns)
   end type CSVOutput

contains

   !> @brief Constructs a new CSVOutput instance.
   !>
   !> Factory function to create and initialize a CSVOutput with the
   !> specified filename, header row, and data values.
   !>
   !> @param[in] filename Path to the output CSV file.
   !> @param[in] header   Array of column header strings.
   !> @param[in] values   2D array of real values (rows x columns).
   !>
   !> @return out A fully initialized CSVOutput instance.
   function new_csv_output(filename, header, values) result(out)
      character(len=*), intent(in) :: filename
      character(len=*), intent(in) :: header(:)
      real, intent(in) :: values(:, :)

      type(CSVOutput) :: out

      out%values = values
      out%filename = filename
      out%header = header
   end function new_csv_output

   !> @brief Constructs a new PointParticle instance.
   !>
   !> Factory function to create and initialize a PointParticle with the
   !> specified physical properties.
   !>
   !> @param[in] pos    Initial 3D position vector (m).
   !> @param[in] vel    Initial 3D velocity vector (m/s).
   !> @param[in] mass   Mass of the particle (kg).
   !> @param[in] charge Electric charge of the particle (C).
   !>
   !> @return p A fully initialized PointParticle instance.
   function new_point_particle(pos, vel, mass, charge) result(p)
      real, intent(in) :: pos(3)
      real, intent(in) :: vel(3)
      real, intent(in) :: mass
      real, intent(in) :: charge

      type(MechanicalState) :: initial_state
      type(PointParticle) :: p

      initial_state%position = pos
      initial_state%velocity = vel

      p%mass = mass
      p%charge = charge
      p%state = initial_state

   end function new_point_particle

end module types
