! 3456789 123456789 223456789 323456789 423456789 523456789 623456789 723456789 823456789 923456789 023456789 123456789 223456789 32
module mSolutionLeastSquares

    ! Modern Fortran Explained (p. 349)
    ! Metcalf, Michael; Reid, John; Cohen, Malcolm.

    use, intrinsic :: ieee_features,    only : ieee_denormal, ieee_nan, ieee_underflow_flag
    use, intrinsic :: ieee_exceptions,  only : ieee_overflow, ieee_underflow, ieee_divide_by_zero, ieee_invalid, ieee_inexact, &
                                               ieee_get_halting_mode, ieee_get_flag, ieee_set_flag, ieee_all, ieee_status_type, &
                                               ieee_get_status, ieee_set_status
    use, intrinsic :: iso_fortran_env,  only : stdin  => input_unit, &
                                               stdout => output_unit, &
                                               stderr => error_unit

    use mClassLinearSystem,             only : linearSystem
    use mClassSolutionBasic,            only : solutionBasic

    use mFileHandling,                  only : safeopen_readwrite, find_IU_info

    use mLapackInterfaceDGELS,          only : dgels,  error_dgels,  echo_dgels
    use mLapackInterfaceDGELSD,         only : dgelsd, error_dgelsd, echo_dgelsd
    use mLapackInterfaceDGELSX,         only : dgelsx, error_dgelsx, echo_dgelsx
    use mLapackInterfaceDGELSY,         only : dgelsy, error_dgelsy, echo_dgelsy
    use mLapackInterfaceDGETRF,         only : dgetrf, error_dgetrf, echo_dgetrf
    use mLapackInterfaceDGETRI,         only : dgetri, error_dgetri, echo_dgetri

    use mLibraryConstants,              only : machine_epsilon, zero
    use mPrecisionDefinitions,          only : ip, rp

    use mToolsAllocators,               only : toolKitAllocation, toolKitAllocation0
    use mToolsIEEE,                     only : toolKitIEEE, toolKitIEEE0

    implicit none

    integer :: k = 0, io_work = 0
    integer :: m = 0, n = 0, nrhs = 0, lda = 0, ldb = 0, info = 0, lwork = 0, nb = 0

    real ( kind = rp ) :: start = 0.0_rp, finish = 0.0_rp

    type ( toolKitAllocation ) :: alloc = toolKitAllocation0
    type ( toolKitIEEE )       :: ieeeFlags = toolKitIEEE0

