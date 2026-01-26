program helical_motion_simulation
   use utils
   use helical_motion
   use config
   use types
   use constants
   use tomlf

   implicit none

   ! properties of point particle
   real, allocatable :: initial_velocity(:)
   real, allocatable :: initial_position(:)
   real, allocatable :: magnetic_field(:)
   real :: charge
   real :: mass
   ! properties of output
   character(len=:), allocatable :: output_dir
   character(len=256) :: output_filename
   ! properties of simulation
   real :: delta_t
   integer :: num_steps

   type(PointParticle) :: p

   real, allocatable :: trajectory(:, :)
   allocate (trajectory(num_steps, 3))

   call load_config()

   ! create new point particle instance and run simulation
   p = new_point_particle(initial_position, initial_velocity, mass, charge)

   call print_separator()
   print *, 'Running helical motion simulation'
   print *, 'Using magnetic field: ', magnetic_field
   print *, 'Using initial velocity: ', initial_velocity
   print *, 'Using initial position: ', initial_position
   print *, 'Using particle charge: ', charge

   ! run simulation and calculate trajectory
   trajectory = run_helical_motion_simulation(p, magnetic_field, delta_t, num_steps)

   output_filename = trim(output_dir)//'/'//'trajectory.csv'
   ! write trajectory to output file
   print *, 'Writing output to: ', output_filename
   call write_csv(output_filename, trajectory)

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

      ! get specific sections of configuration file
      call get_value(table, "parameters", parameters_section, stat=stat)
      if (stat /= 0) then
         print *, 'Error: invalid configuration'
         stop 1
      end if

      call get_value(table, "config", config_section, stat=stat)
      if (stat /= 0) then
         print *, 'Error: invalid configuration'
         stop 1
      end if

      ! get array values containing initial positions, velocity and fields
      call expect_real_array_value(parameters_section, "initial_velocity", initial_velocity)
      call expect_real_array_value(parameters_section, "initial_position", initial_position)
      call expect_real_array_value(parameters_section, "magnetic_field", magnetic_field)

      ! get parameters for charge and mass
      call expect_real_value(parameters_section, "charge", charge)
      call expect_real_value(parameters_section, "mass", mass)

      ! get parameters for simulation
      call expect_real_value(parameters_section, "delta_t", delta_t)
      call expect_integer_value(parameters_section, "num_steps", num_steps)

      ! get configuration settings
      call expect_char_value(config_section, "output_dir", output_dir)

   end subroutine load_config
end program helical_motion_simulation
