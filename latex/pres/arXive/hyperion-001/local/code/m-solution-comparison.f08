! 3456789 123456789 223456789 323456789 423456789 523456789 623456789 723456789 823456789 923456789 023456789 123456789 223456789 32
module mSolutionComparison

    use, intrinsic :: iso_fortran_env,  only : stdin  => input_unit, &
                                               stdout => output_unit, &
                                               stderr => error_unit
    use mClassSolutionBasic,            only : solutionBasic
    use mClassSolutionComplete,         only : solutionComplete

    use mFormatDescriptorsBasics,       only : fmt_two, fmt_five
    use mFormatDescriptorsComparison,   only : fmt_relative, fmt_difference, fmt_difference1, fmt_kerror, fmt_error

    use mLibraryConstants,              only : machine_epsilon, zero
    use mPrecisionDefinitions,          only : ip, rp, kindA

    implicit none
    integer ( kind = ip ) :: row = 0, k = 0, count = 0

contains

    subroutine compareSolutionBasic_sub ( solnA, solnB, io_unit )
        ! compute  difference between basic solutions term-by-term
        type ( solutionBasic ),          intent ( in ) :: solnA, solnB
        integer ( kind = ip ), optional, intent ( in ) :: io_unit
        integer ( kind = ip ) :: n = 0, nrhs = 0, io = 0

            if ( present ( io_unit ) ) then
                io = io_unit
            else
                io = stdout
            endif

                ! header
            write ( * , fmt = 100 )
            write ( * , fmt = fmt_two ) "A: ", solnA % descriptor
            write ( * , fmt = fmt_two ) "B: ", solnB % descriptor

                ! measure arrays
            n    = size ( solnA % x, 1 )
            nrhs = size ( solnA % x, 2 )

            call compareSolutionArrays_sub ( arrayA = solnA % x ( :, : ), arrayB = solnB % x ( :, : ), &
                                             n = n, nrhs = nrhs, io_unit = io, &
                                             descriptor_action = "X: Comparing solution vectors", descriptor_term = "x" )
        return

        100 format ( /, "A - B: Comparing basic solutions" )

    end subroutine compareSolutionBasic_sub

    subroutine compareSolutionComplete_sub ( solnA, solnB, io_unit )
        ! compute  difference between basic solutions term-by-term
        type ( solutionComplete ),       intent ( in ) :: solnA, solnB
        integer ( kind = ip ), optional, intent ( in ) :: io_unit
        integer ( kind = ip ) :: m = 0, n = 0, nrhs = 0, io = 0
        real    ( kind = rp ) :: delta = zero, delta_epsilon = zero

            if ( present ( io_unit ) ) then
                io = io_unit
            else
                io = stdout
            endif

                ! header
            write ( io, * ) ""
            write ( io, * ) "A - B: Comparing complete solutions"
            write ( io, fmt = fmt_two ) "A: ", solnA % descriptor
            write ( io, fmt = fmt_two ) "B: ", solnB % descriptor

                ! measure arrays
            m    = size ( solnA % residual,     1 )
            n    = size ( solnA % solution % x, 1 )
            nrhs = size ( solnA % solution % x, 2 )

            call compareSolutionArrays_sub ( arrayA = solnA % solution % x ( : , : ), arrayB = solnB % solution % x ( : , : ), &
                                             n = n, nrhs = nrhs, io_unit = io, &
                                             descriptor_action = "Comparing solution vectors", descriptor_term = "x" )

            call compareSolutionArrays_sub ( arrayA = solnA % sigma ( : , : ), arrayB = solnB % sigma ( : , : ), &
                                             n = n, nrhs = nrhs, io_unit = io, &
                                             descriptor_action = "Comparing error terms", descriptor_term = "sigma" )

            call compareSolutionArrays_sub ( arrayA = solnA % residual ( : , : ), arrayB = solnB % residual ( : , : ), &
                                             n = m, nrhs = nrhs, io_unit = io, &
                                             descriptor_action = "Comparing residual error vectors", descriptor_term = "residual" )

            write ( io, * ) ""
            write ( io, * ) "Comparing total error"
            count = 0
            ! loop over solutions
            do k = 1, nrhs
                ! compute the difference, express as machine epsilons
                count = count + 1
                delta = solnA % t2 ( k ) - solnB % t2 ( k )
                delta_epsilon = abs ( delta ) / machine_epsilon
                write ( io, fmt = fmt_difference1 ) count, "t2", k, delta_epsilon, delta, solnA % t2 ( k ), solnB % t2 ( k )
                if ( delta_epsilon >= 100.0_rp ) then ! compute relative error
                    delta = delta / solnA % t2 ( k )
                    delta_epsilon = abs ( delta ) / machine_epsilon
                    write ( io, fmt = fmt_relative ) delta, delta_epsilon
                end if
            end do ! nrhs

            write ( io, * ) ""
            write ( io, fmt = 100 ) "cpu time A: ", solnA % solutionTimeComplete
            write ( io, fmt = 100 ) "cpu time B: ", solnB % solutionTimeComplete

        return
        100 format ( g0, E10.2 )
    end subroutine compareSolutionComplete_sub

    subroutine compareSolutionArrays_sub ( arrayA, arrayB, n, nrhs, descriptor_action, descriptor_term, io_unit )
        integer ( kind = ip ),                        intent ( in ) :: n, nrhs
        integer ( kind = ip ), optional,              intent ( in ) :: io_unit
        real    ( kind = rp ), dimension ( n, nrhs ), intent ( in ) :: arrayA, arrayB
        character ( kind = kindA, len = * ),          intent ( in ) :: descriptor_action, descriptor_term

        integer ( kind = ip ) :: io = 0
        real    ( kind = rp ) :: delta = zero, delta_epsilon = zero, &
                                 A = zero, B = zero, &
                                 error = zero, kerror = zero

            if ( present ( io_unit ) ) then
                io = io_unit
            else
                io = stdout
            endif

            write ( io, * ) ""
            write ( io, * ) descriptor_action
            count = 0
            error = zero
            ! loop over solutions
            do k = 1, nrhs
                ! loop over vector elements
                kerror = zero
                do row = 1, n
                    ! compute difference, express as machine epsilons
                    count = count + 1
                    A = arrayA ( row, k )
                    B = arrayB ( row, k )
                    delta = A - B
                    delta_epsilon = abs ( delta ) / machine_epsilon
                    kerror = kerror + delta ** 2
                    write ( io, fmt = fmt_difference ) count, trim ( descriptor_term ), row, k, delta_epsilon, delta, A, B
                    ! if ( delta_epsilon >= 100.0_rp ) then ! compute relative error
                    !     delta = delta / A
                    !     delta_epsilon = abs ( delta ) / machine_epsilon
                    !     write ( io, fmt = fmt_relative ) delta, delta_epsilon
                    !end if
                end do ! row
                write ( io, fmt = fmt_kerror ) trim ( descriptor_term ), k, nrhs, kerror, sqrt ( kerror )
                error = error + kerror
            end do ! nrhs
                ! summarize if needed
            if ( nrhs > 1 ) then
                write ( io, fmt = fmt_error ) trim ( descriptor_term ), nrhs, error, sqrt ( error )
            end if

        return
    end subroutine compareSolutionArrays_sub

end module mSolutionComparison
