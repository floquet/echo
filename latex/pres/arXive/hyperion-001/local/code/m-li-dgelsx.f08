! 3456789 123456789 223456789 323456789 423456789 523456789 623456789 723456789 823456789 923456789 023456789 123456789 223456789 32
! https://stackoverflow.com/questions/8508590/standard-input-and-output-units-in-fortran-90
! https://stackoverflow.com/questions/67463087/error-in-lapack-routine-sgels-using-an-interface-and-allocatable-work-array
! https://www.netlib.org/lapack/explore-3.1.1-html/dgelsx.f.html
module mLapackInterfaceDGELSX

    use, intrinsic :: iso_fortran_env,  only : stdout => output_unit
    use mFileHandling,                  only : safeopen_readwrite
    use mFormatDescriptorsBasics,       only : fmt_two
    use mFormatDescriptorsLapack,       only : fmt_array_1, fmt_array_2, fmt_dgelsd_error, fmt_elements, fmt_lapack_error, &
                                               fmt_listA, fmt_listb, fmt_list_work, fmt_shape_r2, fmt_size_norm, fmt_no_positive
    implicit none

    interface lapack_dgelsx

        subroutine dgelsx ( m, n, nrhs, A, lda, b, ldb, jpvt, rcond, rank, work, lwork, info )
            use mPrecisionDefinitions, only : rp
            integer,                                              intent ( in )    :: m, n, nrhs, lda, ldb, lwork
            integer,                                              intent ( out )   :: rank, info
            integer,            dimension ( 1 : n ),              intent ( inout ) :: jpvt
            real ( kind = rp ), dimension ( 1 : lwork ),          intent ( out )   :: work
            real ( kind = rp ), dimension ( 1 : lda , 1 : n ),    intent ( inout ) :: A
            real ( kind = rp ), dimension ( 1 : ldb , 1 : nrhs ), intent ( inout ) :: b
            real ( kind = rp ),                                   intent ( in )    :: rcond
        end subroutine dgelsx

    end interface lapack_dgelsx

contains

    subroutine echo_dgelsx ( m, n, nrhs, A, lda, b, ldb, jpvt, rcond, rank, work, lwork, info )
        use mPrecisionDefinitions, only : rp
        integer,                                              intent ( in )    :: m, n, nrhs, lda, ldb, lwork
        integer,                                              intent ( out )   :: rank, info
        integer,            dimension ( 1 : n ),              intent ( inout ) :: jpvt
        real ( kind = rp ), dimension ( 1 : lwork ),          intent ( out )   :: work
        real ( kind = rp ), dimension ( 1 : lda , 1 : n ),    intent ( inout ) :: A
        real ( kind = rp ), dimension ( 1 : ldb , 1 : nrhs ), intent ( inout ) :: b
        real ( kind = rp ),                                   intent ( in )    :: rcond
        integer :: col = 0, row = 0, io_work = 0

            write ( * , * ) "Slot arguments to dgelsx:"
            write ( * , fmt = fmt_two )       " 1. in     m     = ", m
            write ( * , fmt = fmt_two )       " 2. in     n     = ", n
            write ( * , fmt = fmt_two )       " 3. in     nrhs  = ", nrhs
            write ( * , fmt = fmt_array_2 )   " 4. inout  A     = ", lda, n
            write ( * , fmt = fmt_two )       " 5. in     lda   = ", lda
            write ( * , fmt = fmt_array_2 )   " 6. inout  b     = ", ldb, nrhs
            write ( * , fmt = fmt_two )       " 7. in     ldb   = ", ldb
            write ( * , fmt = fmt_array_1 )   " 8. inout  jpvt  = ", n
            write ( * , fmt = fmt_two )       " 9. in     rcond = ", rcond
            write ( * , fmt = fmt_two )       "10. out    rank  = ", rank
            write ( * , fmt = fmt_size_norm ) "11. out    work  = ", lwork, norm2 ( work )
            write ( * , fmt = fmt_two )       "12. inout  lwork = ", lwork
            write ( * , fmt = fmt_two )       "13. out    info  = ", info

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
            write ( * , fmt = fmt_two )      " jpvt:      shape ( jpvt ) = ", shape ( jpvt )
            write ( * , fmt = fmt_two )      " workspace: shape ( work ) = ", shape ( work )

        return

    end subroutine echo_dgelsx

    subroutine error_dgelsx ( info_value, message )
        use mPrecisionDefinitions, only : kindA
        integer, intent ( in ) :: info_value
        character ( kind = kindA, len = * ), intent ( in ), optional :: message
        character ( kind = kindA, len = 6 ), parameter :: iam = "DGELSX"

            if ( info_value == 0 ) then
                return
            endif

            if ( present ( message ) ) then
                write ( * , * ) message
            end if

            if ( info_value > 0 ) then
                write ( * , fmt = fmt_lapack_error ) iam
                write ( * , fmt = fmt_no_positive ) iam, info_value
                return
            else
                write ( * , fmt = fmt_lapack_error ) iam
                write ( * , fmt = 100 ) iam, abs ( info_value )
                return
            endif

        return

        100 format ( /, "Illegal value in call to ", g0, " in slot ", g0, ". The slot arguments follow:", /, &
                    " 1. m     (input)            integer", /, &
                    " 2. n     (input)            integer", /, &
                    " 3. nrhs  (input)            integer", /, &
                    " 4. A     (input/output)     double precision  rank 2", /, &
                    " 5. lda   (input)            integer", /, &
                    " 6. b     (input/output)     double precision  rank 2", /, &
                    " 7. ldb   (input)            integer", /, &
                    " 8. jpvt  (input/output)     integer           rank 1", /, &
                    " 9. rcond (input)            integer", /, &
                    "10. rank  (output)           integer", /, &
                    "11. work  (input)            double precision  rank 1", /, &
                    "12. lwork (workspace/output) integer", /, &
                    "13. info  (output)           integer" )
    end subroutine error_dgelsx

