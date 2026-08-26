! 3456789 123456789 223456789 323456789 423456789 523456789 623456789 723456789 823456789 923456789 023456789 123456789 223456789 32
! https://stackoverflow.com/questions/8508590/standard-input-and-output-units-in-fortran-90
! https://stackoverflow.com/questions/67463087/error-in-lapack-routine-sgels-using-an-interface-and-allocatable-work-array
! https://www.netlib.org/lapack/explore-3.1.1-html/dgelsd.f.html
module mLapackInterfaceDGELSD
    ! DGELSD computes the minimum-norm solution to a real linear least
    ! squares problem:
    !     minimize 2-norm(| b - A*x |)
    ! using the singular value decomposition (SVD) of A.
    ! PATHOLOGY: written for full column rank
    use, intrinsic :: iso_fortran_env,  only : stdout => output_unit
    use mFileHandling,                  only : safeopen_readwrite
    use mFormatDescriptorsBasics,       only : fmt_two
    use mFormatDescriptorsLapack,       only : fmt_array_1, fmt_array_2, fmt_dgelsd_error, fmt_elements, fmt_lapack_error, &
                                               fmt_listA, fmt_listb, fmt_list_work, fmt_shape_r1, fmt_shape_r2, fmt_size_norm
    implicit none

    interface lapack_dgelsd
        ! explicit interface allows slot arguments to be labelled and passed in any order
        !   allows slot arguments to be labelled
        !   allows slot arguments to be passed in any order
        !   allows compiler to check argument types
        subroutine dgelsd ( m, n, nrhs, A, lda, b, ldb, s, rcond, rank, work, lwork, iwork, info )
            use mPrecisionDefinitions, only : rp
            integer,                                              intent ( in )    :: m, n, nrhs, lda, ldb, lwork
            integer,                                              intent ( out )   :: rank, info
            integer,            dimension ( : ),                  intent ( out )   :: iwork
            real ( kind = rp ), dimension ( 1 : n ),              intent ( out )   :: s
            real ( kind = rp ), dimension ( 1 : lwork ),          intent ( out )   :: work
            real ( kind = rp ), dimension ( 1 : lda , 1 : n ),    intent ( inout ) :: A
            real ( kind = rp ), dimension ( 1 : ldb , 1 : nrhs ), intent ( inout ) :: b
            real ( kind = rp ),                                   intent ( in )    :: rcond
        end subroutine dgelsd

    end interface lapack_dgelsd