contains

    module subroutine dgelsyHandler_sub ( inData, outSoln, io_unit )
        type ( linearSystem ),           intent ( in )       :: inData
        type ( solutionBasic ),          intent ( out )      :: outSoln
        integer ( kind = ip ), optional, intent ( in )       :: io_unit

        real ( kind = rp )                                   :: rcond = zero
        real ( kind = rp ), dimension ( 1 : 1 )              :: query
        real ( kind = rp ), dimension ( : ),     allocatable :: work
        real ( kind = rp ), dimension ( : , : ), allocatable :: AinOFout, bInxOut
        integer,            dimension ( : ),     allocatable :: jpvt
        integer               :: rank = 0, mu = 0, nu = 0
        integer ( kind = ip ) :: io = 0

            write ( io , * ) " ==   ==   == INSIDE dgelsyHandler_sub, io_unit = ", io_unit
            call find_IU_info ( io_unit )
            if ( present ( io_unit ) ) then
                io = io_unit
            else
                io = stdout
            endif
            write ( * , * )  " ==   ==   == * INSIDE dgelsyHandler_sub setting io = ", io
            write ( io , * ) " ==   ==   == INSIDE dgelsyHandler_sub setting io = ", io

            mu   = inData % m
            nu   = inData % n
            lda  = inData % lda
            ldb  = inData % ldb
            nrhs = inData % nrhs

                ! preserve the data by overwriting copies
                ! clone: copy shape, type, and values
            call alloc % allocate_using_source_rank_2 ( target_array = AinOFout, source_array = inData % A ( 1 : mu, 1 : nu ) )
            call alloc % allocate_using_source_rank_2 ( target_array = bInxOut,  source_array = inData % b ( 1 : mu, 1 : nrhs ) )
            call alloc % allocate_rank_one_integers ( integer_array = jpvt, index_min = 1, index_max = nu )

            !rcond = machine_epsilon
            rcond = -1.0_rp
            rcond = 0.00000001_rp

            write ( io , * ) ""
            write ( io , * ) "#  #  #  #  #  Solve the linear system using Lapack routine DGELSY"
            write ( io , * ) "               DGELSY computes the minimum-norm solution to a real"
            write ( io , * ) "               linear least squares problem:"
            write ( io , * ) "                    minimize || A * X - B ||"
            write ( io , * ) "               using a complete orthogonal factorization of A."
            write ( io , * ) "               A is an m x n matrix which may be rank-deficient."

            ! Query the optimal workspace.
            write ( io , * ) ""
            write ( io , * ) "DGELSY query to compute optimal workspace"

            lwork = -1
            call       dgelsy ( m = mu,           n = nu, nrhs = nrhs, &
                                A = AinOFout,   lda = lda, &
                                b = bInxOut,    ldb = ldb, &
                                jpvt = jpvt,  rcond = rcond, rank = rank, &
                                work = query, lwork = lwork, info = info )
            call error_dgelsy ( info, "workspace query" )

            lwork = nint ( query ( 1 ) )
            write ( io , * ) "shape ( bInxOut )    = ", shape ( bInxOut )
            write ( io , * ) "shape ( inData % b ) = ", shape ( inData % b )
            write ( io , * ) "size ( jpvt, 1 ) = ", size ( jpvt, 1 )

            call alloc % allocate_rank_one_reals ( real_array = work, index_min = 1, index_max = lwork )
            write ( io , * ) "work allocated with ", lwork, " elements; norm2 = ", norm2 ( work )
            nb = 64
            write ( io , * ) "NAG lwork = 3 * n + nb * ( n + 1 ) = ", 3 * nu + nb * ( nu + 1 )

                io_work = safeopen_readwrite ( filename = "work_file_input.txt" )
                write ( io , * ) "io_work = ", io_work
                do k = 1, lwork
                    write ( io_work , fmt = 160 ) k, work ( k )
                end do
                close ( io_work )

            write ( io , * ) "^ ^ ^ shape ( bInxOut )    = ", shape ( bInxOut )
            write ( io , * ) ""
            write ( io , * ) " into DGELSY.................... "
            call  echo_dgelsy ( m = mu,           n = nu, nrhs = nrhs, &
                                A = AinOFout,   lda = lda, &
                                b = bInxOut,    ldb = ldb, &
                                jpvt = jpvt,  rcond = rcond, rank = rank, &
                                work = query, lwork = lwork, info = info )
            call       dgelsy ( m = mu,           n = nu, nrhs = nrhs, &
                                A = AinOFout,   lda = lda, &
                                b = bInxOut,    ldb = ldb, &
                                jpvt = jpvt,  rcond = rcond, rank = rank, &
                                work = query, lwork = lwork, info = info )
            write ( io , * ) ""
            write ( io , * ) " out of DGELSY.................... "
            call  echo_dgelsy ( m = mu,           n = nu, nrhs = nrhs, &
                                A = AinOFout,   lda = lda, &
                                b = bInxOut,    ldb = ldb, &
                                jpvt = jpvt,  rcond = rcond, rank = rank, &
                                work = query, lwork = lwork, info = info )
            call error_dgelsy ( info, "solution for linear system" )
            write ( io , * ) "after dgelsy: work has ", lwork, " elements; norm2 = ", norm2 ( work )
            write ( io , * ) "^ ^ ^ shape ( bInxOut )    = ", shape ( bInxOut )

            ! compute residual error
            call outSoln % injectSolutionBasic ( x = bInxOut ( 1 : nu, 1 : nrhs ), &
                                                 descriptor = "DGELSY solution" )
            !write ( io , * ) "call outSoln % printSolutionBasic ( )"
            call outSoln % printSolutionBasic ( )
            ! call  echo_dgelsy ( m = mu,           n = nu, nrhs = nrhs, &
            !                     A = AinOFout,   lda = lda, &
            !                     b = bInxOut,    ldb = ldb, &
            !                     jpvt = jpvt,  rcond = rcond, rank = rank, &
            !                     work = query, lwork = lwork, info = info )
            ! write ( io , * ) "all done with outSoln % printSolutionBasic ( )"
            write ( io , * ) "all done with outSoln % printSolutionBasic ( )"

            call ieeeFlags % ieeeGetFlagStatus ( )
            call ieeeFlags % ieeeGetHaltingMode ( )

            work = zero
        return
    160 format ( "work ( ", g0, " ) = ", g0 )
    end subroutine dgelsyHandler_sub

    module subroutine smartInvertLUfactorization_sub ( A, Ainv, io_unit )
        ! dgetrf computes LU factorization
        ! dgetri inverts LU factorization
        integer ( kind = ip ), optional,         intent ( in )  :: io_unit
        real ( kind = rp ), dimension ( : , : ), intent ( in )  :: A
        real ( kind = rp ), dimension ( : , : ), intent ( out ) :: Ainv
        real ( kind = rp ), dimension ( : , : ), allocatable    :: LUFactorization
        integer,            dimension ( : ),     allocatable    :: ipv
        integer :: mu = 0, nu = 0
        integer ( kind = ip ) :: io = 0

            if ( present ( io_unit ) ) then
                io = io_unit
            else
                io = stdout
            endif

                ! matrix must be square
            mu = size ( A, 1 ) ! rows
            nu = size ( A, 2 ) ! cols

            if ( mu /= nu ) then
                write ( io , * ) "Error using DGETRI to invert a matrix using the PA = LU factorization"
                write ( io , * ) "Input matrix LUFactorization is not square."
                write ( io , * ) "Number of rows    = ", mu
                write ( io , * ) "Number of columns = ", nu
                return
            end if

            ! pivot list
        call alloc % allocate_rank_one_integers ( integer_array = ipv, index_min = 1, index_max = nu )
            ! duplicate type and size, not values
        call alloc % allocate_using_mold_rank_2 ( target_array = LUFactorization, mold_array = A )

        call dgetrfHandler_sub ( Amatrix         = A               ( 1 : mu, 1 : nu ), &
                                 LUFactorization = LUFactorization ( 1 : mu, 1 : nu ), &
                                 pivotArray      = ipv             ( 1 : nu ) )

        call dgetriHandler_sub ( LUFactorization = LUFactorization ( 1 : mu, 1 : nu ), &
                                 MatrixInverse   = Ainv            ( 1 : nu, 1 : mu ), &
                                 pivotArray      = ipv             ( 1 : nu ) )
        return
    end subroutine smartInvertLUfactorization_sub

    module subroutine InvertLUfactorization_sub ( inData, outSoln, io_unit )
        type ( linearSystem ),           intent ( in )  :: inData
        type ( solutionBasic ),          intent ( out ) :: outSoln
        integer ( kind = ip ), optional, intent ( in )  :: io_unit

        real ( kind = rp ), dimension ( : , : ), allocatable :: Astar, AsA, Asb, AsAinverse
        integer,            dimension ( : ),     allocatable :: ipv
        integer               :: mu = 0, nu = 0
        integer ( kind = ip ) :: io = 0

            if ( present ( io_unit ) ) then
                io = io_unit
            else
                io = stdout
            endif

            mu = inData % m
            nu = inData % n
            nrhs = inData % nrhs

                ! memory for pivot list shared between dgetr and dgetri
            call alloc % allocate_rank_one_integers ( integer_array = ipv, index_min = 1, index_max = nu )

                ! memory for A, A*, A*A, A*b
            call alloc % allocate_rank_two_reals ( real_array = Astar,      numRows = nu, numColumns = mu )
            call alloc % allocate_rank_two_reals ( real_array = AsA,        numRows = nu, numColumns = nu )
            call alloc % allocate_rank_two_reals ( real_array = AsAinverse, numRows = nu, numColumns = nu )
            call alloc % allocate_rank_two_reals ( real_array = Asb,        numRows = nu, numColumns = 1 )
                ! compute product matrix for normal equations
            Astar ( 1 : nu, 1 : mu ) = transpose ( inData % A ( 1 : mu, 1 : nu ) )
            AsA   ( 1 : nu, 1 : nu ) = matmul ( Astar, inData % A )
            Asb   ( 1 : nu, 1 : 1 )  = matmul ( Astar, inData % b )

            call cpu_time ( time = start )
                call smartInvertLUfactorization_sub ( A = AsA, Ainv = AsAinverse, io_unit = io )
            call cpu_time ( time = finish )

            call outSoln % injectSolutionBasic ( x = matmul ( AsAinverse, Asb ), &
                                                 descriptor = "Inverse via LU factorization of the normal equations", &
                                                 solutionTimeBasic = finish - start )
        return
    end subroutine InvertLUfactorization_sub

    module subroutine dgetriHandler_sub ( LUFactorization, MatrixInverse, pivotArray )
        !  DGETRI computes the inverse of a matrix using the LU factorization
        !  computed by DGETRF.
        !
        !  This method inverts U and then computes inv(A) by solving the system
        !  inv(A)*L = inv(U) for inv(A).
        real ( kind = rp ), dimension ( : , : ), intent ( in )  :: LUFactorization
        real ( kind = rp ), dimension ( : , : ), intent ( out ) :: MatrixInverse
        integer,            dimension ( : ),     intent ( in )  :: pivotArray

        real ( kind = rp ), dimension ( 1 : 1 )                 :: query = zero
        real ( kind = rp ), dimension ( : ),     allocatable    :: work
        integer                                                 :: mu = 0, nu = 0

            mu = size ( LUFactorization, 1 )
            nu = size ( LUFactorization, 2 )
            if ( mu /= nu ) then
                write ( * , * ) "Error calling DGETRI to invert a matrix using the PA = LU factorization"
                write ( * , * ) "Input matrix LUFactorization is not square."
                write ( * , * ) "Number of rows    = ", mu
                write ( * , * ) "Number of columns = ", nu
                return
            end if

            MatrixInverse ( 1 : nu, 1 : nu ) = LUFactorization ( 1 : nu, 1 : nu )
                ! query size of work array
            lwork = -1
            call       dgetri ( n = nu, A = MatrixInverse, lda = nu, ipv = pivotArray, work = query, lwork = lwork, info = info )
            call error_dgetri ( info, "workspace query" )

            lwork = nint ( query ( 1 ) )
            call alloc % allocate_rank_one_reals ( real_array = work, index_min = 1, index_max = lwork )
                ! invert matrix
            call       dgetri ( n = nu, A = MatrixInverse, lda = nu, ipv = pivotArray, work = work, lwork = lwork, info = info )
            call error_dgetri ( info, "solution for matrix inverse" )

        return
    end subroutine dgetriHandler_sub

    module subroutine dgetrfHandler_sub ( Amatrix, LUFactorization, pivotArray )
            ! Use dgetrf to compute LU factorization
        real ( kind = rp ), dimension ( : , : ), intent ( in )    :: Amatrix
        real ( kind = rp ), dimension ( : , : ), intent ( out )   :: LUFactorization
        integer,            dimension ( : ),     intent ( inout ) :: pivotArray

        !integer, dimension ( : ), allocatable :: ipv
        integer :: minnm = 0, mu = 0, nu = 0
                ! shorthand to make the code easier to read
            mu = size ( Amatrix, 1 )
            nu = size ( Amatrix, 2 )
            minnm = min ( mu, nu )

            LUFactorization ( 1 : mu, 1 : nu ) = Amatrix ( 1 : mu, 1 : nu )

                ! clone: copy size, type, values
            call       dgetrf ( m = mu, n = nu, A = LUFactorization, lda = nu, ipv = pivotArray, info = info )
            call error_dgetrf ( info, "LU decomposition" )

        return
    end subroutine dgetrfHandler_sub

    module subroutine dgelsdHandler_sub ( inData, outSoln )
        type ( linearSystem ),  intent ( in )                :: inData
        type ( solutionBasic ), intent ( out )               :: outSoln
        real ( kind = rp )                                   :: rcond = zero
        real ( kind = rp ), dimension ( 1 : 1 )              :: query
        real ( kind = rp ), dimension ( : ),     allocatable :: work, s
        real ( kind = rp ), dimension ( : , : ), allocatable :: AinOFout, bInxOut
        integer,            dimension ( : ),     allocatable :: iwork
        integer :: rank = 0, mu = 0, nu = 0

            mu = inData % m
            nu = inData % n
            lda  = inData % lda
            ldb  = inData % ldb
            nrhs = inData % nrhs

                ! preserve the data by overwriting copies
                ! clone: copy shape, type, and values
            call alloc % allocate_using_source_rank_2 ( target_array = AinOFout, source_array = inData % A )
            call alloc % allocate_using_source_rank_2 ( target_array = bInxOut,  source_array = inData % b )

            call alloc % allocate_rank_one_integers ( integer_array = iwork, index_min = 1, index_max = 1028 )

            !rcond = machine_epsilon
            rcond = -1.0_rp
            rcond = 0.001_rp
            rcond = machine_epsilon

            ! Query the optimal workspace.
            write ( * , * ) ""
            write ( * , * ) "DGELSD query to compute optimal workspace"

            lwork = -1
            call       dgelsd ( m = mu,           n = nu, nrhs = nrhs, &
                                A = AinOFout,   lda = lda, &
                                b = bInxOut,    ldb = ldb, &
                                s = s,        rcond = rcond, rank = rank, &
                                work = query, lwork = lwork, iwork = iwork, info = info )
            call error_dgelsd ( info, "workspace query" )

            write ( * , * ) ""
            write ( * , * ) "DGELSD solution for linear system"
            write ( * , * ) "D shape ( work ) = ", shape ( work )
            write ( * , * ) "D allocated ( work ) = ", allocated ( work )
            lwork = nint ( query ( 1 ) )

            call alloc % allocate_rank_one_reals ( real_array = work, index_min = 1, index_max = lwork )
            write ( * , * ) "before echo: work allocated with ", lwork, " elements; norm2 = ", norm2 ( work )
            write ( * , * ) "shape ( iwork ) = ", shape ( iwork )
            work = zero
            write ( * , * ) ""
            write ( * , * ) "after work allocated with ", lwork, " elements; norm2 = ", norm2 ( work )
                ! io_work = safeopen_readwrite ( filename = "work_file_input.txt" )
                ! do k = 1, lwork
                !     write ( io_work , fmt = 160 ) k, work ( k )
                ! end do
            call cpu_time ( time = start )
                call  echo_dgelsd ( m = mu,           n = nu, nrhs = nrhs, &
                                    A = AinOFout,   lda = lda, &
                                    b = bInxOut,    ldb = ldb, &
                                    s = s,        rcond = rcond,  rank = rank, &
                                    work = query, lwork = lwork, iwork = iwork, info = info )

                call       dgelsd ( m = mu,           n = nu, nrhs = nrhs, &
                                    A = AinOFout,   lda = lda, &
                                    b = bInxOut,    ldb = ldb, &
                                    s = s,        rcond = rcond,  rank = rank, &
                                    work = query, lwork = lwork, iwork = iwork, info = info )
            call cpu_time ( time = finish )

            call error_dgelsd ( info, "solution for linear system" )

            ! compute residual error
            call outSoln % injectSolutionBasic ( x = bInxOut ( 1 : nu, 1 : nrhs ), &
                                                 descriptor = "DGELSD solution", solutionTimeBasic = finish - start )
            write ( * , * ) "D call outSoln % printSolutionBasic ( )"
        return
    end subroutine dgelsdHandler_sub

    module subroutine dgelsxHandler_sub ( inData, outSoln )
        type ( linearSystem ),  intent ( in )                :: inData
        type ( solutionBasic ), intent ( out )               :: outSoln
        real ( kind = rp )                                   :: rcond = zero
        real ( kind = rp ), dimension ( 1 : 1 )              :: query
        real ( kind = rp ), dimension ( : ),     allocatable :: work
        real ( kind = rp ), dimension ( : , : ), allocatable :: AinOFout, bInxOut
        integer,            dimension ( : ),     allocatable :: jpvt
        integer :: rank = 0, mu = 0 , nu = 0

            mu = inData % m
            nu = inData % n
            lda  = inData % lda
            ldb  = inData % ldb
            nrhs = inData % nrhs

                ! preserve the data by overwriting copies
                ! clone: copy shape, type, and values
            call alloc % allocate_using_source_rank_2 ( target_array = AinOFout, source_array = inData % A ( 1 : mu, 1 : nu ) )
            call alloc % allocate_using_source_rank_2 ( target_array = bInxOut,  source_array = inData % b ( 1 : mu, 1 : nrhs ) )

            write ( * , * ) "allocated ( jpvt ) = ", allocated ( jpvt )

            call alloc % allocate_rank_one_integers ( integer_array = jpvt, index_min = 1, index_max = nu )
            write ( * , * ) "allocated ( jpvt ) = ", allocated ( jpvt )
            write ( * , * ) "shape ( jpvt ) = ", shape ( jpvt )
            write ( * , * ) "dot_product ( jpvt ) = ", dot_product( jpvt, jpvt )
            write ( * , * ) "in jpvt = ", jpvt

            !rcond = machine_epsilon
            rcond = -1.0_rp
            rcond = 0.001_rp

            ! Query the optimal workspace.
            write ( * , * ) ""
            write ( * , * ) "DGELSX query to compute optimal workspace"

            lwork = -1
            call       dgelsx ( m = mu,           n = nu, nrhs = nrhs, &
                                A = AinOFout,   lda = lda, &
                                b = bInxOut,    ldb = ldb, &
                                jpvt = jpvt,  rcond = rcond, rank = rank, &
                                work = query, lwork = lwork, info = info )
            call error_dgelsx ( info, "workspace query" )

            write ( * , * ) ""
            write ( * , * ) "DGELSX solution for linear system"
            write ( * , * ) "X shape ( work ) = ", shape ( work )
            write ( * , * ) "X allocated ( work ) = ", allocated ( work )
            lwork = nint ( query ( 1 ) )
            write ( * , * ) "query = ", query
            write ( * , * ) "lwork = ", lwork

            !write ( * , * ) "before echo: work allocated with ", lwork, " elements; norm2 = ", norm2 ( work )
            call alloc % allocate_rank_one_reals ( real_array = work, index_min = 1, index_max = lwork )
            work = zero
            write ( * , * ) ""
            write ( * , * ) "after work allocated with ", lwork, " elements; norm2 = ", norm2 ( work )
                io_work = safeopen_readwrite ( filename = "work_file_input.txt" )
                do k = 1, lwork
                    write ( io_work , fmt = 160 ) k, work ( k )
                end do
            call       dgelsx ( m = mu,           n = nu, nrhs = nrhs, &
                                A = AinOFout,   lda = lda, &
                                b = bInxOut,    ldb = ldb, &
                                jpvt = jpvt,  rcond = rcond, rank = rank, &
                                work = query, lwork = lwork, info = info )
            call error_dgelsx ( info, "solution for linear system" )

            ! compute residual error
            call outSoln % injectSolutionBasic ( x = bInxOut ( 1 : inData %  n, 1 : nrhs ), &
                                                 descriptor = "DGELSX solution" )
            write ( * , * ) "X call outSoln % printSolutionBasic ( )"
            call outSoln % printSolutionBasic ( )
            call  echo_dgelsx ( m = mu,           n = nu,  nrhs = nrhs, &
                                A = AinOFout,   lda = lda, &
                                b = bInxOut,    ldb = ldb, &
                                jpvt = jpvt,  rcond = rcond, rank = rank, &
                                work = query, lwork = lwork, info = info )
            write ( * , * ) "X all done with outSoln % printSolutionBasic ( )"
            work = zero
        return
    160 format ( "X work ( ", g0, " ) = ", g0 )
    end subroutine dgelsxHandler_sub

    module subroutine dgelsHandler_sub ( inData, outSoln )
        type ( linearSystem ),  intent ( in )                :: inData
        type ( solutionBasic ), intent ( out )               :: outSoln
        real ( kind = rp ), dimension ( 1 : 1 )              :: query
        real ( kind = rp ), dimension ( : ),     allocatable :: work
        real ( kind = rp ), dimension ( : , : ), allocatable :: AinOFout, bInxOut

            m = inData % m
            n = inData % n
            lda  = inData % lda
            ldb  = inData % ldb
            nrhs = inData % nrhs

                ! preserve the data by overwriting copies
                ! clone: copy shape, type, and values
            call alloc % allocate_using_source_rank_2 ( target_array = AinOFout, source_array = inData % A ( 1 : m, 1 : n ) )
            call alloc % allocate_using_source_rank_2 ( target_array = bInxOut,  source_array = inData % b ( 1 : m, 1 : nrhs ) )

            write ( * , * ) ""
            write ( * , * ) "#  #  #  #  #  Solve the linear system using Lapack routine DGELS"
            write ( * , * ) "               DGELS solves overdetermined or underdetermined real linear systems"
            write ( * , * ) "               involving an M-by-N matrix A, or its transpose, using a QR or LQ"
            write ( * , * ) "               factorization of A.  It is assumed that A has full rank."

            ! Query the optimal workspace.
            write ( * , * ) ""
            write ( * , * ) "DGELS query to compute optimal workspace"

            lwork = -1
            call       dgels ( trans = 'N', m = m, n = n, nrhs = nrhs, &
                               A = AinOFout ( 1 : m, 1 : n ),    lda = lda, &
                               b = bInxOut  ( 1 : m, 1 : nrhs ), ldb = ldb, &
                               work = query, lwork = lwork, info = info )
            call error_dgels ( info, "workspace query" )

            write ( * , * ) ""
            write ( * , * ) "DGELS solution for linear system"
            lwork = nint ( query ( 1 ) )

            call alloc % allocate_rank_one_reals ( real_array = work, index_min = 1, index_max = lwork )

            call       dgels ( trans = 'N', m = m, n = n, nrhs = nrhs, &
                               A = AinOFout ( 1 : m, 1 : n ),    lda = lda, &
                               b = bInxOut  ( 1 : m, 1 : nrhs ), ldb = ldb, &
                               work = work,  lwork = lwork, info = info )
            call error_dgels ( info, "solution for linear system" )

            ! compute residual error
            call outSoln % injectSolutionBasic ( x = bInxOut ( 1 : n, 1 : nrhs ), &
                                                 descriptor = "DGELS solution for Intel example" )
            !call outSoln % printSolutionBasic ( )

        return
    end subroutine dgelsHandler_sub

end module mSolutionLeastSquares
