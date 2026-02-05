module helical_motion
   use forces
   use types

   implicit none
   private

   public :: helical_motion_force_t, new_helical_motion_force_t

   !> @brief Composite force for helical motion simulation.
   !>
   !> Combines electromagnetic (Lorentz) and gravitational forces to
   !> simulate the helical trajectory of a charged particle in
   !> crossed electric and magnetic fields with gravity.
   type, extends(force_t) :: helical_motion_force_t
      real :: magnetic_field(3)  !< Magnetic field vector B (T)
      real :: electric_field(3)  !< Electric field vector E (V/m)
   contains
      procedure, pass(this) :: get_force => get_helical_motion_force
   end type helical_motion_force_t

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
      class(helical_motion_force_t), intent(in) :: this
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

   !> @brief Constructs a new helical_motion_force_t instance.
   !>
   !> Factory function to create a composite force object for helical
   !> motion simulations with the specified electromagnetic field vectors.
   !>
   !> @param[in] electric_field 3D electric field vector E (V/m).
   !> @param[in] magnetic_field 3D magnetic field vector B (T).
   !>
   !> @return force A fully initialized helical_motion_force_t instance.
   function new_helical_motion_force_t(electric_field, magnetic_field) result(force)
      real, intent(in) :: electric_field(3), magnetic_field(3)
      type(helical_motion_force_t) :: force

      force%magnetic_field = magnetic_field
      force%electric_field = electric_field

   end function new_helical_motion_force_t

end module helical_motion
