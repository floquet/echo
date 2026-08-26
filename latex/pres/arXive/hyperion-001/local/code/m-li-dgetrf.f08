! 3456789 123456789 223456789 323456789 423456789 523456789 623456789 723456789 823456789 923456789 023456789 123456789 223456789 32
! https://stackoverflow.com/questions/8508590/standard-input-and-output-units-in-fortran-90
! https://stackoverflow.com/questions/67463087/error-in-lapack-routine-sgels-using-an-interface-and-allocatable-work-array
! https://stackoverflow.com/questions/26475987/lapack-inversion-routine-strangely-mixes-up-all-variables
! https://www.netlib.org/lapack/lapack-3.1.1/html/dgetrf.f.html
module mLapackInterfaceDGETRF

    use, intrinsic :: iso_fortran_env,  only : stdout => output_unit
    use mFormatDescriptorsBasics,       only : fmt_two
    use mFormatDescriptorsLapack,       only : fmt_array_1, fmt_array_2, fmt_dgetrf_error, fmt_elements, fmt_lapack_error, &
                                               fmt_listA, fmt_listb, fmt_list_work, fmt_shape_r2, fmt_size_norm

    implicit none

    interface lapack_DGETRF

        subroutine DGETRF ( m, n, A, lda, ipv, info )
            use mPrecisionDefinitions, only : rp
            integer,                                           intent ( in )    :: m, n, lda
            integer,                                           intent ( out )   :: info
            integer,            dimension ( 1 : n ),           intent ( in )    :: ipv
            real ( kind = rp ), dimension ( 1 : lda , 1 : n ), intent ( inout ) :: A
        end subroutine DGETRF

    end interface lapack_DGETRF

contains

    subroutine echo_DGETRF ( m, n, A, lda, ipv, info )
        use mPrecisionDefinitions, only : rp
        integer,                                           intent ( in )    :: m, n, lda
        integer,                                           intent ( out )   :: info
        integer,            dimension ( 1 : n ),           intent ( in )    :: ipv
        real ( kind = rp ), dimension ( 1 : lda , 1 : n ), intent ( inout ) :: A

        integer :: col = 0, row = 0

            write ( * , * ) "Slot arguments to DGETRF:"
            write ( * , fmt = 100 ) " 1. in     m     = ", m
            write ( * , fmt = 100 ) " 1. in     n     = ", n
            write ( * , fmt = 110 ) " 2. inout  A     = ", lda, n
            write ( * , fmt = 100 ) " 3. in     lda   = ", lda
            write ( * , fmt = 120 ) " 4. out    ipv   = ", min ( m, n )
            write ( * , fmt = 100 ) " 7. out    info  = ", info

            write ( * , * ) ""
            write ( * , fmt = 130 ) lda * n, "design matrix A"
            do col = 1, n
                do row = 1, lda
                    write ( * , fmt = 140 ) row, col, A ( row, col )
                end do
            end do

            write ( * , * ) ""
            write ( * , * ) "Rank and size:"
            write ( * , fmt = 170 ) " mesh:   shape ( A )   = ", shape ( A )
            write ( * , fmt = 100 ) " pivots: shape ( ipv ) = ", shape ( ipv )

        return

    100 format ( g0, g0 )
    110 format ( g0, "array size: ", g0, " x ", g0 )
    120 format ( g0, "array size: ", g0 )
    130 format ( "The ", g0, " elements of the ", g0, " follow:")
    140 format ( "A ( ", g0, ", ", g0, " ) = ", g0 )
    170 format ( g0, 2 ( g0, " x ", g0 ) )

    end subroutine echo_DGETRF

    subroutine error_dgetrf ( info_value, message )
        use mPrecisionDefinitions, only : kindA
        integer,                             intent ( in )           :: info_value
        character ( kind = kindA, len = * ), intent ( in ), optional :: message
        character ( kind = kindA, len = 6 ), parameter :: iam = "DGETRF"

            if ( info_value == 0 ) then
                return
            endif

            if ( present ( message ) ) then
                write ( * , * ) message
            end if

            if ( info_value > 0 ) then
                write ( * , fmt = fmt_lapack_error ) iam
                write ( * , fmt = fmt_dgetrf_error ) iam, info_value, info_value
                return
            else
                write ( * , fmt = fmt_lapack_error ) iam
                write ( * , fmt = 100 ) iam, abs ( info_value )
                return
            endif

        return

    100 format ( /, "Illegal value in call to DGETRF in slot ", g0, ". The slot arguments follow:", /, &
                    " 1. m     (input)         integer", /, &
                    " 2. n     (input)         integer", /, &
                    " 3. A     (input/output)  double precision  rank 2", /, &
                    " 4. lda   (input)         integer", /, &
                    " 5. ipv   (output)        integer", /, &
                    " 6. info  (output)        integer" )
    end subroutine error_dgetrf

end module mLapackInterfaceDGETRF

!      SUBROUTINE DGETRF( M, N, A, LDA, IPIV, INFO )
!
!  -- LAPACK routine (version 3.1) --
!     Univ. of Tennessee, Univ. of California Berkeley and NAG Ltd..
!     November 2006
!
!     .. Scalar Arguments ..
!       INTEGER            INFO, LDA, M, N
!     ..
!     .. Array Arguments ..
!       INTEGER            IPIV( * )
!       DOUBLE PRECISION   A( LDA, * )
!     ..
!
!  Purpose
!  =======
!
!  DGETRF computes an LU factorization of a general M-by-N matrix A
!  using partial pivoting with row interchanges.
!
!  The factorization has the form
!     A = P * L * U
!  where P is a permutation matrix, L is lower triangular with unit
!  diagonal elements (lower trapezoidal if m > n), and U is upper
!  triangular (upper trapezoidal if m < n).
!
!  This is the right-looking Level 3 BLAS version of the algorithm.
!
!  Arguments
!  =========
!
!  M       (input) INTEGER
!          The number of rows of the matrix A.  M >= 0.
!
!  N       (input) INTEGER
!          The number of columns of the matrix A.  N >= 0.
!
!  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
!          On entry, the M-by-N matrix to be factored.
!          On exit, the factors L and U from the factorization
!          A = P*L*U; the unit diagonal elements of L are not stored.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(1,M).
!
!  IPIV    (output) INTEGER array, dimension (min(M,N))
!          The pivot indices; for 1 <= i <= min(M,N), row i of the
!          matrix was interchanged with row IPIV(i).
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value
!          > 0:  if INFO = i, U(i,i) is exactly zero. The factorization
!                has been completed, but the factor U is exactly
!                singular, and division by zero will occur if it is used
!                to solve a system of equations.
