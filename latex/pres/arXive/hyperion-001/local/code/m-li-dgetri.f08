! 3456789 123456789 223456789 323456789 423456789 523456789 623456789 723456789 823456789 923456789 023456789 123456789 223456789 32
! https://stackoverflow.com/questions/8508590/standard-input-and-output-units-in-fortran-90
! https://stackoverflow.com/questions/67463087/error-in-lapack-routine-sgels-using-an-interface-and-allocatable-work-array
! https://stackoverflow.com/questions/26475987/lapack-inversion-routine-strangely-mixes-up-all-variables
! https://www.netlib.org/lapack/explore-3.1.1-html/dgetri.f.html
module mLapackInterfaceDGETRI

    use, intrinsic :: iso_fortran_env,  only : stdout => output_unit
    use mFileHandling,                  only : safeopen_readwrite
    use mFormatDescriptorsBasics,       only : fmt_two
    use mFormatDescriptorsLapack,       only : fmt_array_1, fmt_array_2, fmt_dgetrf_error, fmt_elements, fmt_lapack_error, &
                                               fmt_listA, fmt_listb, fmt_list_work, fmt_shape_r2, fmt_size_norm

    implicit none

    interface lapack_dgetri

        subroutine dgetri ( n, A, lda, ipv, work, lwork, info )
            use mPrecisionDefinitions, only : rp
            integer,                                                   intent ( in )    :: n, lda, lwork
            integer,                                                   intent ( out )   :: info
            integer,                 dimension ( 1 : n ),              intent ( in )    :: ipv
            real      ( kind = rp ), dimension ( 1 : lwork ),          intent ( out )   :: work
            real      ( kind = rp ), dimension ( 1 : lda , 1 : n ),    intent ( inout ) :: A
        end subroutine dgetri

    end interface lapack_dgetri

contains

    subroutine echo_dgetri ( n, A, lda, ipv, work, lwork, info )
        use mPrecisionDefinitions, only : rp
        integer,                                           intent ( in ) :: n, lda, lwork
        integer,                                           intent ( in ) :: info
        integer,            dimension ( 1 : n ),           intent ( in ) :: ipv
        real ( kind = rp ), dimension ( 1 : lwork ),       intent ( in ) :: work
        real ( kind = rp ), dimension ( 1 : lda , 1 : n ), intent ( in ) :: A

        integer :: col = 0, row = 0, io_work = 0

            write ( * , * ) "Slot arguments to dgetri:"
            write ( * , fmt = fmt_two )      " 1. in     n     = ", n
            write ( * , fmt = fmt_array_2 )   " 2. inout  A     = ", lda, n
            write ( * , fmt = fmt_two )       " 3. in     lda   = ", lda
            write ( * , fmt = fmt_array_1 )   " 4. in     ipv   = ", n
            write ( * , fmt = fmt_size_norm ) " 5. out    work  = ", lwork, norm2 ( work )
            write ( * , fmt = fmt_two )       " 6. inout  lwork = ", lwork
            write ( * , fmt = fmt_two )       " 7. out    info  = ", info

            write ( * , * ) ""
            write ( * , fmt = fmt_elements ) n * lda, "design matrix A"
            do col = 1, n
                do row = 1, lda
                    write ( * , fmt = fmt_listA ) row, col, A ( row, col )
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
            write ( * , fmt = fmt_two )      " workspace: shape ( work ) = ", shape ( work )
            write ( * , fmt = fmt_two )      " pivots:    shape ( ipv )  = ", shape ( ipv )

        return

    end subroutine echo_dgetri

    subroutine error_dgetri ( info_value, message )
        use mPrecisionDefinitions, only : kindA
        integer, intent ( in ) :: info_value
        character ( kind = kindA, len = * ), intent ( in ), optional :: message
        character ( kind = kindA, len = 6 ), parameter :: iam = "DGETRI"

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

    100 format ( /, "Illegal value in call to dgetri in slot ", g0, ". The slot arguments follow:", /, &
                    " 1. n     (input)            integer", /, &
                    " 2. A     (input/output)     double precision  rank 2", /, &
                    " 3. lda   (input)            integer", /, &
                    " 4. ipv   (input)            integer", /, &
                    " 5. work  (input)            double precision  rank 1", /, &
                    " 6. lwork (workspace/output) integer", /, &
                    " 7. info  (output)           integer" )
    end subroutine error_dgetri

end module mLapackInterfacedgetri


!      SUBROUTINE DGETRI( N, A, LDA, IPIV, WORK, LWORK, INFO )
!
!  -- LAPACK routine (version 3.1) --
!     Univ. of Tennessee, Univ. of California Berkeley and NAG Ltd..
!     November 2006
!
!     .. Scalar Arguments ..
!       INTEGER            INFO, LDA, LWORK, N
!     ..
!     .. Array Arguments ..
!       INTEGER            IPIV( * )
!       DOUBLE PRECISION   A( LDA, * ), WORK( * )
!     ..
!
!  Purpose
!  =======
!
!  DGETRI computes the inverse of a matrix using the LU factorization
!  computed by DGETRF.
!
!  This method inverts U and then computes inv(A) by solving the system
!  inv(A)*L = inv(U) for inv(A).
!
!  Arguments
!  =========
!
!  N       (input) INTEGER
!          The order of the matrix A.  N >= 0.
!
!  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
!          On entry, the factors L and U from the factorization
!          A = P*L*U as computed by DGETRF.
!          On exit, if INFO = 0, the inverse of the original matrix A.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(1,N).
!
!  IPIV    (input) INTEGER array, dimension (N)
!          The pivot indices from DGETRF; for 1<=i<=N, row i of the
!          matrix was interchanged with row IPIV(i).
!
!  WORK    (workspace/output) DOUBLE PRECISION array, dimension (MAX(1,LWORK))
!          On exit, if INFO=0, then WORK(1) returns the optimal LWORK.
!
!  LWORK   (input) INTEGER
!          The dimension of the array WORK.  LWORK >= max(1,N).
!          For optimal performance LWORK >= N*NB, where NB is
!          the optimal blocksize returned by ILAENV.
!
!          If LWORK = -1, then a workspace query is assumed; the routine
!          only calculates the optimal size of the WORK array, returns
!          this value as the first entry of the WORK array, and no error
!          message related to LWORK is issued by XERBLA.
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value
!          > 0:  if INFO = i, U(i,i) is exactly zero; the matrix is
!                singular and its inverse could not be computed.
!
!  =====================================================================
