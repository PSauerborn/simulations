module utils
   use csv_module
   use types

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

   !> @brief Writes CSV data to a file using the csv-fortran library.
   !>
   !> Creates or overwrites a CSV file with the provided data. The output
   !> includes a header row followed by the data values. Each row of the
   !> values array becomes a line in the output file.
   !>
   !> @param[in] output   CSVOutput instance containing filename, header, and values.
   !> @param[in] real_fmt Optional format string for real numbers (default: '(F12.6)').
   !>
   !> @note The file is created with 'replace' status, overwriting any
   !>       existing file with the same name.
   subroutine write_csv(output, real_fmt)
      type(CSVOutput) :: output
      character(len=*), intent(in), optional :: real_fmt

      integer :: i
      integer :: num_rows, column_count

      type(csv_file) :: f
      logical :: status_ok
      character(len=20) :: fmt_str

      ! Set default format if not provided
      if (present(real_fmt)) then
         fmt_str = real_fmt
      else
         fmt_str = '(F12.6)'
      end if

      num_rows = size(output%values, 1)
      column_count = size(output%values, 2)

      call f%initialize(verbose=.true.)
      call f%open(output%filename, n_cols=column_count, status_ok=status_ok)
      ! add CSV header row
      call f%add(output%header)
      call f%next_row()

      do i = 1, num_rows
         call f%add(output%values(i, :), real_fmt=fmt_str)
         call f%next_row()
      end do

      call f%close(status_ok)
   end subroutine write_csv

end module utils
