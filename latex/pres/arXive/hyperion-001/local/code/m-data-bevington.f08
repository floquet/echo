! 3456789 123456789 223456789 323456789 423456789 523456789 623456789 723456789 823456789 923456789 023456789 123456789 223456789 32
module mDataBevington

    use mClassLinearSystem,             only : linearSystem
    use mClassSolutionBasic,            only : solutionBasic
    use mClassSolutionComplete,         only : solutionComplete
    use mLibraryConstants,              only : zero
    use mPrecisionDefinitions,          only : rp

    implicit none

contains

    subroutine exampleBevington ( bevingtonData, bevingtonSolnComplete )
        ! nb: /Users/dantopa/Mathematica_files/nb/projects/least squares/bevington/basics/bevington verify answers 01.nb
        type ( linearSystem ),     intent ( out ) :: bevingtonData
        type ( solutionComplete ), intent ( out ) :: bevingtonSolnComplete
        integer, parameter :: m = 9, n = 2, nrhs = 1
        integer, parameter :: lda = m, ldb = m
        ! raw data
        real ( kind = rp ), parameter :: A ( 1 : lda , 1 : n ) = &
                                         reshape ( [ [ 1.0_rp, 1.0_rp, 1.0_rp, 1.0_rp, 1.0_rp, 1.0_rp, 1.0_rp, 1.0_rp, 1.0_rp ], &
                                                     [ 1.0_rp, 2.0_rp, 3.0_rp, 4.0_rp, 5.0_rp, 6.0_rp, 7.0_rp, 8.0_rp, 9.0_rp ] ], &
                                                        [ m, n ] )
        real ( kind = rp ), parameter :: b ( 1 : ldb , 1 : nrhs ) = &
                                         reshape ( [ [ 15.6_rp, 17.5_rp, 36.6_rp, 43.8_rp, 58.2_rp, &
                                                       61.6_rp, 64.2_rp, 70.4_rp, 98.8_rp ] ], &
                                                        [ m, nrhs ] )
        ! Mathematica solution
            ! rank 0
        real ( kind = rp ), parameter :: det = 540.0_rp
            ! rank 1
        real ( kind = rp ), parameter :: errorNormMM ( 1 : nrhs ) = [ 1139969.0_rp / 3600.0_rp ]
        real ( kind = rp ), parameter :: singularValues ( 1 : n ) = [ 3.0_rp * sqrt ( 49.0_rp + sqrt ( 2341.0_rp ) ), &
                                                                      3.0_rp * sqrt ( 49.0_rp - sqrt ( 2341.0_rp ) ) ]
            ! rank 2
        real ( kind = rp ), parameter :: solnMM ( 1 : n , 1 : nrhs ) = &
                reshape ( [ [ 1733.0_rp, 3387.0_rp ] ], [ n, nrhs ] ) / 360.0_rp
        real ( kind = rp ), parameter :: residualMM ( 1 : m , 1 : nrhs ) = &
                reshape ( [ [ -496.0_rp, 2207.0_rp, -1282.0_rp,  -487.0_rp, -2284.0_rp, &
                              -121.0_rp, 2330.0_rp,  3485.0_rp, -3352.0_rp ] ], [ m, nrhs ] ) / 360.0_rp
        real ( kind = rp ), parameter :: sigmaMM ( 1 : n , 1 : nrhs ) = &
                reshape ( [ sqrt ( [ 108297055.0_rp,  3419907.0_rp ] ) ], [ n, nrhs ] ) / 360.0_rp / sqrt ( 35.0_rp )
        real ( kind = rp ), parameter :: Wmm ( 1 : n , 1 : n ) = reshape ( [ [ 9.0_rp, 45.0_rp, 45.0_rp, 285.0_rp ] ], [ n, n ] )
        real ( kind = rp ), parameter :: Winvmm ( 1 : n , 1 : n ) = &
                reshape ( [ [ 285.0_rp, -45.0_rp, -45.0_rp, 9.0_rp ] ], [ n, n ] ) / det

            write ( * , * ) "exampleBevington"
                ! inject data
            call bevingtonData % injectLinearSystem ( m = m, n = n, nrhs = nrhs, lda = m, ldb = m, &
                                                      A = A ( 1 : lda , 1 : n ), &
                                                      b = b ( 1 : ldb , 1 : nrhs ), &
                                                      descriptor = "Bevington example data 6.1" )
                ! inject solutions
            call bevingtonSolnComplete % injectSolutionComplete ( system = bevingtonData, solution = solnMM, &
                                        t2 = errorNormMM, sigma = sigmaMM, residual = residualMM, W = Wmm, Winv = WinvMM, &
                                        descriptor = "Mathematica solution for Bevington data, arbitrary precision", &
                                        solutionTimeComplete = zero )
        return
    end subroutine exampleBevington

end module mDataBevington
