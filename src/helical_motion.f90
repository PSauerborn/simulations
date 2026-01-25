module helical_motion
   use types
   use forces

   implicit none
   private ! hide all variables

   public :: run_helical_motion_simulation ! export the function

contains ! required when defining functions in a module
   pure function get_force(charge, mass, velocity, magnetic_field) result(force)
      real, intent(in) :: charge
      real, intent(in) :: mass
      real, intent(in) :: velocity(3)
      real, intent(in) :: magnetic_field(3)

      real :: force(3)

      force = lorentz_force(charge, velocity, magnetic_field) + earth_gravity_force(mass)

   end function get_force

   pure function calculate_trajectory_update(magnetic_field, charge, mass, initial_state, delta_t) result(final_state)
      real, intent(in) :: charge
      real, intent(in) :: mass
      real, intent(in) :: magnetic_field(3)
      real, intent(in) :: delta_t
      type(MechanicalState), intent(in) :: initial_state
      type(MechanicalState) :: final_state
      real :: force(3)
      real :: acceleration(3)

      force = get_force(charge, mass, initial_state%velocity, magnetic_field)
      acceleration = force/mass

      ! do initial velocity and position update
      final_state%velocity = initial_state%velocity + 0.5*acceleration*delta_t
      final_state%position = initial_state%position + final_state%velocity*delta_t

      force = get_force(charge, mass, final_state%velocity, magnetic_field)
      acceleration = force/mass

      ! do final velocity update
      final_state%velocity = final_state%velocity + 0.5*acceleration*delta_t

   end function calculate_trajectory_update

! pure functions are functions that do not have side effects such as printing to the console
   pure function run_helical_motion_simulation(particle, magnetic_field, delta_t, num_steps) result(trajectory)
      type(PointParticle), intent(in) :: particle
      real, intent(in) :: magnetic_field(3)
      real, intent(in) :: delta_t
      integer, intent(in) :: num_steps
      integer :: i
      type(MechanicalState) :: state

      real, allocatable :: trajectory(:, :)
      allocate (trajectory(num_steps, 3))

      state%position = particle%pos
      state%velocity = particle%vel

      do i = 1, num_steps
         ! update state with new trajectory and append to list of results
         state = calculate_trajectory_update(magnetic_field, particle%charge, particle%mass, state, delta_t)
         trajectory(i, :) = state%position
      end do
   end function run_helical_motion_simulation

end module helical_motion
