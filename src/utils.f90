module utils
   implicit none
   private ! hide all variables

   public :: print_separator, write_csv ! export the function

contains ! required when defining functions in a module

   !> @brief Prints a horizontal separator line to stdout.
   !>
   !> Outputs a line of dashes for visual separation in console output.
   subroutine print_separator()
      print *, '----------------------------------------'
   end subroutine print_separator

   !> @brief Writes a 2D array of real values to a CSV file.
   !>
   !> Creates or overwrites a CSV file with the provided data. Each row of
   !> the input array becomes a line in the output file, with values
   !> separated by commas.
   !>
   !> @param[in] filename Path to the output CSV file.
   !> @param[in] data     2D array of real values to write.
   !>
   !> @note The file is created with 'replace' status, overwriting any
   !>       existing file with the same name.
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
