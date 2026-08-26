! 3456789 123456789 223456789 323456789 423456789 523456789 623456789 723456789 823456789 923456789 023456789 123456789 223456789 32
module mDataNAGdgelsy

    use mClassLinearSystem,             only : linearSystem
    use mClassSolutionBasic,            only : solutionBasic
    use mClassSolutionComplete,         only : solutionComplete
    use mLibraryConstants,              only : zero
    use mPrecisionDefinitions,          only : rp

    implicit none

contains
    subroutine exampleNAGdgelsy ( NAGdgelsyData, NAGdgelsySolnComplete )
        ! nb: /Users/dantopa/Mathematica_files/nb/topics/lapack/dgels/nag-dgelsy-01.nb
        type ( linearSystem ),     intent ( out ) :: NAGdgelsyData
        type ( solutionComplete ), intent ( out ) :: NAGdgelsySolnComplete
        integer, parameter :: m = 6, n = 5, nrhs = 1
        integer, parameter :: lda = m, ldb = m
        ! raw data
        real ( kind = rp ), parameter :: A ( 1 : lda , 1 : n ) = &
                                         reshape ( [ [ -0.09_rp, -1.56_rp, -1.48_rp, -1.09_rp,  0.08_rp, -1.59_rp ],   &
                                                     [  0.14_rp,  0.2_rp,  -0.43_rp,  0.84_rp,  0.55_rp, -0.72_rp ],   &
                                                     [ -0.46_rp,  0.29_rp,  0.89_rp,  0.77_rp, -1.13_rp,  1.06_rp ],   &
                                                     [  0.68_rp,  1.09_rp, -0.71_rp,  2.11_rp,  0.14_rp,  1.24_rp ],   &
                                                     [  1.29_rp,  0.51_rp, -0.96_rp, -1.27_rp,  1.74_rp,  0.34_rp ] ], &
                                                        [ m, n ] )
        real ( kind = rp ), parameter :: b ( 1 : ldb , 1 : nrhs ) = &
                                         reshape ( [ [ 7.4_rp, 4.2_rp, -8.3_rp, 1.8_rp, 8.6_rp, 2.1_rp ] ], &
                                                        [ m, nrhs ] )
        ! Mathematica solution
            ! rank 0
        real ( kind = rp ), parameter :: det = 0.003580091139738075_rp
            ! rank 1
        real ( kind = rp ), parameter :: errorNormMM ( 1 : nrhs ) = [ 0.000012077113770655917_rp ]
        real ( kind = rp ), parameter :: singularValues ( 1 : n ) = [ 3.9996534877789536_rp, 2.9962473455460703_rp, &
                                                                      2.0000762147785545_rp, 0.9988306717677832_rp, &
                                                                      0.002499243643689815_rp ]
            ! rank 2
        real ( kind = rp ), parameter :: solnMM ( 1 : n , 1 : nrhs ) = &
                reshape ( [ [ -0.799744726899023_rp, -3.2879635059925576_rp, -7.474984265141085_rp, 4.939273145125415_rp, &
                               0.7678334408676943_rp ] ], [ n, nrhs ] )
        real ( kind = rp ), parameter :: residualMM ( 1 : m , 1 : nrhs ) = &
                reshape ( [ [ -0.0006342260485387996_rp, -0.00233358109772297_rp,   0.0007064711397575252_rp, &
                               0.0008123894402027876_rp,  0.0019011405889433064_rp, 0.0012065888850680828_rp ] ], [ m, nrhs ] )
        real ( kind = rp ), parameter :: sigmaMM ( 1 : n , 1 : nrhs ) = &
                reshape ( [ [0.24547740310430688_rp, 0.7287941816513717_rp, 1.0329190157238064_rp, 0.26898840208784536_rp, &
                             0.45038718843193254_rp ] ], [ n, nrhs ] )
        real ( kind = rp ), parameter :: Wmm ( 1 : n , 1 : n ) = &
                reshape ( [ [ 8.3547_rp,  0.585_rp,  -4.3433_rp, -4.9711_rp,  1.492_rp ], &
                            [ 0.585_rp,   1.771_rp,  -1.127_rp,   1.5751_rp,  0.3408_rp ], &
                            [-4.3433_rp, -1.1267_rp,  4.0812_rp,  2.1523_rp, -3.8836_rp ], &
                            [-4.9711_rp,  1.5751_rp,  2.1523_rp,  8.1639_rp,  0.10020000000000012_rp ], &
                            [ 1.492_rp,   0.3408_rp, -3.8836_rp,  0.10020000000000012_rp, 7.6019_rp ] ], &
                                [ n, n ] )
        real ( kind = rp ), parameter :: Winvmm ( 1 : n , 1 : n ) = &
                reshape ( [ [ 17.862982212233756_rp,    53.029993420186884_rp,    75.16165028314671_rp,   &
                             -19.571909875552024_rp,    32.77268830041258_rp ], [ 53.02999342018691_rp,   &
                             157.44929443622064_rp,    223.1501797818981_rp,     -58.111519528003335_rp,  &
                              97.30058837013148_rp ], [ 75.16165028314671_rp,    223.150179781898_rp,     &
                             316.27398504279694_rp,    -82.36043949937176_rp,    137.90544480431439_rp ], &
                           [ -19.571909875552038_rp,   -58.11151952800335_rp,    -82.36043949937181_rp,   &
                              21.44855482459144_rp,    -35.91187106430198_rp ], [ 32.77268830041258_rp,   &
                              97.30058837013145_rp,    137.90544480431439_rp,    -35.91187106430196_rp,   &
                              60.13163071772343_rp ] ], [ n, n ] ) / det

                ! inject data
            call NAGdgelsyData % injectLinearSystem ( m = m, n = n, nrhs = nrhs, lda = m, ldb = m, &
                                                      A = A ( 1 : lda , 1 : n ), &
                                                      b = b ( 1 : ldb , 1 : nrhs ), &
                                                      descriptor = "NAG dgelsy example data" )
                ! inject solutions
            call NAGdgelsySolnComplete % injectSolutionComplete ( system = NAGdgelsyData, solution = solnMM, &
                                        t2 = errorNormMM, sigma = sigmaMM, residual = residualMM, W = Wmm, Winv = WinvMM, &
                                        descriptor = "Mathematica solution for NAG delsy data, arbitrary precision", &
                                        solutionTimeComplete = zero )
        return
    end subroutine exampleNAGdgelsy

end module mDataNAGdgelsy

! DGELSY Example Program Results
!
! Least squares solution
!      0.6344     0.9699    -1.4402     3.3678     3.3992
!
! Tolerance used to estimate the rank of A
!      1.00E-02
! Estimated rank of A
!      4
