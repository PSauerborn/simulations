module forces
   use constants
   use types
   use utils

   implicit none
   private

   public :: new_lorentz_force_t, lorentz_force_t, new_earth_gravity_force_t, earth_gravity_force_t

   !> @brief Abstract base type for all force implementations.
   !>
   !> Provides a common interface for force calculations in simulations.
   !> Concrete subtypes must implement the get_force method to compute
   !> the force acting on a particle.
   type, abstract, public :: force_t
   contains
      procedure(force_proto), deferred, pass(this) :: get_force
   end type force_t

   !> @brief Interface for force calculation methods.
   !>
   !> Defines the signature that all force implementations must follow.
   abstract interface
      function force_proto(this, particle) result(force)
         import force_t
         import PointParticle
         class(force_t), intent(in) :: this   !< The force instance
         type(PointParticle), intent(in) :: particle  !< Particle to compute force on
         real :: force(3)  !< Resulting 3D force vector (N)
      end function force_proto
   end interface

   !> @brief Lorentz force implementation for charged particles.
   !>
   !> Computes the electromagnetic force on a charged particle using
   !> the Lorentz force law: F = q(E + v × B).
   type, extends(force_t) :: lorentz_force_t
      real :: magnetic_field(3)  !< Magnetic field vector B (T)
      real :: electric_field(3)  !< Electric field vector E (V/m)
   contains
      procedure, pass(this) :: get_force => lorentz_force
   end type lorentz_force_t

   !> @brief Earth surface gravitational force implementation.
   !>
   !> Computes the gravitational force on a particle at Earth's surface,
   !> directed in the negative z-direction: F = [0, 0, -mg].
   type, extends(force_t) :: earth_gravity_force_t
   contains
      procedure, pass(this) :: get_force => earth_gravity_force
   end type earth_gravity_force_t

contains

   !> @brief Constructs a new lorentz_force_t instance.
   !>
   !> Factory function to create and initialize a Lorentz force object
   !> with the specified electric and magnetic field vectors.
   !>
   !> @param[in] electric_field 3D electric field vector (V/m).
   !> @param[in] magnetic_field 3D magnetic field vector (T).
   !>
   !> @return force A fully initialized lorentz_force_t instance.
   function new_lorentz_force_t(electric_field, magnetic_field) result(force)
      real :: electric_field(3)
      real :: magnetic_field(3)
      type(lorentz_force_t) :: force

      force%magnetic_field = magnetic_field
      force%electric_field = electric_field

   end function new_lorentz_force_t

   !> @brief Calculates the Lorentz force on a charged particle.
   !>
   !> Computes the full Lorentz force: F = q(E + v × B), where E is the
   !> electric field, v is the particle velocity, and B is the magnetic field.
   !>
   !> @param[in] this     The lorentz_force_t instance containing field vectors.
   !> @param[in] particle The PointParticle to calculate the force on.
   !>
   !> @return force 3D Lorentz force vector (N).
   function lorentz_force(this, particle) result(force)
      real :: force(3)
      class(lorentz_force_t), intent(in) :: this
      type(PointParticle), intent(in) :: particle

      real :: charge
      real :: velocity(3)
      real :: magnetic_part(3)
      real :: electric_part(3)

      charge = particle%charge
      velocity = particle%state%velocity

      ! calculate magnetic and electric parts
      magnetic_part = cross_product(velocity, this%magnetic_field)
      electric_part = this%electric_field
      ! compute net lorentz force
      force = charge*(electric_part + magnetic_part)

   end function lorentz_force

   !> @brief Constructs a new earth_gravity_force_t instance.
   !>
   !> Factory function to create an Earth surface gravity force object.
   !> This force uses the standard gravitational acceleration constant g_earth.
   !>
   !> @return force A fully initialized earth_gravity_force_t instance.
   function new_earth_gravity_force_t() result(force)
      type(earth_gravity_force_t) :: force

   end function new_earth_gravity_force_t

   !> @brief Calculates the gravitational force on Earth's surface.
   !>
   !> Computes the gravitational force acting on a particle at Earth's surface,
   !> directed in the negative z-direction: F = [0, 0, -mg].
   !>
   !> @param[in] this     The earth_gravity_force_t instance.
   !> @param[in] particle The PointParticle to calculate the force on.
   !>
   !> @return force 3D gravitational force vector (N).
   function earth_gravity_force(this, particle) result(force)
      type(PointParticle), intent(in) :: particle
      class(earth_gravity_force_t), intent(in) :: this

      real :: force(3)

      force = [0.0, 0.0, -1.0*g_earth]*particle%mass
   end function earth_gravity_force
end module forces