contains
    ! debug tool to echo arguments passed to LAPACK routine
    subroutine echo_dgelsd ( m, n, nrhs, A, lda, b, ldb, s, rcond, rank, work, lwork, iwork, info )
        use mPrecisionDefinitions, only : rp
        integer,                                              intent ( in )    :: m, n, nrhs, lda, ldb, lwork
        integer,                                              intent ( out )   :: rank, info
        integer,            dimension ( : ),                  intent ( out )   :: iwork
        real ( kind = rp ), dimension ( 1 : n ),              intent ( out )   :: s
        real ( kind = rp ), dimension ( 1 : lwork ),          intent ( out )   :: work
        real ( kind = rp ), dimension ( 1 : lda , 1 : n ),    intent ( inout ) :: A
        real ( kind = rp ), dimension ( 1 : ldb , 1 : nrhs ), intent ( inout ) :: b
        real ( kind = rp ),                                   intent ( in )    :: rcond
        integer :: col = 0, row = 0, io_work = 0

            write ( * , * ) "Slot arguments to dgelsd:"
            write ( * , fmt = fmt_two )       " 1. in     m        = ", m
            write ( * , fmt = fmt_two )       " 2. in     n        = ", n
            write ( * , fmt = fmt_two )       " 3. in     nrhs     = ", nrhs
            write ( * , fmt = fmt_array_2 )   " 4. inout  A        = ", lda, n
            write ( * , fmt = fmt_two )       " 5. in     lda      = ", lda
            write ( * , fmt = fmt_array_2 )   " 6. inout  b        = ", ldb, nrhs
            write ( * , fmt = fmt_two )       " 7. in     ldb      = ", ldb
            write ( * , fmt = fmt_array_1 )   " 8. out    s        = ", n
            write ( * , fmt = fmt_two )       " 9. in     rcond    = ", rcond
            write ( * , fmt = fmt_two )       "10. out    rank     = ", rank
            write ( * , fmt = fmt_size_norm ) "11. out    work     = ", lwork, norm2 ( work )
            write ( * , fmt = fmt_two )       "12. inout  lwork    = ", lwork
            write ( * , fmt = fmt_array_1 )   "13. out    iwork    = ", n
            write ( * , fmt = fmt_two )       "14. out    info     = ", info

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
                io_work = safeopen_readwrite ( filename = "work_file_echo.txt" )
                do row = 1, lwork
                    write ( io_work , fmt = fmt_list_work ) row, work ( row )
                end do
                close ( io_work )
            endif

            write ( * , * ) ""
            write ( * , * ) "Rank and size:"
            write ( * , fmt = fmt_shape_r2 ) " mesh:      shape ( A )    = ", shape ( A )
            write ( * , fmt = fmt_shape_r2 ) " data:      shape ( b )    = ", shape ( b )
            write ( * , fmt = fmt_two )      " s:         shape ( s )    = ", shape ( s )
            write ( * , fmt = fmt_two )      " workspace: shape ( work ) = ", shape ( work )

        return

    end subroutine echo_dgelsd

    ! harvest error signal provided by LAPACK
    subroutine error_dgelsd ( info_value, message )
        use mPrecisionDefinitions, only : kindA
        integer, intent ( in ) :: info_value
        character ( kind = kindA, len = * ), intent ( in ), optional :: message
        character ( kind = kindA, len = 6 ), parameter :: iam = "DGELSD"

            if ( info_value == 0 ) then
                return
            endif

            if ( present ( message ) ) then
                write ( * , * ) message
            end if

            if ( info_value > 0 ) then
                write ( * , fmt = fmt_lapack_error ) iam
                write ( * , fmt = fmt_dgelsd_error ) info_value
                return
            else
                write ( * , fmt = fmt_lapack_error ) iam
                write ( * , fmt = 100 ) iam, abs ( info_value )
                return
            endif

        return

        100 format ( /, "Illegal value in call to dgelsd in slot ", g0, ". The slot arguments follow:", /, &
                    " 1. m     (input)            integer", /, &
                    " 2. n     (input)            integer", /, &
                    " 3. nrhs  (input)            integer", /, &
                    " 4. A     (input/output)     double precision  rank 2", /, &
                    " 5. lda   (input)            integer", /, &
                    " 6. b     (input/output)     double precision  rank 2", /, &
                    " 7. ldb   (input)            integer", /, &
                    " 8. s     (output)     integer           rank 1", /, &
                    " 9. rcond (input)            integer", /, &
                    "10. rank  (output)           integer", /, &
                    "11. work  (input)            double precision  rank 1", /, &
                    "12. lwork (workspace/output) integer", /, &
                    "13. iwork (workspace)        integer           rank 1", /, &
                    "14. info  (output)           integer" )
    end subroutine error_dgelsd

end module mLapackInterfaceDGELSD

