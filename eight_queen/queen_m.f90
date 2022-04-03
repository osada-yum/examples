module queen_m
  use, intrinsic :: iso_fortran_env
  implicit none

! max_row = 12
! |*| | |-| | |-| | |-|-|-|
! | |-|-| | |-| | |*|-|-| |
! | |*|-| |-| | | |-|-|-|-|
! |-| |-|-| | | |-|-| |-|*|
! | | |*|-|-| |-|-| |-|-|-|
! | | | |-|-|-|*| |-|-|-|-|
! | | | | |-|-|-|-|-|*|-|-|
! | | | |*| |-|-|-|-|-|-|-|
! | | |-| |-|-|-|-|-|-|*|-|
! | |-| | |*|-| |-|-|-|-|-|
! |-| | | |-|-|-|*|-|-|-|-|
! | | | |-| |*|-|-|-|-|-|-|

  type queen_t
     private
     integer                :: row, col
     type(queen_t), pointer :: neighbor
     integer                :: max_row
   contains
     procedure, pass :: find_solution => find_solution_q
     procedure, pass :: can_attack    => can_attack_q
     procedure, pass :: advance       => advance_q
     procedure, pass :: print         => print_q
     final :: destroy_queen
  end type queen_t

  interface queen_t
     module procedure :: initialize_left, initialize_q
  end interface queen_t

contains

  impure function initialize_left(col, max_row) result(res_q)
    type(queen_t)       :: res_q
    integer, intent(in) :: col, max_row
    res_q%row     = 1
    res_q%col     = col
    res_q%max_row = max_row
    res_q%neighbor => null()
    return
  end function initialize_left

  impure function initialize_q(col, max_row, queen) result(res_q)
    type(queen_t)                     :: res_q
    integer              , intent(in) :: col, max_row
    type(queen_t), target, intent(in) :: queen
    res_q%row     = 1
    res_q%col     = col
    res_q%max_row = max_row
    res_q%neighbor => queen
    return
  end function initialize_q

  subroutine destroy_queen(this)
    type(queen_t), intent(inout) :: this
    write(error_unit, '(a, i0, a, i0, a)') "destroyed: (", this%row, ", ", this%col, ")"
  end subroutine destroy_queen

  impure recursive logical function find_solution_q(this)
    class(queen_t), intent(inout) :: this
    do
       if (.not. associated(this%neighbor)) exit
       if (.not. this%neighbor%can_attack(this%row, this%col)) exit
       if (.not. this%advance()) then
          find_solution_q = .false.
          return
       end if
    end do
    find_solution_q = .true.
    return
  end function find_solution_q

  pure recursive logical function can_attack_q(this, test_row, test_col) result(attackable)
    class(queen_t), intent(in) :: this
    integer      , intent(in) :: test_row, test_col
    integer                   :: column_diff
    if (this%row == test_row) then
       attackable = .true.
       return
    end if

    column_diff = test_col - this%col
    if ( this%row + column_diff == test_row .or.&
         this%row - column_diff == test_row ) then
       attackable = .true.
       return
    end if

    if (associated(this%neighbor)) then
       attackable = this%neighbor%can_attack(test_row, test_col)
    else
       attackable = .false.
    end if
    return
  end function can_attack_q

  impure recursive logical function advance_q(this)
    class(queen_t), intent(inout) :: this
    if (this%row < this%max_row) then
       this%row = this%row + 1
       advance_q = this%find_solution()
       return
    end if

    if (.not. this%neighbor%advance()) then
       advance_q = .false.
       return
    end if
    this%row = 1
    advance_q = this%find_solution()
    return
  end function advance_q

  recursive subroutine print_q(this)
    class(queen_t), intent(in) :: this
    if (associated(this%neighbor)) then
       call this%neighbor%print()
    end if
    write(output_unit, *) this%row, this%col
  end subroutine print_q

end module queen_m
