module forces
   use constants

   implicit none
   private

   public :: lorentz_force, earth_gravity_force

contains

   !> @brief Computes the cross product of two 3D vectors.
   !>
   !> @param[in] a First 3D vector.
   !> @param[in] b Second 3D vector.
   !>
   !> @return output The cross product a × b as a 3D vector.
   pure function cross_product(a, b) result(output)
      real :: output(3)
      real, intent(in) :: a(3)
      real, intent(in) :: b(3)

      output(1) = a(2)*b(3) - a(3)*b(2)
      output(2) = a(3)*b(1) - a(1)*b(3)
      output(3) = a(1)*b(2) - a(2)*b(1)
   end function cross_product

   !> @brief Calculates the Lorentz force on a charged particle.
   !>
   !> Computes the magnetic component of the Lorentz force: F = q(v × B).
   !>
   !> @param[in] charge         Electric charge of the particle (C).
   !> @param[in] velocity       3D velocity vector of the particle (m/s).
   !> @param[in] magnetic_field 3D magnetic field vector (T).
   !>
   !> @return force 3D force vector (N).
   pure function lorentz_force(charge, velocity, magnetic_field) result(force)
      real :: force(3)
      real, intent(in) :: charge
      real, intent(in) :: velocity(3)
      real, intent(in) :: magnetic_field(3)

      force = charge*cross_product(velocity, magnetic_field)
   end function lorentz_force

   !> @brief Calculates the gravitational force on Earth's surface.
   !>
   !> Computes the gravitational force acting on a mass at Earth's surface,
   !> directed in the negative z-direction: F = [0, 0, -mg].
   !>
   !> @param[in] mass Mass of the object (kg).
   !>
   !> @return force 3D gravitational force vector (N).
   pure function earth_gravity_force(mass) result(force)
      real, intent(in) :: mass
      real :: force(3)

      force = [0.0, 0.0, -1.0*g_earth]*mass
   end function earth_gravity_force

end module forces
