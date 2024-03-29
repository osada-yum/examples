# 目的

実験的な機能を使ってみよう!

# LFortranとテンプレート

`Fortran` の新しい規格に追加を検討されている機能として ジェネリックだのテンプレートだのというものがあるらしい. `Fortran` の実行環境の一つであるLFortranでは実験的な機能の `template` が実装されているらしいので使ってみようという試みである.

# 実行環境

-   OOP を使っているコードは `Ubuntu22.04` の `gfortran-11.2.0`
-   LFortranの実験的な機能の `template` を使っているコードは <https://dev.lfortran.org>

で実行した.

# モノイド

`template` 例として, モノイドの定義を紹介する.

-   モノイドとは? (参考 <https://ja.wikipedia.org/wiki/%E3%83%A2%E3%83%8E%E3%82%A4%E3%83%89>)

    ある集合 `S` と 単位元 `e` と結合則を満たす集合 `S` での2項演算子 `op` の組 (`S`, `e`, `op`)である(という説明で良いのだろうか?). 例としては, 整数全体の集合を `N` として

    -   (`N`, 0, `+`)
    -   (`N`, 1, `*`)

    はモノイドである. また, 32ビット整数全体の集合を `Int` として

    -   (`Int`, 2147483647, `min`)
    -   (`Int`, -2147483648, `max`)

    もモノイドである.

では, `Fortran` でモノイドを再現したいときはどうすればよいだろうか? `Fortran` では引数の型が違う場合には, 異なる関数に同じ名前を付けることができるが, 上記のモノイドでは引数の型で区別をすることができない. しかし, 以下の2通りの方法でなら, モノイドを実装することができる. OOPでは継承を利用して単位元メソッドと演算子メソッドを抽象クラスからオーバーライドする. 一方で, (LFortranの実験的な) `template` 機能を使うことで, 新しいクラスを作ることなしでモノイドを実装することができる.

## OOPによるモノイド

継承を利用して抽象モノイドクラスを定義して子クラスでメソッドを実装する. そして, モノイドの配列の要素全てにモノイド演算を適用した. 下のコードにはいくつかの特徴がある.

-   親クラスを継承している.
-   real型のモノイドを作る場合は新しい親クラスと子クラスを定義する必要がある.
-   `monoid_int32_add` と `monoid_int32_mul` を組み合わせてることが可能になってしまっている(`select type` で弾くことは可能).
-   `integer` 型そのものではなく, ユーザ定義型を使わないといけない.
-   実装が辛い?(個人の感想).

ソースコード<details><div>


```fortran
module monoid_class_m
  implicit none
  private
  public :: monoid_int32_base, mconcat_array
  type, abstract :: monoid_int32_base
     private
   contains
     procedure(val_interface),      deferred, pass :: val
     procedure(op_interface),       deferred, pass :: op
     procedure(identity_interface), deferred, pass :: identity
  end type monoid_int32_base
  abstract interface
     function val_interface(x) result(z)
       import monoid_int32_base
       class(monoid_int32_base), intent(in) :: x
       integer :: z
     end function val_interface
     function op_interface(x, y) result(z)
       import monoid_int32_base
       class(monoid_int32_base), intent(in) :: x, y
       class(monoid_int32_base), allocatable :: z
     end function op_interface
     function identity_interface(this) result(z)
       import monoid_int32_base
       class(monoid_int32_base), intent(in) :: this
       class(monoid_int32_base), allocatable :: z
     end function identity_interface
  end interface
contains
  function mconcat_array(n, arr) result(z)
    integer, intent(in) :: n
    class(monoid_int32_base), intent(in) :: arr(n)
    class(monoid_int32_base), allocatable :: tmp
    integer :: z, i
    tmp = arr(1)%identity()
    do i = 1, n
       tmp = tmp%op(arr(i))
    end do
    z = tmp%val()
  end function mconcat_array
end module monoid_class_m

module monoid_subclass_m
  use monoid_class_m
  implicit none
  public :: monoid_int32_add
  type, extends(monoid_int32_base) :: monoid_int32_add
     private
     integer :: val_
   contains
     procedure, pass :: val      => val_monoid_int32_add
     procedure, pass :: op       => op_monoid_int32_add
     procedure, pass :: identity => identity_monoid_int32_add
  end type monoid_int32_add
  interface monoid_int32_add
     module procedure :: init_monoid_int32_add
  end interface monoid_int32_add

  type, extends(monoid_int32_base) :: monoid_int32_mul
     private
     integer :: val_
   contains
     procedure, pass :: val      => val_monoid_int32_mul
     procedure, pass :: op       => op_monoid_int32_mul
     procedure, pass :: identity => identity_monoid_int32_mul
  end type monoid_int32_mul
  interface monoid_int32_mul
     module procedure :: init_monoid_int32_mul
  end interface monoid_int32_mul

  type, extends(monoid_int32_base) :: monoid_int32_min
     private
     integer :: val_
   contains
     procedure, pass :: val      => val_monoid_int32_min
     procedure, pass :: op       => op_monoid_int32_min
     procedure, pass :: identity => identity_monoid_int32_min
  end type monoid_int32_min
  interface monoid_int32_min
     module procedure :: init_monoid_int32_min
  end interface monoid_int32_min

  type, extends(monoid_int32_base) :: monoid_int32_max
     private
     integer :: val_
   contains
     procedure, pass :: val      => val_monoid_int32_max
     procedure, pass :: op       => op_monoid_int32_max
     procedure, pass :: identity => identity_monoid_int32_max
  end type monoid_int32_max
  interface monoid_int32_max
     module procedure :: init_monoid_int32_max
  end interface monoid_int32_max
contains

  function init_monoid_int32_add(v) result(z)
    integer, intent(in) :: v
    type(monoid_int32_add) :: z
    z%val_ = v
  end function init_monoid_int32_add
  function val_monoid_int32_add(x) result(z)
    class(monoid_int32_add), intent(in) :: x
    integer :: z
    z = x%val_
  end function val_monoid_int32_add
  function op_monoid_int32_add(x, y) result(z)
    class(monoid_int32_add), intent(in) :: x
    class(monoid_int32_base), intent(in) :: y
    class(monoid_int32_base), allocatable :: z
    z = monoid_int32_add(x%val() + y%val())
  end function op_monoid_int32_add
  function identity_monoid_int32_add(this) result(z)
    class(monoid_int32_add), intent(in) :: this
    class(monoid_int32_base), allocatable :: z
    z = monoid_int32_add(0)
  end function identity_monoid_int32_add

  function init_monoid_int32_mul(v) result(z)
    integer, intent(in) :: v
    type(monoid_int32_mul) :: z
    z%val_ = v
  end function init_monoid_int32_mul
  function val_monoid_int32_mul(x) result(z)
    class(monoid_int32_mul), intent(in) :: x
    integer :: z
    z = x%val_
  end function val_monoid_int32_mul
  function op_monoid_int32_mul(x, y) result(z)
    class(monoid_int32_mul), intent(in) :: x
    class(monoid_int32_base), intent(in) :: y
    class(monoid_int32_base), allocatable :: z
    z = monoid_int32_mul(x%val() * y%val())
  end function op_monoid_int32_mul
  function identity_monoid_int32_mul(this) result(z)
    class(monoid_int32_mul), intent(in) :: this
    class(monoid_int32_base), allocatable :: z
    z = monoid_int32_mul(1)
  end function identity_monoid_int32_mul

  function init_monoid_int32_min(v) result(z)
    integer, intent(in) :: v
    type(monoid_int32_min) :: z
    z%val_ = v
  end function init_monoid_int32_min
  function val_monoid_int32_min(x) result(z)
    class(monoid_int32_min), intent(in) :: x
    integer :: z
    z = x%val_
  end function val_monoid_int32_min
  function op_monoid_int32_min(x, y) result(z)
    class(monoid_int32_min), intent(in) :: x
    class(monoid_int32_base), intent(in) :: y
    class(monoid_int32_base), allocatable :: z
    z = monoid_int32_min(min(x%val(), y%val()))
  end function op_monoid_int32_min
  function identity_monoid_int32_min(this) result(z)
    class(monoid_int32_min), intent(in) :: this
    class(monoid_int32_base), allocatable :: z
    z = monoid_int32_min(huge(0_4))
  end function identity_monoid_int32_min

  function init_monoid_int32_max(v) result(z)
    integer, intent(in) :: v
    type(monoid_int32_max) :: z
    z%val_ = v
  end function init_monoid_int32_max
  function val_monoid_int32_max(x) result(z)
    class(monoid_int32_max), intent(in) :: x
    integer :: z
    z = x%val_
  end function val_monoid_int32_max
  function op_monoid_int32_max(x, y) result(z)
    class(monoid_int32_max), intent(in) :: x
    class(monoid_int32_base), intent(in) :: y
    class(monoid_int32_base), allocatable :: z
    z = monoid_int32_max(max(x%val(), y%val()))
  end function op_monoid_int32_max
  function identity_monoid_int32_max(this) result(z)
    class(monoid_int32_max), intent(in) :: this
    class(monoid_int32_base), allocatable :: z
    z = monoid_int32_max(-huge(0_4)-1)
  end function identity_monoid_int32_max
end module monoid_subclass_m

program test_monoid_class
  use, intrinsic :: iso_fortran_env
  use monoid_class_m
  use monoid_subclass_m
  implicit none
  integer, parameter :: n = 10
  integer :: i
  add:block
    type(monoid_int32_add) :: arr(n)
    do i = 1, n
       arr(i) = monoid_int32_add(i)
    end do
    print'(a, i0)', "mconcat add: ", mconcat_array(n, arr)
  end block add
  mul:block
    type(monoid_int32_mul) :: arr(n)
    do i = 1, n
       arr(i) = monoid_int32_mul(i)
    end do
    print'(a, i0)', "mconcat mul: ", mconcat_array(n, arr)
  end block mul
  min:block
    type(monoid_int32_min) :: arr(n)
    do i = 1, n
       arr(i) = monoid_int32_min(i)
    end do
    print'(a,i0)', "mconcat min: ", mconcat_array(n, arr)
  end block min
  max:block
    type(monoid_int32_max) :: arr(n)
    do i = 1, n
       arr(i) = monoid_int32_max(i)
    end do
    print'(a, i0)', "mconcat max: ", mconcat_array(n, arr)
  end block max
end program test_monoid_class
```

</div></details>


```text
mconcat add:      55
mconcat mul: 3628800
mconcat min:       1
mconcat max:      10
```

## templateによるモノイド

`template` を利用してモノイドの単位元を返す関数とモノイド演算をする関数(のインターフェース)を定義する. 実装は `Haskell` の `Monoid` 型クラスを参考にした. `mappend` が2項演算で `mempty` が単位元を返す関数である. 特徴は以下の通り.

-   `integer` や `real` 型の配列に対しての関数を生成することができる, つまり, 新しい型を宣言する必要がない. (なお, `logical` 型の `mconcat_all` と `mconcat_any` を実装しようとしたが, `logical` 型はまだ対応していなかった.)
-   `instantiate` を使った人が, 本当にモノイドになっているかを保証する必要がある(継承使う方法も, Haskellの型クラスも同様).
-   関数だけ実装すればよいので実装が軽い?(個人の感想).

ソースコード<details><div>


```fortran
! LFortranで動かせる.
! https://dev.lfortran.org
module template_monoid_m
  implicit none
  private
  public :: monoid_t
  requirement monoid_r(tp, mappend, mempty)
  type :: tp; end type
     function mappend(x, y) result(z)
       type(tp), intent(in) :: x, y
       type(tp) :: z
     end function mappend
     function mempty() result(zero)
       type(tp) :: zero
     end function mempty
  end requirement
  template monoid_t(tp, mappend, mempty)
    requires monoid_r(tp, mappend, mempty)
    private
    public :: mconcat_generic
  contains
    function mconcat_generic(n, arr) result(z)
      integer, intent(in) :: n
      type(tp), intent(in) :: arr(n)
      type(tp) :: z
      integer :: i
      z = mempty()
      do i = 1, n
         z = mappend(z, arr(i))
      end do
    end function mconcat_generic
  end template
end module template_monoid_m

module monoid_func_m
  use template_monoid_m
  implicit none
contains
  function mappend_add_int(x, y) result(z)
    integer, intent(in) :: x, y
    integer :: z
    z = x + y
  end function mappend_add_int
  function mempty_add_int() result(z)
    integer :: z
    z = 0
  end function mempty_add_int
  function mappend_mul_int(x, y) result(z)
    integer, intent(in) :: x, y
    integer :: z
    z = x * y
  end function mappend_mul_int
  function mempty_mul_int() result(z)
    integer :: z
    z = 1
  end function mempty_mul_int
  function mappend_min_int(x, y) result(z)
    integer, intent(in) :: x, y
    integer :: z
    z = min(x, y)
  end function mappend_mul_int
  function mempty_min_int() result(z)
    integer :: z
    z = huge(0_4)
  end function mempty_min_int
  function mappend_max_int(x, y) result(z)
    integer, intent(in) :: x, y
    integer :: z
    z = max(x, y)
  end function mappend_mul_int
  function mempty_max_int() result(z)
    integer :: z
    z = -huge(0_4)-1
  end function mempty_max_int
  subroutine test_template()
    integer, parameter :: n = 10
    integer :: arr(n), i
    do i = 1, n
       arr(i) = i; print*, arr(i)
    end do
    instantiate monoid_t(integer, mappend_add_int, mempty_add_int) &
         , only: mconcat_sum => mconcat_generic
    print'(a, i0)', "mconcat_sum: ", mconcat_sum(n, arr)
    instantiate monoid_t(integer, mappend_mul_int, mempty_mul_int) &
         , only: mconcat_prod => mconcat_generic
    print'(a, i0)', "mconcat_prod: ", mconcat_prod(n, arr)
    instantiate monoid_t(integer, mappend_min_int, mempty_min_int) &
         , only: mconcat_min => mconcat_generic
    print'(a, i0)', "mconcat_min: ", mconcat_min(n, arr)
    instantiate monoid_t(integer, mappend_max_int, mempty_max_int) &
         , only: mconcat_max => mconcat_generic
    print'(a, i0)', "mconcat_max: ", mconcat_max(n, arr)
  end subroutine test_template

  real function mempty_add_real() result(z)
    z = 0.0
  end function mempty_add_real
  real function mappend_add_real(x, y) result(z)
    real, intent(in) :: x, y
    z = x + y
  end function mappend_add_real
  subroutine test_template2()
    real :: arr(5)
    arr = [1.2, 3.4, 0.1, -0.1, -1.2]
    instantiate monoid_t(real, mappend_add_real, mempty_add_real) &
         , only: mconcat_sum_real => mconcat_generic
    print'(g0)', mconcat_sum_real(size(arr), arr)
  end subroutine test_template2
end module monoid_func_m
program test_monoid
  use monoid_func_m
  implicit none
  call test_template()
  call test_template2()
end program test_monoid
```

</div></details>


結果はこんな感じ.

```text
1
2
3
4
5
6
7
8
9
10
mconcat_sum:  55
mconcat_prod:  3628800
mconcat_min:  1
mconcat_max:  10
```

# ソート

`template` を使うとOOPのクラスよりも楽にモノイドを実装できることがわかった. `Haskell` の型クラスに習えば, モノイドに逆元を加えて群を実装することや, 順序関係が定義されている型の配列に対してソートを実装することが楽になるかもしれない.

## template を用いたバブルソート

`C++` テンプレートのように, (`sort<type, func>`) ソートへ順序関係を返す関数を与えることができたりする. とりあえず, 数行で実装できるバブルソートを試してみた.

ソースコード<details><div>


```fortran
module bubble_sort_template_m
  implicit none
  private
  public :: bubble_sort_template
  requirement cmp(tp, compare)
    type :: tp; end type
    function compare(x, y) result(z)
      type(tp), intent(in) :: x, y
      logical :: z
    end function compare
  end requirement

  template bubble_sort_tempalte(tp, compare)
    requires cmp(tp, compare)
    private
    public :: bubble_sort_generic
  contains
    subroutine bubble_sort_generic(n, arr)
      integer, intent(in) :: n
      type(tp), intent(inout) :: arr(n)
      type(tp) :: tmp
      integer :: i, j
      do i = n, 2, -1
         do j = n-1, n-i+1, -1
            if (compare(arr(j+1), arr(j))) then
               tmp = arr(j+1)
               arr(j+1) = arr(j)
               arr(j) = tmp
            end if
         end do
      end do
    end subroutine bubble_sort_generic
  end template
end module bubble_sort_template_m

module bubble_sort_m
  use bubble_sort_template_m
  implicit none
  public
contains
  logical function less(x, y) result(z)
    integer, intent(in) :: x, y
    z = x < y
  end function less
  logical function more(x, y) result(z)
    integer, intent(in) :: x, y
    z = x > y
  end function more
  subroutine test_template()
    integer, parameter :: n = 10
    integer :: i
    integer :: arr(n)
    print*, "arr: "
    arr = [1, 3, 5, 7, 9, 2, 4, 6, 8, 10]
    do i = 1, n
       print*, arr(i)
    end do
    instantiate bubble_sort_tempalte(integer, less), &
         only: bubble_sort_int => bubble_sort_generic
    call bubble_sort_int(size(arr), arr)
    print*, "sorted arr: "
    do i = 1, n
       print*, arr(i)
    end do
    instantiate bubble_sort_tempalte(integer, more), &
         only: bubble_sort_int_descending => bubble_sort_generic
    call bubble_sort_int_descending(size(arr), arr)
    print*, "sorted arr in descending order: "
    do i = 1, n
       print*, arr(i)
    end do
  end subroutine test_template
end module bubble_sort_m

program test_bubble_sort
  use bubble_sort_m
  implicit none
  call test_template()
end program test_bubble_sort
```

</div></details>


結果はこんな感じ.

```text
arr:
1
3
5
7
9
2
4
6
8
10
sorted arr:
1
2
3
4
5
6
7
8
9
10
sorted arr in descending order:
10
9
8
7
6
5
4
3
2
1
```

# 更なる発展&#x2026;?

`template` を使うとOOPのクラスよりも楽にモノイドを実装できることがわかった. `Haskell` の型クラスに習えば, モノイドに逆元を加えて群を実装することや, 順序関係が定義されている型の配列に対してソートを実装することが楽になるかもしれない.

# 参考

-   LFortranテンプレートの機能があることは, `Fortran勉強会.f13` で知った.

https://fortran-jp.org/usergroup/usergroup.html

-   LFortranのサイト

https://lfortran.org/

https://dev.lfortran.org

で実行してみよう!

-   templateの例

https://fortran66.hatenablog.com/entry/2022/11/07/004514

https://fortran66.hatenablog.com/entry/2023/02/21/012205

-   モノイド

https://ja.wikipedia.org/wiki/%E3%83%A2%E3%83%8E%E3%82%A4%E3%83%89
