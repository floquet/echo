! 3456789 123456789 223456789 323456789 423456789 523456789 623456789 723456789 823456789 923456789 023456789 123456789 223456789 32
! https://stackoverflow.com/questions/8508590/standard-input-and-output-units-in-fortran-90
! https://stackoverflow.com/questions/67463087/error-in-lapack-routine-sgels-using-an-interface-and-allocatable-work-array
! https://www.netlib.org/lapack/explore-3.1.1-html/dgels.f.html
! https://github.com/Reference-LAPACK/lapack/blob/master/SRC/dgetsls.f
module mLapackInterfaceDGELS

    use, intrinsic :: iso_fortran_env,  only : stdout => output_unit
    use mFormatDescriptorsBasics,       only : fmt_two
    use mFormatDescriptorsLapack,       only : fmt_array_1, fmt_array_2, fmt_dgels_error, fmt_elements, fmt_lapack_error, &
                                               fmt_listA, fmt_listb, fmt_list_work, fmt_shape_r2, fmt_size_norm

    implicit none

    interface lapack_dgels

        subroutine dgels ( trans, m, n, nrhs, A, lda, b, ldb, work, lwork, info )
            use mPrecisionDefinitions, only : rp, kindA
            integer,                                                   intent ( in )    :: m, n, nrhs, lda, ldb, lwork
            integer,                                                   intent ( out )   :: info
            real      ( kind = rp ), dimension ( 1 : lwork ),          intent ( out )   :: work
            real      ( kind = rp ), dimension ( 1 : lda , 1 : n ),    intent ( inout ) :: A
            real      ( kind = rp ), dimension ( 1 : ldb , 1 : nrhs ), intent ( inout ) :: b
            character ( kind = kindA ),                                intent ( in )    :: trans
        end subroutine dgels

    end interface lapack_dgels

contains

    subroutine echo_dgels ( trans, m, n, nrhs, A, lda, b, ldb, work, lwork, info )
        use mPrecisionDefinitions, only : rp, kindA
        integer,                                                   intent ( in ) :: m, n, nrhs, lda, ldb, lwork
        integer,                                                   intent ( in ) :: info
        real      ( kind = rp ), dimension ( 1 : lwork ),          intent ( in ) :: work
        real      ( kind = rp ), dimension ( 1 : lda , 1 : n ),    intent ( in ) :: A
        real      ( kind = rp ), dimension ( 1 : ldb , 1 : nrhs ), intent ( in ) :: b
        character ( kind = kindA ),                                intent ( in ) :: trans
        integer :: col = 0, row = 0

            write ( * , * ) "Slot arguments to DGELS:"
            write ( * , fmt = fmt_two )      "  1. in     trans = ", trans
            write ( * , fmt = fmt_two )       " 2. in     m     = ", m
            write ( * , fmt = fmt_two )       " 3. in     n     = ", n
            write ( * , fmt = fmt_two )       " 4. in     nrhs  = ", nrhs
            write ( * , fmt = fmt_array_2 )   " 5. inout  A     = ", lda, n
            write ( * , fmt = fmt_two )       " 6. in     lda   = ", lda
            write ( * , fmt = fmt_array_2 )   " 7. inout  b     = ", ldb, nrhs
            write ( * , fmt = fmt_two )       " 8. in     ldb   = ", ldb
            write ( * , fmt = fmt_size_norm ) " 9. out    work  = ", lwork, norm2 ( work )
            write ( * , fmt = fmt_two )       "10. inout  lwork = ", lwork
            write ( * , fmt = fmt_two )       "11. out    info  = ", info

            write ( * , * ) ""
            write ( * , fmt = fmt_elements ) n * lda, "design matrix A"
            do col = 1, n
                do row = 1, lda
                    write ( * , fmt = fmt_listA ) row, col, A ( row, col )
                end do
            end do

            write ( * , * ) ""
            write ( * , fmt = fmt_elements ) nrhs * ldb, "data vector b"
            do col = 1, nrhs
                do row = 1, ldb
                    write ( * , fmt = fmt_listb ) row, col, b ( row, col )
                end do
            end do

            write ( * , * ) ""
            if ( lwork < 0 ) then
                write ( * , fmt = fmt_elements ) lwork, "workspace"
                write ( * , * ) "query: size of WORK not set yet"
            else
                do row = 1, lwork
                    write ( * , fmt = fmt_list_work ) row, work ( row )
                end do
            endif

            write ( * , * ) ""
            write ( * , * ) "Rank and size:"
            write ( * , fmt = fmt_shape_r2 ) " mesh:      shape ( A )    = ", shape ( A )
            write ( * , fmt = fmt_shape_r2 ) " data:      shape ( b )    = ", shape ( b )
            write ( * , fmt = fmt_two )      " workspace: shape ( work ) = ", shape ( work )

        return

    end subroutine echo_dgels

    subroutine error_dgels ( info_value, message )
        use mPrecisionDefinitions, only : kindA
        integer,                             intent ( in )           :: info_value
        character ( kind = kindA, len = * ), intent ( in ), optional :: message
        character ( kind = kindA, len = 5 ), parameter :: iam = "DGELS"

            if ( info_value == 0 ) then
                return
            endif

            if ( present ( message ) ) then
                write ( * , * ) message
            end if

            if ( info_value > 0 ) then
                write ( * , fmt = fmt_lapack_error ) iam
                write ( * , fmt = fmt_dgels_error ) info_value
                return
            else
                write ( * , fmt = fmt_lapack_error ) iam
                write ( * , fmt = 100 ) iam, abs ( info_value )
                return
            endif

        return

    100 format ( /, "Illegal value in call to ", g0, " in slot ", g0, ". The slot arguments follow:", /, &
                    " 1. trans (input)            character*1", /, &
                    " 2. m     (input)            integer", /, &
                    " 3. n     (input)            integer", /, &
                    " 4. nrhs  (input)            integer", /, &
                    " 5. A     (input/output)     double precision  rank 2", /, &
                    " 6. lda   (input)            integer", /, &
                    " 7. b     (input/output)     double precision  rank 2", /, &
                    " 8. ldb   (input)            integer", /, &
                    " 9. work  (input)            double precision  rank 1", /, &
                    "10. lwork (workspace/output) integer", /, &
                    "11. info  (output)           integer" )

    end subroutine error_dgels

