program helical_motion_simulation
   use utils
   use config
   use types
   use constants
   use tomlf
   use forces
   use integrators
   use helical_motion

   implicit none

   ! properties of point particle
   real, allocatable :: initial_velocity(:)
   real, allocatable :: initial_position(:)
   real, allocatable :: magnetic_field(:)
   real, allocatable :: electric_field(:)
   real, allocatable :: trajectory(:, :)

   real :: charge
   real :: mass
   real :: delta_t
   integer :: num_steps
   integer :: i

   character(len=:), allocatable :: output_dir

   type(PointParticle) :: p
   type(CSVOutput) :: csv
   type(boris_t) :: integrator
   type(helical_motion_force_t) :: force

   ! read TOML configuration file and set values
   ! for all required parameters. this MUST be done
   ! first to ensure that simulation parameters are loaded
   ! into memory.
   call load_config()

   ! allocate trajectory array
   allocate (trajectory(num_steps, 3))

   call print_separator()
   print *, 'Running helical motion simulation'
   print *, 'Using magnetic field: ', magnetic_field
   print *, 'Using electric field: ', electric_field
   print *, 'Using initial velocity: ', initial_velocity
   print *, 'Using initial position: ', initial_position
   print *, 'Using particle charge: ', charge

   ! create new point particle instance
   p = new_point_particle(initial_position, initial_velocity, mass, charge)

   ! use boris integrator. this performs better for simulations
   ! involving velocity-dependent forces that produce rotations
   ! (such as a magnetic field).
   integrator = new_boris_integrator(delta_t, magnetic_field)

   ! set properties of magnetic and electric field
   ! IMPORTANT: magnetic field is set to 0 as we are using
   ! the boris integrator, which already incorporates the magnetic field
   force = new_helical_motion_force_t(electric_field, [0.0, 0.0, 0.0])

   ! perform numerical integration using verlet operator
   ! and helical motion force
   do i = 1, num_steps
      call integrator%integrate_step(p, force)
      ! add updated position to trajectory list
      trajectory(i, :) = p%state%position
   end do

   csv%filename = trim(output_dir)//'/'//'trajectory.csv'
   csv%header = ["x1", "x2", "x3"]
   csv%values = trajectory

   ! write trajectory to output file
   print *, 'Writing output to: ', csv%filename
   call write_csv(csv)

   print *, 'Simulation finished'

contains
   !> @brief Reads simulation configuration from a TOML config file.
   !>
   !> Loads simulation parameters from a TOML configuration file, including:
   !> - Particle properties: initial_velocity, initial_position, charge, mass
   !> - Magnetic field settings: magnetic_field vector
   !> - Simulation parameters: delta_t (time step), num_steps (iteration count)
   !> - Output configuration: output_dir
   !>
   !> The default config path is 'etc/helical_motion.toml', which can be
   !> overridden by providing a path as the first command-line argument.
   !>
   !> @note If a command-line argument is provided, it specifies the path to
   !>       the TOML configuration file to use instead of the default.
   !>
   !> @warning Terminates execution with an error if the configuration file
   !>          cannot be loaded or contains invalid configuration.
   subroutine load_config()
      character(len=256) :: config_path = 'etc/helical_motion.toml'
      integer :: n_args, stat
      ! parsed toml configuration
      type(toml_table), allocatable :: table
      type(toml_error), allocatable :: error
      type(toml_table), pointer :: parameters_section, config_section ! these need to be pointers

      ! get command line arguments. config path is first argument
      ! if no arguments are provided, use default config path
      n_args = command_argument_count()
      if (n_args > 0) then
         call get_command_argument(1, config_path)
      end if

      call toml_load(table, config_path, error=error)
      ! allocated checks if the array has been allocated a length,
      ! which occurs if any errors are added.
      if (allocated(error)) then
         print '(a)', error%message
         stop 1
      end if

      ! parameters section contains simulation params
      call get_value(table, "parameters", parameters_section, stat=stat)
      if (stat /= 0) then
         print *, 'Error: invalid configuration'
         stop 1
      end if

      ! config section contains configuration settings
      call get_value(table, "config", config_section, stat=stat)
      if (stat /= 0) then
         print *, 'Error: invalid configuration'
         stop 1
      end if

      ! get array values containing initial positions, velocity and fields
      call read_config_value(parameters_section, "initial_velocity", initial_velocity)
      call read_config_value(parameters_section, "initial_position", initial_position)
      call read_config_value(parameters_section, "magnetic_field", magnetic_field)
      call read_config_value(parameters_section, "electric_field", electric_field)

      ! get parameters for charge and mass
      call read_config_value(parameters_section, "charge", charge)
      call read_config_value(parameters_section, "mass", mass)

      ! get parameters for simulation
      call read_config_value(parameters_section, "delta_t", delta_t)
      call read_config_value(parameters_section, "num_steps", num_steps)

      ! get configuration settings
      call read_config_value(config_section, "output_dir", output_dir)

   end subroutine load_config
end program helical_motion_simulation
