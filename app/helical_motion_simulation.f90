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
   character(len=256) :: output_file = "output/helical_motion.csv"

   ! properties of magnetic field
   real :: magnetic_field(3) = [0.0, 0.0, 1.0]

   ! properties of simulation
   real :: delta_t = 0.01
   integer :: num_steps = 1000

   type(PointParticle) :: p

   real, allocatable :: trajectory(:, :)
   allocate (trajectory(num_steps, 3))

   call read_config("etc/helical_motion.nml")

   ! create new point particle instance and run simulation
   p = new_point_particle(initial_position, initial_velocity, mass, charge)

   call print_separator()
   print *, 'Running helical motion simulation'
   print *, 'Using magnetic field: ', magnetic_field
   print *, 'Using initial velocity: ', initial_velocity
   print *, 'Using initial position: ', initial_position
   print *, 'Using particle charge: ', charge

   trajectory = run_helical_motion_simulation(p, magnetic_field, delta_t, num_steps)

   call write_csv(output_file, trajectory)

   print *, 'Simulation finished'

contains
   subroutine read_config(filepath)
      character(len=*), intent(in) :: filepath

      namelist /params/ initial_velocity, initial_position, charge, mass, magnetic_field, output_file, delta_t, num_steps

      logical :: file_exists
      integer :: fu
      integer :: rc

      print *, 'Reading input parameters from: ', filepath

      inquire (file=filepath, exist=file_exists)
      if (.not. file_exists) then
         print *, 'Error: input file not found: ', filepath
         stop 1
      end if

      open (newunit=fu, file=filepath, action='read')
      read (nml=params, iostat=rc, unit=fu)
      close (fu)

   end subroutine read_config

end program helical_motion_simulation
