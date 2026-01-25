module utils
   implicit none
   private ! hide all variables

   public :: print_separator, write_csv ! export the function

contains ! required when defining functions in a module

   subroutine print_separator()
      print *, '----------------------------------------'
   end subroutine print_separator

   subroutine write_csv(filename, data)
      character(len=*), intent(in) :: filename
      real, intent(in) :: data(:, :)
      integer :: i
      integer :: num_rows
      integer :: nu

      num_rows = size(data, 1)

      open (newunit=nu, file=filename, status='replace', action='write')
      do i = 1, num_rows
         write (nu, '(2(f0.3, ","), f0.3)') data(i, :)
      end do

      close (nu)

   end subroutine write_csv

end module utils
