program find_sol
  use, intrinsic :: iso_fortran_env
  use queen_m
  implicit none
  integer, parameter :: num_queen = 10
  integer            :: i
  logical            :: can_find
  type(queen_t)      :: queen(num_queen)

  queen(1) = queen_t(1, num_queen)
  do i = 2, num_queen
     queen(i) = queen_t(i, num_queen, queen(i-1))
     can_find = queen(i)%find_solution()
  end do

  call queen(num_queen)%print()
end program find_sol
