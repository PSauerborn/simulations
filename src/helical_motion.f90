module helical_motion
   use forces
   use types

   implicit none
   private

   public :: helical_motion_force

   !> @brief Composite force for helical motion simulation.
   !>
   !> Combines electromagnetic (Lorentz) and gravitational forces to
   !> simulate the helical trajectory of a charged particle in
   !> crossed electric and magnetic fields with gravity.
   type, extends(force_t) :: helical_motion_force
      real :: magnetic_field(3)  !< Magnetic field vector B (T)
      real :: electric_field(3)  !< Electric field vector E (V/m)
      real :: gravity(3)         !< Gravity vector (m/s^2), currently unused
   contains
      procedure, pass(this) :: get_force => get_helical_motion_force
   end type helical_motion_force

contains
   !> @brief Calculates the net force for helical motion simulation.
   !>
   !> Computes the total force acting on a charged particle by combining
   !> the Lorentz force (from electric and magnetic fields) and Earth's
   !> gravitational force.
   !>
   !> @param[in] this     The helical_motion_force instance with field config.
   !> @param[in] particle The PointParticle to calculate forces on.
   !>
   !> @return force The net 3D force vector (N).
   function get_helical_motion_force(this, particle) result(force)
      type(PointParticle), intent(in) :: particle
      class(helical_motion_force), intent(in) :: this
      type(lorentz_force_t) :: lorentz_force
      type(earth_gravity_force_t) :: gravity_force
      real :: force(3)

      ! create lorentz force using set electric and magnetic field
      lorentz_force = new_lorentz_force_t(this%electric_field, this%magnetic_field)
      ! create earth gravity force
      gravity_force = new_earth_gravity_force_t()

      ! calculate net force by adding together lorentz and gravity
      force = lorentz_force%get_force(particle) + gravity_force%get_force(particle)

   end function get_helical_motion_force

end module helical_motion
