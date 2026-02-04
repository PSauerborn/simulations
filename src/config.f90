module config
   use tomlf

   implicit none
   private

   public :: read_config_value

   interface read_config_value
      module procedure read_real_value
      module procedure read_integer_value
      module procedure read_char_value
      module procedure read_real_array_value
   end interface read_config_value
contains

   !> @brief Extracts a required real value from a TOML table.
   !>
   !> Retrieves a real (floating-point) value from the specified TOML table
   !> using the given key. If the key does not exist or the value cannot be
   !> parsed as a real number, the program terminates with an error.
   !>
   !> @param[in] table Pointer to the TOML table to read from.
   !> @param[in] key The key name to look up in the table.
   !> @param[out] val The extracted real value.
   !>
   !> @warning Terminates execution if the key is missing or value is invalid.
   subroutine read_real_value(table, key, val)
      type(toml_table), pointer, intent(in) :: table
      character(*), intent(in) :: key
      real, intent(out) :: val
      integer :: stat

      call get_value(table, key, val, stat=stat)
      if (stat /= 0) then
         print *, 'Error: invalid real config value for ', key
         stop 1
      end if
   end subroutine read_real_value

   !> @brief Extracts a required integer value from a TOML table.
   !>
   !> Retrieves an integer value from the specified TOML table using the
   !> given key. If the key does not exist or the value cannot be parsed
   !> as an integer, the program terminates with an error.
   !>
   !> @param[in] table Pointer to the TOML table to read from.
   !> @param[in] key The key name to look up in the table.
   !> @param[out] val The extracted integer value.
   !>
   !> @warning Terminates execution if the key is missing or value is invalid.
   subroutine read_integer_value(table, key, val)
      type(toml_table), pointer, intent(in) :: table
      character(*), intent(in) :: key
      integer, intent(out) :: val
      integer :: stat

      call get_value(table, key, val, stat=stat)
      if (stat /= 0) then
         print *, 'Error: invalid integer config value for ', key
         stop 1
      end if
   end subroutine read_integer_value

   !> @brief Extracts a required character string value from a TOML table.
   !>
   !> Retrieves a character string value from the specified TOML table using
   !> the given key. The output is an allocatable deferred-length string. If
   !> the key does not exist or the value cannot be parsed as a string, the
   !> program terminates with an error.
   !>
   !> @param[in] table Pointer to the TOML table to read from.
   !> @param[in] key The key name to look up in the table.
   !> @param[out] val The extracted character string (allocatable).
   !>
   !> @warning Terminates execution if the key is missing or value is invalid.
   subroutine read_char_value(table, key, val)
      type(toml_table), pointer, intent(in) :: table
      character(*), intent(in) :: key
      character(len=:), allocatable, intent(out) :: val
      integer :: stat

      call get_value(table, key, val, stat=stat)
      if (stat /= 0) then
         print *, 'Error: invalid character config value for ', key
         stop 1
      end if
   end subroutine read_char_value

   !> @brief Extracts a required real array from a TOML table.
   !>
   !> Retrieves an array of real (floating-point) values from the specified
   !> TOML table using the given key. The output is an allocatable array that
   !> will be sized according to the array in the configuration file. If the
   !> key does not exist, the value is not an array, or the array elements
   !> cannot be parsed as real numbers, the program terminates with an error.
   !>
   !> @param[in] table Pointer to the TOML table to read from.
   !> @param[in] key The key name to look up in the table.
   !> @param[out] val The extracted real array (allocatable).
   !>
   !> @warning Terminates execution if the key is missing or value is invalid.
   subroutine read_real_array_value(table, key, val)
      type(toml_table), pointer, intent(in) :: table
      type(toml_array), pointer :: temp
      character(*), intent(in) :: key
      real, allocatable :: val(:)
      integer :: stat

      call get_value(table, key, temp, stat=stat)
      if (stat /= 0) then
         print *, 'Error: invalid array config value for ', key
         stop 1
      end if

      if (associated(temp)) then
         call get_value(temp, val, stat=stat)
      else
         print *, 'Error: invalid array config value for ', key
         stop 1
      end if

      if (stat /= 0) then
         print *, 'Error: invalid array config value for ', key
         stop 1
      end if
   end subroutine read_real_array_value

end module config