end module mLapackInterfaceDGELS


!  -- LAPACK driver routine (version 3.1) --
!     Univ. of Tennessee, Univ. of California Berkeley and NAG Ltd..
!     November 2006

!     .. Scalar Arguments ..
!      CHARACTER          TRANS
!      INTEGER            INFO, LDA, LDB, LWORK, M, N, NRHS

!     .. Array Arguments ..
!      DOUBLE PRECISION   A( LDA, ! ), B( LDB, ! ), WORK( ! )

!  Purpose

!  DGELS solves overdetermined or underdetermined real linear systems
!  involving an M-by-N matrix A, or its transpose, using a QR or LQ
!  factorization of A.  It is assumed that A has full rank.

!  The following options are provided:

!  1. If TRANS = 'N' and m >= n:  find the least squares solution of
!     an overdetermined system, i.e., solve the least squares problem
!                  minimize || B - A*X ||.

!  2. If TRANS = 'N' and m < n:  find the minimum norm solution of
!     an underdetermined system A ! X = B.

!  3. If TRANS = 'T' and m >= n:  find the minimum norm solution of
!     an undetermined system A**T ! X = B.

!  4. If TRANS = 'T' and m < n:  find the least squares solution of
!     an overdetermined system, i.e., solve the least squares problem
!                  minimize || B - A**T ! X ||.

!  Several right hand side vectors b and solution vectors x can be
!  handled in a single call; they are stored as the columns of the
!  M-by-NRHS right hand side matrix B and the N-by-NRHS solution
!  matrix X.

!  Arguments

!  TRANS   (input) CHARACTER*1
!          = 'N': the linear system involves A;
!          = 'T': the linear system involves A**T.

!  M       (input) INTEGER
!          The number of rows of the matrix A.  M >= 0.

!  N       (input) INTEGER
!          The number of columns of the matrix A.  N >= 0.

!  NRHS    (input) INTEGER
!          The number of right hand sides, i.e., the number of
!          columns of the matrices B and X. NRHS >=0.

!  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
!          On entry, the M-by-N matrix A.
!          On exit,
!            if M >= N, A is overwritten by details of its QR
!                       factorization as returned by DGEQRF;
!            if M <  N, A is overwritten by details of its LQ
!                       factorization as returned by DGELQF.

!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(1,M).

!  B       (input/output) DOUBLE PRECISION array, dimension (LDB,NRHS)
!          On entry, the matrix B of right hand side vectors, stored
!          columnwise; B is M-by-NRHS if TRANS = 'N', or N-by-NRHS
!          if TRANS = 'T'.
!          On exit, if INFO = 0, B is overwritten by the solution
!          vectors, stored columnwise:
!          if TRANS = 'N' and m >= n, rows 1 to n of B contain the least
!          squares solution vectors; the residual sum of squares for the
!          solution in each column is given by the sum of squares of
!          elements N+1 to M in that column;
!          if TRANS = 'N' and m < n, rows 1 to N of B contain the
!          minimum norm solution vectors;
!          if TRANS = 'T' and m >= n, rows 1 to M of B contain the
!          minimum norm solution vectors;
!          if TRANS = 'T' and m < n, rows 1 to M of B contain the
!          least squares solution vectors; the residual sum of squares
!          for the solution in each column is given by the sum of
!          squares of elements M+1 to N in that column.

!  LDB     (input) INTEGER
!          The leading dimension of the array B. LDB >= MAX(1,M,N).

!  WORK    (workspace/output) DOUBLE PRECISION array, dimension (MAX(1,LWORK))
!          On exit, if INFO = 0, WORK(1) returns the optimal LWORK.

!  LWORK   (input) INTEGER
!          The dimension of the array WORK.
!          LWORK >= max( 1, MN + max( MN, NRHS ) ).
!          For optimal performance,
!          LWORK >= max( 1, MN + max( MN, NRHS )*NB ).
!          where MN = min(M,N) and NB is the optimum block size.

!          If LWORK = -1, then a workspace query is assumed; the routine
!          only calculates the optimal size of the WORK array, returns
!          this value as the first entry of the WORK array, and no error
!          message related to LWORK is issued by XERBLA.

!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value
!          > 0:  if INFO =  i, the i-th diagonal element of the
!                triangular factor of A is zero, so that A does not have
!                full rank; the least squares solution could not be
!                computed.
