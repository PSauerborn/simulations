module types
   implicit none
   private ! hide all variables

   public :: MechanicalState, PointParticle, new_point_particle

   type :: MechanicalState
      real :: position(3)
      real :: velocity(3)
   end type MechanicalState

   type :: PointParticle
      real :: pos(3)
      real :: vel(3)
      real :: mass
      real :: charge = 0.0
   end type PointParticle

contains
   ! constructor for PointParticle type
   function new_point_particle(pos, vel, mass, charge) result(p)
      real, intent(in) :: pos(3)
      real, intent(in) :: vel(3)
      real, intent(in) :: mass
      real, intent(in) :: charge

      type(PointParticle) :: p

      p%pos = pos
      p%vel = vel
      p%mass = mass
      p%charge = charge
   end function new_point_particle

end module types