end module mLapackInterfaceDGELSX


!       SUBROUTINE DGELSX( M, N, NRHS, A, LDA, B, LDB, JPVT, RCOND, RANK, WORK, LWORK, INFO )
!
!  -- LAPACK driver routine (version 3.1) --
!     Univ. of Tennessee, Univ. of California Berkeley and NAG Ltd..
!     November 2006
!
!     .. Scalar Arguments ..
!       INTEGER            INFO, LDA, LDB, LWORK, M, N, NRHS, RANK
!       DOUBLE PRECISION   RCOND
!     ..
!     .. Array Arguments ..
!       INTEGER            JPVT( * )
!       DOUBLE PRECISION   A( LDA, * ), B( LDB, * ), WORK( * )
!     ..
!
!  Purpose
!  =======
!
!  DGELSX computes the minimum-norm solution to a real linear least
!  squares problem:
!      minimize || A * X - B ||
!  using a complete orthogonal factorization of A.  A is an M-by-N
!  matrix which may be rank-deficient.
!
!  Several right hand side vectors b and solution vectors x can be
!  handled in a single call; they are stored as the columns of the
!  M-by-NRHS right hand side matrix B and the N-by-NRHS solution
!  matrix X.
!
!  The routine first computes a QR factorization with column pivoting:
!      A * P = Q * [ R11 R12 ]
!                  [  0  R22 ]
!  with R11 defined as the largest leading submatrix whose estimated
!  condition number is less than 1/RCOND.  The order of R11, RANK,
!  is the effective rank of A.
!
!  Then, R22 is considered to be negligible, and R12 is annihilated
!  by orthogonal transformations from the right, arriving at the
!  complete orthogonal factorization:
!     A * P = Q * [ T11 0 ] * Z
!                 [  0  0 ]
!  The minimum-norm solution is then
!     X = P * Z' [ inv(T11)*Q1'*B ]
!                [        0       ]
!  where Q1 consists of the first RANK columns of Q.
!
!  This routine is basically identical to the original xGELSX except
!  three differences:
!    o The call to the subroutine xGEQPF has been substituted by the
!      the call to the subroutine xGEQP3. This subroutine is a Blas-3
!      version of the QR factorization with column pivoting.
!    o Matrix B (the right hand side) is updated with Blas-3.
!    o The permutation of matrix B (the right hand side) is faster and
!      more simple.
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
!  NRHS    (input) INTEGER
!          The number of right hand sides, i.e., the number of
!          columns of matrices B and X. NRHS >= 0.
!
!  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
!          On entry, the M-by-N matrix A.
!          On exit, A has been overwritten by details of its
!          complete orthogonal factorization.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(1,M).
!
!  B       (input/output) DOUBLE PRECISION array, dimension (LDB,NRHS)
!          On entry, the M-by-NRHS right hand side matrix B.
!          On exit, the N-by-NRHS solution matrix X.
!
!  LDB     (input) INTEGER
!          The leading dimension of the array B. LDB >= max(1,M,N).
!
!  JPVT    (input/output) INTEGER array, dimension (N)
!          On entry, if JPVT(i) .ne. 0, the i-th column of A is permuted
!          to the front of AP, otherwise column i is a free column.
!          On exit, if JPVT(i) = k, then the i-th column of AP
!          was the k-th column of A.
!
!  RCOND   (input) DOUBLE PRECISION
!          RCOND is used to determine the effective rank of A, which
!          is defined as the order of the largest leading triangular
!          submatrix R11 in the QR factorization with pivoting of A,
!          whose estimated condition number < 1/RCOND.
!
!  RANK    (output) INTEGER
!          The effective rank of A, i.e., the order of the submatrix
!          R11.  This is the same as the order of the submatrix T11
!          in the complete orthogonal factorization of A.
!
!  WORK    (workspace/output) DOUBLE PRECISION array, dimension (MAX(1,LWORK))
!          On exit, if INFO = 0, WORK(1) returns the optimal LWORK.
!
!  LWORK   (input) INTEGER
!          The dimension of the array WORK.
!          The unblocked strategy requires that:
!             LWORK >= MAX( MN+3*N+1, 2*MN+NRHS ),
!          where MN = min( M, N ).
!          The block algorithm requires that:
!             LWORK >= MAX( MN+2*N+NB*(N+1), 2*MN+NB*NRHS ),
!          where NB is an upper bound on the blocksize returned
!          by ILAENV for the routines DGEQP3, DTZRZF, STZRQF, DORMQR,
!          and DORMRZ.
!
!          If LWORK = -1, then a workspace query is assumed; the routine
!          only calculates the optimal size of the WORK array, returns
!          this value as the first entry of the WORK array, and no error
!          message related to LWORK is issued by XERBLA.
!
!  INFO    (output) INTEGER
!          = 0: successful exit
!          < 0: If INFO = -i, the i-th argument had an illegal value.
