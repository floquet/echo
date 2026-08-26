    ! 3456789 123456789 223456789 323456789 423456789 523456789 623456789 723456789 823456789 923456789 023456789 123456789 223456789 32
module mClassLinearSystem
    ! data which defines the linear system for the affine transformation

    use, intrinsic :: iso_fortran_env,  only : stdin  => input_unit, &
                                               stdout => output_unit, &
                                               stderr => error_unit
    use mToolsAllocators,               only : toolKitAllocation, toolKitAllocation0
    use mFormatDescriptorsBasics,       only : fmt_one, fmt_two, fmt_five
    use mLibraryConstants,              only : descriptorLength
    use mPrintMatrix,                   only : printMatrix
    use mPrecisionDefinitions,          only : ip, rp, kindA

    implicit none

    integer ( ip ) :: k = 0_ip, row = 0_ip, io = 0

    type :: linearSystem
        ! A X = B
        ! A: m x n, X: n x nrhs, B: m x nrhs
        integer :: m = 0, n = 0, nrhs = 0 ! rows, columns, number of right-hand sides
        integer :: lda = 0, ldb = 0       ! leading dimensions for A and b
        integer :: dof = 0                ! degrees of freedom: measurements - free parameters

        real ( kind = rp ), dimension ( : , : ), allocatable :: A, b

        character ( kind = kindA, len = descriptorLength ) :: descriptor = "Identify data source"
        type ( toolKitAllocation ) :: alloc = toolKitAllocation0
    contains
        procedure, public :: injectLinearSystem => injectlinearSystem_sub, &
                             printLinearSystem  => printLinearSystem_sub
    end type linearSystem

    private :: injectlinearSystem_sub, printLinearSystem_sub

contains

    module subroutine injectlinearSystem_sub ( me, m, n, nrhs, A, b, lda, ldb, descriptor )
        ! use the mesh data to construct the design matrix A
        class ( linearSystem ), target :: me
        character ( kind = kindA, len = * ),     intent ( in ) :: descriptor
        integer,                                 intent ( in ) :: m, n, nrhs
        integer, optional,                       intent ( in ) :: lda, ldb   ! derived size parameters
        real ( kind = rp ), dimension ( : , : ), intent ( in ) :: A, b

            me % m    = m
            me % n    = n
            me % nrhs = nrhs
            me % dof  = m - n

            ! leading dimensions for Lapack
            if ( present ( lda ) ) then
                me % lda = lda
            else
                me % lda = max ( m, n )
            endif
            if ( present ( ldb ) ) then
                me % ldb = ldb
            else
                me % ldb = max ( m, n, 1 )
            endif

            call me % alloc % allocate_rank_two_reals ( real_array = me % A, numRows = m, numColumns = n )
            call me % alloc % allocate_rank_two_reals ( real_array = me % b, numRows = m, numColumns = nrhs )

            me % A ( : , : ) = A ( : , : )
            me % b ( : , : ) = b ( : , : )
            me % descriptor  = descriptor

        return
    end subroutine injectlinearSystem_sub

    module subroutine printLinearSystem_sub ( me, io_unit )

        class ( linearSystem ), target :: me
        integer ( kind = ip ), optional, intent ( in ) :: io_unit

            if ( present ( io_unit ) ) then
                io = io_unit
            else
                io = stdout
            endif

            write ( io, * ) ""
            write ( io, fmt = fmt_one ) "Input data source:"
            write ( io, fmt = fmt_one ) me % descriptor
            write ( io, fmt = fmt_two ) "number of measurements,     m    = ", me % m
            write ( io, fmt = fmt_two ) "number of free parameters,  n    = ", me % n
            write ( io, fmt = fmt_two ) "number of right-hand sides, nrhs = ", me % nrhs

            call printMatrix ( A = me % A, myFormat = "F7.3", spaces = 2, moniker = "design matrix",  my_io_unit = io )
            call printMatrix ( A = me % b, myFormat = "F7.3", spaces = 2, moniker = "data vector(s)", my_io_unit = io )

            ! write ( io, * ) ""
            ! write ( io, fmt = fmt_five ) "Data vectors have length ", me % m, ":"
            ! do k = 1, me % nrhs
            !     write ( io, fmt = fmt_five ) "Right-hand side ", k, " of ", me % nrhs, ":"
            !     do row = 1, me % m
            !         write ( io, fmt = 100 ) me % b ( row, k )
            !     end do ! row
            ! end do ! k

        return

        !100 format ( "| ", F6.2, " |" )

    end subroutine printLinearSystem_sub

end module mClassLinearSystem