! SUBROUTINE DGELSD( M, N, NRHS, A, LDA, B, LDB, S, RCOND, RANK, WORK, LWORK, IWORK, INFO )
!
!  -- LAPACK driver routine (version 3.1) --
!     Univ. of Tennessee, Univ. of California Berkeley and NAG Ltd..
!     November 2006
!
!     .. Scalar Arguments ..
! INTEGER            INFO, LDA, LDB, LWORK, M, N, NRHS, RANK
! DOUBLE PRECISION   RCOND
!     ..
!     .. Array Arguments ..
! INTEGER            IWORK( * )
! DOUBLE PRECISION   A( LDA, * ), B( LDB, * ), S( * ), WORK( * )
!     ..
!
!  Purpose
!  =======
!
!  DGELSD computes the minimum-norm solution to a real linear least
!  squares problem:
!      minimize 2-norm(| b - A*x |)
!  using the singular value decomposition (SVD) of A. A is an M-by-N
!  matrix which may be rank-deficient.
!
!  Several right hand side vectors b and solution vectors x can be
!  handled in a single call; they are stored as the columns of the
!  M-by-NRHS right hand side matrix B and the N-by-NRHS solution
!  matrix X.
!
!  The problem is solved in three steps:
!  (1) Reduce the coefficient matrix A to bidiagonal form with
!      Householder transformations, reducing the original problem
!      into a "bidiagonal least squares problem" (BLS)
!  (2) Solve the BLS using a divide and conquer approach.
!  (3) Apply back all the Householder tranformations to solve
!      the original least squares problem.
!
!  The effective rank of A is determined by treating as zero those
!  singular values which are less than RCOND times the largest singular
!  value.
!
!  The divide and conquer algorithm makes very mild assumptions about
!  floating point arithmetic. It will work on machines with a guard
!  digit in add/subtract, or on those binary machines without guard
!  digits which subtract like the Cray X-MP, Cray Y-MP, Cray C-90, or
!  Cray-2. It could conceivably fail on hexadecimal or decimal machines
!  without guard digits, but we know of none.
!
!  Arguments
!  =========
!
!  M       (input) INTEGER
!          The number of rows of A. M >= 0.
!
!  N       (input) INTEGER
!          The number of columns of A. N >= 0.
!
!  NRHS    (input) INTEGER
!          The number of right hand sides, i.e., the number of columns
!          of the matrices B and X. NRHS >= 0.
!
!  A       (input) DOUBLE PRECISION array, dimension (LDA,N)
!          On entry, the M-by-N matrix A.
!          On exit, A has been destroyed.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(1,M).
!
!  B       (input/output) DOUBLE PRECISION array, dimension (LDB,NRHS)
!          On entry, the M-by-NRHS right hand side matrix B.
!          On exit, B is overwritten by the N-by-NRHS solution
!          matrix X.  If m >= n and RANK = n, the residual
!          sum-of-squares for the solution in the i-th column is given
!          by the sum of squares of elements n+1:m in that column.
!
!  LDB     (input) INTEGER
!          The leading dimension of the array B. LDB >= max(1,max(M,N)).
!
!  S       (output) DOUBLE PRECISION array, dimension (min(M,N))
!          The singular values of A in decreasing order.
!          The condition number of A in the 2-norm = S(1)/S(min(m,n)).
!
!  RCOND   (input) DOUBLE PRECISION
!          RCOND is used to determine the effective rank of A.
!          Singular values S(i) <= RCOND*S(1) are treated as zero.
!          If RCOND < 0, machine precision is used instead.
!
!  RANK    (output) INTEGER
!          The effective rank of A, i.e., the number of singular values
!          which are greater than RCOND*S(1).
!
!  WORK    (workspace/output) DOUBLE PRECISION array, dimension (MAX(1,LWORK))
!          On exit, if INFO = 0, WORK(1) returns the optimal LWORK.
!
!  LWORK   (input) INTEGER
!          The dimension of the array WORK. LWORK must be at least 1.
!          The exact minimum amount of workspace needed depends on M,
!          N and NRHS. As long as LWORK is at least
!              12*N + 2*N*SMLSIZ + 8*N*NLVL + N*NRHS + (SMLSIZ+1)**2,
!          if M is greater than or equal to N or
!              12*M + 2*M*SMLSIZ + 8*M*NLVL + M*NRHS + (SMLSIZ+1)**2,
!          if M is less than N, the code will execute correctly.
!          SMLSIZ is returned by ILAENV and is equal to the maximum
!          size of the subproblems at the bottom of the computation
!          tree (usually about 25), and
!             NLVL = MAX( 0, INT( LOG_2( MIN( M,N )/(SMLSIZ+1) ) ) + 1 )
!          For good performance, LWORK should generally be larger.
!
!          If LWORK = -1, then a workspace query is assumed; the routine
!          only calculates the optimal size of the WORK array, returns
!          this value as the first entry of the WORK array, and no error
!          message related to LWORK is issued by XERBLA.
!
!  IWORK   (workspace) INTEGER array, dimension (MAX(1,LIWORK))
!          LIWORK >= 3 * MINMN * NLVL + 11 * MINMN,
!          where MINMN = MIN( M,N ).
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value.
!          > 0:  the algorithm for computing the SVD failed to converge;
!                if INFO = i, i .
!
