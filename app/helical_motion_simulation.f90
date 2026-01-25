program helical_motion_simulation
   use utils
   use helical_motion
   use types
   use constants

   implicit none

   ! properties of point particle
   real :: initial_velocity(3) = [3.0, 0.0, 0.0]
   real :: initial_position(3) = [0.0, 0.0, 0.0]
   real :: charge = -1.0*e
   real :: mass = mass_proton

   ! properties of output
   character(len=256) :: output_dir = 'output', output_filename = 'helical_motion_trajectory.csv', output_path
   character(len=256) :: output_dir_override

   ! properties of simulation
   real :: magnetic_field(3) = [0.0, 0.0, 1.0]
   real :: delta_t = 0.01
   integer :: num_steps = 1000

   type(PointParticle) :: p

   real, allocatable :: trajectory(:, :)
   allocate (trajectory(num_steps, 3))

   ! read and set configuration settings. this includes
   ! settings on where to store output files.
   call read_config('etc/helical_motion.nml')

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

   ! write trajectory to output file
   print *, 'Writing output to: ', output_path
   call write_csv(output_path, trajectory)

   print *, 'Simulation finished'

contains
   !> @brief Reads simulation configuration from a namelist file.
   !>
   !> Loads simulation parameters from the specified namelist file, including
   !> particle properties, magnetic field settings, and output configuration.
   !> The output directory can be overridden via command-line argument.
   !>
   !> @param[in] filepath Path to the namelist configuration file.
   !>
   !> @note If a command-line argument is provided, it overrides the output_dir
   !>       setting from the namelist file. The final output_path is constructed
   !>       by combining the output directory with the output filename.
   !>
   !> @warning Terminates execution if the configuration file does not exist.
   subroutine read_config(filepath)
      character(len=*), intent(in) :: filepath
      integer :: num_args

      namelist /params/ &
         initial_velocity, &
         initial_position, &
         charge, &
         mass, &
         magnetic_field, &
         delta_t, &
         num_steps, &
         output_dir

      logical :: file_exists
      integer :: fu
      integer :: rc

      print *, 'Reading input parameters from: ', filepath

      ! check if input file exists
      inquire (file=filepath, exist=file_exists)
      if (.not. file_exists) then
         print *, 'Error: input file not found: ', filepath
         stop 1
      end if

      ! open and read input file
      open (newunit=fu, file=filepath, action='read')
      read (nml=params, iostat=rc, unit=fu)
      close (fu)

      ! check if output directory has been overridden by command line argument
      num_args = command_argument_count()
      if (num_args > 0) then
         call get_command_argument(1, output_dir_override)
         print *, 'Overriding configured output dir: ', output_dir_override
      else
         output_dir_override = ""
      end if
      ! set output path
      if (len_trim(output_dir_override) > 0) then
         output_path = trim(output_dir_override)//'/'//trim(output_filename)
      else
         output_path = trim(output_dir)//'/'//trim(output_filename)
      end if

   end subroutine read_config

end program helical_motion_simulation
