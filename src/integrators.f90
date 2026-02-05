module integrators
   use types
   use forces
   use utils

   implicit none
   private

   public :: new_verlet_integrator, verlet_t, new_boris_integrator, boris_t

   !> @brief Abstract base type for numerical integrators.
   !>
   !> Provides a common interface for time-stepping algorithms.
   !> Concrete subtypes must implement the integrate_step method.
   type, abstract, public :: integrator_t
      real :: delta_t  !< Time step for integration (s)
   contains
      procedure(step_proto), deferred, pass(this) :: integrate_step
   end type integrator_t

   !> @brief Interface for integration step methods.
   !>
   !> Defines the signature for time-stepping procedures that update
   !> a particle's state based on applied forces.
   abstract interface
      subroutine step_proto(this, particle, force)
         import integrator_t
         import PointParticle
         import force_t
         class(integrator_t), intent(in) :: this  !< The integrator instance
         type(PointParticle), intent(inout) :: particle  !< Particle to update
         class(force_t) :: force  !< Force calculator
      end subroutine step_proto
   end interface

   !> @brief Velocity Verlet integrator implementation.
   !>
   !> Implements the Velocity Verlet algorithm, a symplectic integrator
   !> that conserves energy well for Hamiltonian systems. Second-order
   !> accurate in time.
   type, extends(integrator_t) :: verlet_t
   contains
      procedure, pass(this) :: integrate_step => verlet_step
   end type verlet_t

   !> @brief Boris algorithm integrator for charged particles.
   !>
   !> Implements the Boris push algorithm, which is particularly well-suited
   !> for simulating charged particle motion in magnetic fields. It exactly
   !> conserves phase space volume and handles the velocity-dependent
   !> Lorentz force correctly.
   type, extends(integrator_t) :: boris_t
      real :: magnetic_field(3)  !< Magnetic field vector B (T)
   contains
      procedure, pass(this) :: integrate_step => boris_step
   end type boris_t

contains
   !> @brief Performs a single Velocity Verlet integration step.
   !>
   !> Implements the Velocity Verlet algorithm to update the particle's
   !> position and velocity. The algorithm proceeds as:
   !>   1. Calculate initial acceleration from force
   !>   2. Half-step velocity update: v += 0.5 * a * dt
   !>   3. Full position update: x += v * dt
   !>   4. Recalculate acceleration at new position
   !>   5. Final half-step velocity update: v += 0.5 * a * dt
   !>
   !> @param[in]    this     The verlet_t integrator instance.
   !> @param[inout] particle The PointParticle to integrate.
   !> @param[in]    force    The force_t object to compute forces.
   subroutine verlet_step(this, particle, force)
      class(verlet_t), intent(in) :: this
      class(force_t) :: force
      type(PointParticle), intent(inout) :: particle

      real :: acceleration(3)
      real :: force_vector(3)
      real :: delta_t

      delta_t = this%delta_t

      ! calculate initial force and acceleration
      force_vector = force%get_force(particle)
      acceleration = force_vector/particle%mass

      ! update particle position and velocity
      particle%state%velocity = particle%state%velocity + 0.5*acceleration*delta_t
      particle%state%position = particle%state%position + particle%state%velocity*delta_t

      ! recalculate force and acceleration
      force_vector = force%get_force(particle)
      acceleration = force_vector/particle%mass

      ! do final velocity update
      particle%state%velocity = particle%state%velocity + 0.5*acceleration*delta_t

   end subroutine verlet_step

   !> @brief Constructs a new Velocity Verlet integrator.
   !>
   !> Factory function to create a verlet_t integrator with the
   !> specified time step.
   !>
   !> @param[in] delta_t Time step for integration (s).
   !>
   !> @return integrator A fully initialized verlet_t instance.
   function new_verlet_integrator(delta_t) result(integrator)
      type(verlet_t) :: integrator
      real, intent(in) :: delta_t

      integrator%delta_t = delta_t

   end function new_verlet_integrator

   !> @brief Performs a single Boris push integration step.
   !>
   !> Implements the Boris algorithm for integrating charged particle motion
   !> in electromagnetic fields. The algorithm splits the velocity update into:
   !>   1. Half acceleration from non-magnetic forces
   !>   2. Rotation due to magnetic field (preserves |v|)
   !>   3. Half acceleration from non-magnetic forces
   !>   4. Position update
   !>
   !> This method is symplectic and handles the magnetic rotation exactly,
   !> making it ideal for long-time simulations of magnetized plasmas.
   !>
   !> @param[in]    this     The boris_t integrator instance.
   !> @param[inout] particle The PointParticle to integrate.
   !> @param[in]    force    The force_t object for non-magnetic forces.
   subroutine boris_step(this, particle, force)
      class(boris_t), intent(in) :: this
      class(force_t) :: force
      type(PointParticle), intent(inout) :: particle

      real :: a_linear(3)
      real :: v_minus(3), v_prime(3), v_plus(3), t_vector(3), s_vector(3)

      ! calculate force due to linear components
      a_linear = force%get_force(particle)/particle%mass
      ! do first velocity update
      v_minus = particle%state%velocity + a_linear*(this%delta_t/2)

      ! define tangent and secant vectors
      t_vector = (particle%charge/particle%mass)*this%magnetic_field*(this%delta_t/2)
      s_vector = (2*t_vector)/(1 + dot_product(t_vector, t_vector))

      v_prime = v_minus + cross_product(v_minus, t_vector)
      v_plus = v_minus + cross_product(v_prime, s_vector)

      particle%state%velocity = v_plus + a_linear*(this%delta_t/2)
      particle%state%position = particle%state%position + particle%state%velocity*this%delta_t

   end subroutine boris_step

   !> @brief Constructs a new Boris integrator.
   !>
   !> Factory function to create a boris_t integrator with the
   !> specified time step and magnetic field.
   !>
   !> @param[in] delta_t        Time step for integration (s).
   !> @param[in] magnetic_field 3D magnetic field vector (T).
   !>
   !> @return integrator A fully initialized boris_t instance.
   function new_boris_integrator(delta_t, magnetic_field) result(integrator)
      real, intent(in) :: delta_t
      real, intent(in) :: magnetic_field(3)
      type(boris_t) :: integrator

      integrator%delta_t = delta_t
      integrator%magnetic_field = magnetic_field

   end function new_boris_integrator

end module integrators
