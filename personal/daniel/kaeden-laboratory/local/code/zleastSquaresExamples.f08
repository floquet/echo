! 3456789 123456789 223456789 323456789 423456789 523456789 623456789 723456789 823456789 923456789 023456789 123456789 223456789 32
program leastSquaresExamples

    use, intrinsic :: iso_fortran_env,  only : compiler_options, compiler_version
    use mFormatDescriptorsBasics,       only : fmt_cpu_time, fmt_datecom, fmt_launchC, fmt_compilerV, fmt_compilerO
    use mPrecisionDefinitions,          only : ip, rp, kindA
    use mTaskManager,                   only : computeSolutions_sub

    implicit none

    integer ( kind = ip ) :: dt_values ( 1 : 8 ) = 0_ip  ! containers for date and time
    real ( kind = rp ) :: start = 0.0_rp, finish = 0.0_rp
    character ( kind = kindA, len = 512 ) :: cmd = ""

        call get_command ( cmd )
        call cpu_time ( time = start )

            ! specify problem
            call computeSolutions_sub ( )

        call cpu_time ( time = finish )
        write ( * , fmt = fmt_cpu_time ) finish - start

        ! execution complete - tag output
        call date_and_time ( VALUES = dt_values )
            write ( * , fmt_datecom ) dt_values ( 1 : 3 ), dt_values ( 5 : 7 )

        write ( * , fmt = fmt_launchC )   trim ( cmd )
        write ( * , fmt = fmt_compilerV ) compiler_version ( )
        write ( * , fmt = fmt_compilerO ) compiler_options ( )

        stop 'Normal termination for "leastSquaresExamples.f08."'

end program leastSquaresExamples
