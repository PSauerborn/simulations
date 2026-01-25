module forces
   use constants

   implicit none
   private

   public :: lorentz_force, earth_gravity_force

contains
   pure function cross_product(a, b) result(output)
      real :: output(3)
      real, intent(in) :: a(3)
      real, intent(in) :: b(3)

      output(1) = a(2)*b(3) - a(3)*b(2)
      output(2) = a(3)*b(1) - a(1)*b(3)
      output(3) = a(1)*b(2) - a(2)*b(1)
   end function cross_product

   pure function lorentz_force(charge, velocity, magnetic_field) result(force)
      real :: force(3)
      real, intent(in) :: charge
      real, intent(in) :: velocity(3)
      real, intent(in) :: magnetic_field(3)

      force = charge*cross_product(velocity, magnetic_field)
   end function lorentz_force

   pure function earth_gravity_force(mass) result(force)
      real, intent(in) :: mass
      real :: force(3)

      force = [0.0, 0.0, -1.0*g_earth]*mass
   end function earth_gravity_force

end module forces
