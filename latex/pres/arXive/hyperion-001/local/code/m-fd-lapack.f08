! 3456789 123456789 223456789 323456789 423456789 523456789 623456789 723456789 823456789 923456789 023456789 123456789 223456789 32
module mFormatDescriptorsLapack

    use mPrecisionDefinitions,          only : kindA

    implicit none

    ! Lapack
    character ( kind = kindA, len = * ), parameter :: &
            ! diagnostics
            fmt_elements     = '( "The ", g0, " elements of the ", g0, " follow:" )', &
            fmt_array_1      = '( g0, "array size: ", g0 )', &
            fmt_array_2      = '( g0, "array size: ", g0, " x ", g0 )', &
            fmt_listA        = '( "A ( ", g0, ", ", g0, " ) = ", g0 )', &
            fmt_listb        = '( "b ( ", g0, ", ", g0, " ) = ", g0 )', &
            fmt_list_work    = '( "work ( ", g0, " ) = ", g0 )', &
            fmt_shape_r1     = '( g0, g0, " x ", g0 )', &
            fmt_shape_r2     = '( g0, 2 ( g0, " x ", g0 ) )', &
            fmt_size_norm    = '( g0, "array size: ", g0, ", norm2 ( work ) = ", g0 )', &
            ! errors
            fmt_lapack_error = '( "Error in Lapack subroutine ", g0, ".", / )', &
            fmt_no_positive  = '( /, g0, " should not return positive error values.  INFO = ", g0, " is not allowed." )', &
            fmt_dgels_error  = '( /, "Diagonal element of triangular factor of the matrix A in row ", g0, " = 0.", /, &
                                &  "Therefore the matrix A does not have full rank and the least squares solution ", /, &
                                &  "cannot be computing using DGELS. Consider using the SVD." )', &
            fmt_dgetrf_error = '( /, g0, " error: U( ", g0, ", ", g0, " ) is exactly zero; the input matrix is", /, &
                                & "singular and its inverse could not be computed. ", /, &
                                & "Consider using the SVD to construct a pseudoinverse matrix." )', &
            fmt_dgelsd_error = '( /, "DGELSD SVD algorithm failed to converge.", /, &
                                & "A total of ", g0, " off-diagonal elements of an intermediate &
                                & bidiagonal form did not converge to zero." )'

end module mFormatDescriptorsLapack
